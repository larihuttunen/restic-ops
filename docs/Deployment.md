# Deployment Guide (Linux, systemd)

This guide covers installing and upgrading restic-ops using the self-extracting release. Configuration is always stored in `/etc/restic-ops` and is never overwritten by upgrades.

## Dependencies

Required (Linux):

* `restic`
* `gpg` (and `pinentry`)
* `systemd`

Optional:

* `jq` (for enhanced stats output)
* `logrotate` (for log file management)

## Directory Layout

* Code (versioned): `/usr/local/lib/restic-ops/vN.N.N/`
* Symlink: `/usr/local/bin/restic-ops` pointing to current version
* Config (persistent): `/etc/restic-ops/`
  * `include.txt`
  * `exclude.txt`
  * `restic.env.gpg` (encrypted secrets)
  * `profiles/` (optional, for multi-profile setups)

## Installation

### Download and Verify

Download the latest self-extracting installer (`restic-ops.run`) and its signature (`.asc`). Verify them using GPG as described in `Releases.md`.

### Extract and Install

Create a versioned directory and run the self-extractor.

```sh
mkdir -p /usr/local/lib/restic-ops/vN.N.N
cd /usr/local/lib/restic-ops/vN.N.N
sh /path/to/restic-ops.run
```

### Create Symlink

Link the new version to the system path.

```sh
ln -sfn /usr/local/lib/restic-ops/vN.N.N /usr/local/bin/restic-ops
```

## Configuration (Default Single-Profile)

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

To ensure headless backups work for extended periods, configure the GPG agent to cache the passphrase for 40 days (3456000 seconds).

Configure TTL:
Edit `/root/.gnupg/gpg-agent.conf` (create if missing):

```ini
default-cache-ttl 3456000
max-cache-ttl 3456000
```

Restart Agent:

```sh
gpgconf --kill gpg-agent
```

### Prime the Cache

Run the helper script to interactively cache your passphrase. You will need to run this once every 40 days (or after a reboot).

```sh
/usr/local/bin/restic-ops/bin/prime-gpg.sh
```

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

## Multi-Profile & Admin Targets (Advanced)

For environments requiring multiple backup targets (e.g., isolating an external drive, backing up to different cloud providers, or acting as an admin workstation managing remote backups).

### 1. Profile Setup

Create an isolated directory for the profile inside `/etc/restic-ops/profiles/`.

```sh
mkdir -p /etc/restic-ops/profiles/APP-DB-01
```

Populate this new directory with its own `include.txt`, `exclude.txt`, and `restic.env.gpg`. 

*Note: If you encrypt multiple profiles' `restic.env.gpg` files using the same master password, the GPG agent will seamlessly cache the shared secret globally, allowing unattended automation across all profiles.*

### 2. Manual Profile Execution

To run a primitive script against a specific profile, use the `selector.sh` wrapper. If run interactively and the GPG agent is locked, it will prompt you securely.

```sh
/usr/local/bin/restic-ops/bin/selector.sh APP-DB-01 backup
/usr/local/bin/restic-ops/bin/selector.sh APP-DB-01 stats
```

To run a command sequentially across **all** configured profiles (ideal for admin workstations running global status checks or unlocks), use `foreach.sh`:

```sh
/usr/local/bin/restic-ops/bin/foreach.sh stats
```

### 3. Automated Scheduling (Systemd)

Multi-profile setups use systemd template units (`@.service` and `@.timer`). These manage parallel scheduling and strict fault isolation per profile.

Copy the template units to the systemd directory:
```sh
cp /usr/local/bin/restic-ops/systemd/restic-*@.* /etc/systemd/system/
systemctl daemon-reload
```

Enable the timers for your specific profile instance:
```sh
systemctl enable --now restic-backup@APP-DB-01.timer
systemctl enable --now restic-retention@APP-DB-01.timer
systemctl enable --now restic-prune@APP-DB-01.timer
```

## Upgrading

### Install New Version

Extract the new release to a new versioned directory (e.g., `v0.6.0`).

### Switch Symlink

Point the global symlink to the new version.

```sh
ln -sfn /usr/local/lib/restic-ops/vN.N.N /usr/local/bin/restic-ops
```

### Reload Services

Reload systemd to pick up any changes in the unit files.

```sh
systemctl daemon-reload
systemctl restart restic-backup.timer restic-retention.timer restic-prune.timer
```

Note: Do not touch `/etc/restic-ops`. Your configuration stays compatible across versions.

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

## See Also

* `docs/Admin.md`: Daily operations and troubleshooting.
* `docs/CRON.md`: Scheduling for BSD or non-systemd environments.
* `docs/Releases.md`: Verifying GPG signatures.
* `docs/External.md`: For workflows involving offline or physical media.