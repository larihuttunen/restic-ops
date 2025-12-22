# restic-ops

**Robust, operator-friendly wrappers for Restic backups.**
Focused on security, automation (systemd/cron), and ease of recovery.

## Features
- **Multi-Cloud Support:** Fully compatible with all Restic backends.
  - ✅ **Tested & Verified:** AWS S3, Azure Blob Storage, Backblaze B2.
  - *Also supports: SFTP, REST Server, Google Cloud, local disk, etc.*
- **Secure by Default:** No plaintext passwords on disk; uses GPG-encrypted secrets.
- **Automated:** Ready-to-use systemd units (timers/services) for backup, prune, and retention.
- **Operator-Centric:** Helper scripts for stats, listing snapshots, and unified logging.
- **Portable:** Runs on Linux (systemd) and BSD/macOS (cron).

---

## Quick Start (Linux/systemd)

For the full detailed guide, see [docs/Deployment.md](docs/Deployment.md).

### 1. Install
Download the latest self-extracting release (`.run`) and install it to a versioned directory.

```sh
# 1. Prepare directory
mkdir -p /usr/local/lib/restic-ops/v0.2.1
cd /usr/local/lib/restic-ops/v0.2.1

# 2. Extract release (assuming you downloaded restic-ops.run here)
sh restic-ops.run

# 3. Symlink for easy access
ln -sfn /usr/local/lib/restic-ops/v0.2.1 /usr/local/bin/restic-ops

```

### 2. Configure

Create the persistent configuration directory and copy the default rules.

1. **Create Config & Copy Rules:**
```sh
mkdir -p /etc/restic-ops
cp /usr/local/bin/restic-ops/conf/*.txt /etc/restic-ops/

```

2. **Setup Encrypted Secrets:**
Create a temporary `restic.env` with your credentials, encrypt it, and delete the plaintext.
```sh
# Create/Edit secrets
vi /etc/restic-ops/restic.env

# Encrypt (AES256) and remove plaintext
gpg --symmetric --cipher-algo AES256 /etc/restic-ops/restic.env
rm /etc/restic-ops/restic.env

```

### 3. Initialize GPG Agent

Configure the agent to remember your passphrase for 40 days so backups run unattended.

1. **Set TTL (40 days):**
Add these lines to `/root/.gnupg/gpg-agent.conf`:
```ini
default-cache-ttl 3456000
max-cache-ttl 3456000
```

2. **Restart & Prime:**
```sh
gpgconf --kill gpg-agent
/usr/local/bin/restic-ops/bin/prime-gpg.sh
```

### 4. Run First Backup

Initialize the repository and perform the first run.

```sh
/usr/local/bin/restic-ops/bin/init.sh
/usr/local/bin/restic-ops/bin/backup.sh

```

### 5. Automate

Enable the provided systemd timers.

```sh
cp /usr/local/bin/restic-ops/systemd/restic-*.service /etc/systemd/system/
cp /usr/local/bin/restic-ops/systemd/restic-*.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now restic-backup.timer restic-retention.timer restic-prune.timer

```

---

## Documentation

* **[Deployment Guide](docs/Deployment.md):** Full installation, directory layout, and upgrade steps.
* **[Operations & Troubleshooting](docs/Admin.md):** Daily management commands.
* **[Cron/BSD Guide](cron/README.md):** Scheduling without systemd.
* **[Roadmap](docs/Roadmap.md):** Future plans and version history.

