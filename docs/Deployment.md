# Deployment Guide (Linux, systemd) — restic-ops

This guide covers installing and upgrading restic-ops using the self-extracting release.
Configuration is always stored in `/etc/restic-ops` and is never overwritten by upgrades.

---

## Dependencies

**Required (Linux):**
* `restic`
* `gpg` (and `pinentry`)
* `bash`
* `systemd`

**Optional:**
* `jq` (for enhanced stats output)
* `logrotate` (for log file management)

---

## Directory Layout

* **Code (versioned):** `/usr/local/lib/restic-ops/v0.2.1/`
* **Symlink:** `/usr/local/bin/restic-ops` → current version
* **Config (persistent):** `/etc/restic-ops/`
    * `include.txt`
    * `exclude.txt`
    * `restic.env.gpg` (encrypted secrets)

---

## Installation

### Download and Verify
Download the latest self-extracting installer (`restic-ops.run`) and its signature (`.asc`). Verify them using GPG as described in `Releases.md`.

### Extract and Install
Create a versioned directory and run the self-extractor.

```sh
mkdir -p /usr/local/lib/restic-ops/v0.2.1
cd /usr/local/lib/restic-ops/v0.2.1
sh /path/to/restic-ops.run

```

### Create Symlink

Link the new version to the system path.

```sh
ln -sfn /usr/local/lib/restic-ops/v0.2.1 /usr/local/bin/restic-ops

```

---

## Configuration

### Persistent Config Directory

Create the configuration folder and copy the default rules.

```sh
mkdir -p /etc/restic-ops
# Copy default rules (assumes conf/*.txt exists in the release)
cp /usr/local/bin/restic-ops/conf/*.txt /etc/restic-ops/

```

### Secret Management

Create your environment file with credentials, encrypt it, and delete the plaintext.

```sh
# 1. Edit secrets
vi /etc/restic-ops/restic.env

# 2. Encrypt (AES256)
gpg --symmetric --cipher-algo AES256 /etc/restic-ops/restic.env

# 3. Remove plaintext
rm /etc/restic-ops/restic.env

```

### GPG Agent Persistence (40-Day Cache)

To ensure headless backups work for extended periods, configure the GPG agent to cache the passphrase for 40 days ( seconds).

**Configure TTL:**
Edit `/root/.gnupg/gpg-agent.conf` (create if missing):

```ini
default-cache-ttl 3456000
max-cache-ttl 3456000

```

**Restart Agent:**

```sh
gpgconf --kill gpg-agent

```

### Prime the Cache

Run the helper script to interactively cache your passphrase. You will need to run this once every 40 days (or after a reboot).

```sh
/usr/local/bin/restic-ops/bin/prime-gpg.sh

```

---

## Initialization

### Initialize Repository

If this is a new repository, initialize it now.

```sh
/usr/local/bin/restic-ops/bin/init.sh

```

### Seed First Backup

Run a manual backup to ensure everything is working.

```sh
/usr/local/bin/restic-ops/bin/backup.sh

```

---

## Automation (Systemd)

### Deploy Units

Copy the service and timer files to the systemd directory.

```sh
cp /usr/local/bin/restic-ops/systemd/restic-*.service /etc/systemd/system/
cp /usr/local/bin/restic-ops/systemd/restic-*.timer /etc/systemd/system/
systemctl daemon-reload

```

### Enable Timers

Enable the timers to start the schedule.

```sh
# Core timers
systemctl enable --now restic-backup.timer
systemctl enable --now restic-retention.timer
systemctl enable --now restic-prune.timer

# Optional: Cache cleanup (enable if disk space is tight)
# systemctl enable --now restic-cache-clean.timer

```

---

## Upgrading

### Install New Version

Extract the new release to a new versioned directory (e.g., `v0.2.2`).

### Switch Symlink

Point the global symlink to the new version.

```sh
ln -sfn /usr/local/lib/restic-ops/v0.2.2 /usr/local/bin/restic-ops

```

### Reload Services

Reload systemd to pick up any changes in the unit files.

```sh
systemctl daemon-reload
systemctl restart restic-backup.timer restic-retention.timer restic-prune.timer

```

*Note: Do not touch `/etc/restic-ops`. Your configuration stays compatible across versions.*

---

## Verification

### Headless Decrypt Test

Ensure the agent is caching secrets correctly by running this without a prompt:

```sh
env -i GNUPGHOME=/root/.gnupg gpg --batch --yes -d /etc/restic-ops/restic.env.gpg | head

```

### Check Timers

Verify that the timers are active and scheduled.

```sh
systemctl list-timers | grep restic

```

---

## See Also

* `docs/Admin.md`: Daily operations and troubleshooting.
* `docs/CRON.md`: Scheduling for BSD or non-systemd environments.
* `docs/Releases.md`: Verifying GPG signatures.
