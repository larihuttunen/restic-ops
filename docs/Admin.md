# Admin Guide — restic-ops

This guide covers daily and periodic operations after deployment.
Assume you are working as root (`sudo su -`) and the tools are installed at `/usr/local/bin/restic-ops`.

---

## Service Status (Systemd)

Check the status of automated timers and recent job runs.

```sh
# List all timers (backup, retention, prune)
systemctl list-timers --all | grep restic

# Check status of the latest backup service run
systemctl status restic-backup.service

# Check logs for the backup service
journalctl -u restic-backup.service -n 50 --no-pager

```

**Triggering a manual run via systemd:**

```sh
# Start a backup immediately (without waiting for timer)
systemctl start restic-backup.service

```

---

## Inspecting Repository

### Listing Snapshots

Use `list.sh` to filter snapshots. It supports standard restic filtering flags.

```sh
# List all snapshots
bin/list.sh

# Filter by host and tag
bin/list.sh --host db-server-01 --tag production

# Output JSON for parsing
bin/list.sh --json | jq .

```

### Repository Stats

Use `stats.sh` to analyze growth and size.

```sh
# Show restore size of the very latest snapshot
bin/stats.sh --mode restore-size --latest

# Show raw data added by a specific host in the last 30 days
bin/stats.sh --host app-server --since 30d --mode raw-data

# Get a human-readable summary of the latest snapshot (requires jq)
bin/stats.sh --latest --json --summary

```

---

## Restoration

To restore data, use the `restore.sh` wrapper. You need a **snapshot ID** (find one using `list.sh`) and a **target directory**.

**Syntax:** `bin/restore.sh <snapshot-id|latest> <target-dir> [restic-args]`

```sh
# Restore the latest snapshot to a temporary location
bin/restore.sh latest /tmp/restore-test

# Restore a specific snapshot
bin/restore.sh 6d425719 /mnt/recovery/v1

# Restore only a specific file/path from the snapshot
bin/restore.sh latest /tmp/restore-file --include "/etc/hosts"

```

---

## Manual Maintenance

While systemd handles automation, you may need to run these manually during setup or debugging.

```sh
# Run a backup (foreground)
bin/backup.sh

# Run retention policy (forget old snapshots)
bin/backup.sh --tag manual  # useful to tag manual runs separately
bin/retention.sh

# Prune data (heavy operation, exclusive lock)
bin/prune.sh

```

---

## Configuration Management

Configuration is persistent in `/etc/restic-ops`.

### Files

* **Rules:** `/etc/restic-ops/include.txt` and `/etc/restic-ops/exclude.txt`
* **Secrets:** `/etc/restic-ops/restic.env.gpg`

### Editing Secrets

Secrets are immutable and encrypted. To change a password or S3 key:

* **Decrypt to a temp file:**

```sh
gpg -d /etc/restic-ops/restic.env.gpg > /etc/restic-ops/restic.env.tmp

```

* **Edit the temp file:**

```sh
vi /etc/restic-ops/restic.env.tmp

```

* **Re-encrypt and replace:**

```sh
gpg --yes --symmetric --cipher-algo AES256 -o /etc/restic-ops/restic.env.gpg /etc/restic-ops/restic.env.tmp
rm /etc/restic-ops/restic.env.tmp

```

* **Re-prime the cache (see below).**

---

## Troubleshooting

### Removing Stale Locks

If a backup job crashes (e.g., OOM kill, power loss) or is manually killed, the repository may remain "locked." Future jobs will fail with `Fatal: unable to create lock`.

To unlock it, you can source the helper environment in a subshell:

```sh
(
  . /usr/local/bin/restic-ops/bin/common.sh
  load_secrets "$SECRETS"
  echo "Unlocking $RESTIC_REPOSITORY..."
  restic -r "$RESTIC_REPOSITORY" unlock
)

```

### Priming the GPG Agent

The automated scripts rely on a cached GPG key in memory. If you reboot or restart `gpg-agent`, you must re-prime it.

```sh
export GNUPGHOME=/root/.gnupg
gpg -d /etc/restic-ops/restic.env.gpg >/dev/null

```

*(If you see a passphrase prompt, enter it. Future non-interactive runs will now succeed.)*

### Verification

If automation is failing, test if the script can decrypt secrets without a prompt:

```sh
# This should print the first few lines of your secrets WITHOUT asking for a password
env -i GNUPGHOME=/root/.gnupg gpg --batch --yes -d /etc/restic-ops/restic.env.gpg | head

```

If this prompts for a password or fails:

1. Check `gpg-agent` is running.
2. Ensure you have "primed" the cache (step above).
3. Check `pinentry-mode loopback` settings if applicable.

---

## Manual Use Case

For personal computers such as laptops, which are not always online, you can add a manual
retention cycle through `/etc/restic-ops/restic.env`. This will keep at least five last
backups but make sure that the backups are temporally spaced through the daily, monthly,
yearly cycle.

```
export KEEP_LAST=5
export KEEP_DAILY=7
export KEEP_WEEKLY=4
export KEEP_MONTHLY=12
export KEEP_YEARLY=2

```

---

## Advanced: Centralized Admin Console

If you manage backups for multiple hosts (e.g., a "fleet" of servers), logging into each one as root to run maintenance is tedious. The **Admin Console** allows you to run maintenance commands (prune, check, stats) for *any* host from a single administrative machine (e.g., your laptop), without needing `sudo`.

### Features

* **Isolated Context:** Sets up a clean environment so it doesn't conflict with your personal GPG keys.
* **Safe Caching:** Automatically uses a local cache directory (`~/.cache/restic-admin`) to avoid permission errors with root-owned paths.
* **Robust Auth:** Uses memory-based password handling to bypass GPG agent caching issues.

### Setup

On your Admin machine, create a workspace that links to your installed tools and holds your encrypted keys.

**Directory Structure:**

```text
~/restic-admin/
├── bin -> /usr/local/bin/restic-ops/bin  # Symlink to installed tools
└── etc/                                  # Local directory for secrets
    ├── webserver-restic.env.gpg
    ├── mailserver-restic.env.gpg
    └── ...

```

**Initialization:**

```sh
mkdir -p ~/restic-admin/etc
ln -s /usr/local/bin/restic-ops/bin ~/restic-admin/bin
cd ~/restic-admin
ln -s bin/run.sh run.sh

```

### Usage

Run commands directly through the `run.sh` symlink.

**Syntax:** `./run.sh <hostname> <command> [args...]`

**Examples:**

```sh
cd ~/restic-admin

# Prune the repository for host 'webserver'
./run.sh webserver prune

# Check repository health for 'mailserver' (read 100MB of data)
./run.sh mailserver check --read-data-subset=100M

# View stats for 'web'
./run.sh webserver stats

```

**Note:** The first time you run a command for a host, the script will prompt you for the repository password. It handles authentication securely in memory for that session.

---

## See also

* `docs/Deployment.md` for install/upgrade.
* `docs/README.md` for BSD/cron scheduling.
