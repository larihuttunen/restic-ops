# Deployment Guide: restic-ops

* This guide explains how to deploy restic-ops on a machine you want to back up. It assumes you have already cloned the repository and installed prerequisites.


## 1. Prerequisites

* restic binary (download from https://github.com/restic/restic/releases)
* gpg installed
* Systemd (recommended) or cron for scheduling
* Clone the repo:

```
git clone git@github.com:larihuttunen/restic-ops.git
cd restic-ops
```

## 2. Configure Include/Exclude Lists

Edit:
* conf/include.txt → paths to back up (e.g., /etc, /home, /var/lib/postgresql/backups)
* conf/exclude.txt → patterns to skip (e.g., *.tmp, /.cache/)

## 3. Create Secrets (Symmetric Encryption)

* We use symmetric encryption with gpg-agent for caching the passphrase.
* Create conf/secrets/restic.env with export lines:

```
export RESTIC_REPOSITORY="s3:https://s3.amazonaws.com/your-bucket/path"
export RESTIC_PASSWORD="your-strong-password"
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export RESTIC_CACHE_DIR="/var/cache/restic"   # Central cache directory with enough space
```

* Encrypt and remove plaintext:

```
gpg --symmetric --cipher-algo AES256 conf/secrets/restic.env
rm conf/secrets/restic.env
```

* Decrypt in scripts:
```
eval "$(gpg --batch --quiet --decrypt conf/secrets/restic.env.gpg)"
```

* For unattended use, rely on gpg-agent caching. No passphrase file is needed if you supply the passphrase interactively once.

## 4. Initialize Repository

* Dry run first:
```
bin/backup.sh --dry-run
```

* Initialize:
```
restic init
```

## 5. Enable Systemd Timers

To schedule backups, retention, and cache maintenance, follow these steps:

### Install unit files
Copy all service and timer files from your repo into systemd’s directory:

```bash
sudo cp systemd/*.service systemd/*.timer /etc/systemd/system/
sudo systemctl daemon-reload
```

### Enable timers
Enable **daily backup**:

```bash
sudo systemctl enable --now restic-backup.timer
```

Enable **weekly retention**:

```bash
sudo systemctl enable --now restic-retention.timer
```

Enable **weekly cache cleanup**:

```bash
sudo systemctl enable --now restic-cache-clean.timer
```

### Check timers

```bash
systemctl list-timers | grep restic
```

---

### Cache Cleanup Units (already included in `systemd/`)

`systemd/restic-cache-clean.service`:
```ini
[Unit]
Description=Clean restic cache

[Service]
Type=oneshot
ExecStart=/usr/bin/restic cache --cleanup --max-age 30 --cache-dir /var/cache/restic
```

`systemd/restic-cache-clean.timer`:
```ini
[Unit]
Description=Weekly restic cache cleanup

[Timer]
OnCalendar=Sun *-*-* 04:00:00
Persistent=true

[Install]
WantedBy=timers.target
```## 6. Verify Logs

```
journalctl -u restic-backup.service
```

## 7. Restore

* Restore latest snapshot:

```
bin/restore.sh latest /tmp/restore
```

* Restore by ID:

```
bin/restore.sh <snapshot-id> /tmp/restore --include /etc
```

## 8. Retention Policy

* Default:
 - Daily: 14
 - Monthly: 6
 - Yearly: 3

* Override:

```
KEEP_DAILY=7 KEEP_MONTHLY=12 KEEP_YEARLY=5 bin/retention.sh
```

## 9. Using gpg-agent with Symmetric Encryption

* Systemd timers run non-interactively, so configure gpg-agent with a long TTL (40 days):
* Edit ~/.gnupg/gpg-agent.conf:

```
default-cache-ttl 3456000    # 40 days in seconds
max-cache-ttl 3456000
```

* Reload agent:

```
gpgconf --reload gpg-agent
```

* Enable agent at boot:

```
systemctl --user enable --now gpg-agent.service
```

* Supply passphrase interactively once
 - Run:

```
gpg --decrypt conf/secrets/restic.env.gpg
```

* Enter the passphrase manually. gpg-agent caches it for 40 days. After this, systemd timers can run unattended without prompts.

### Caching Behavior Explained

* When you decrypt a file, gpg-agent caches the passphrase in memory.
* Subsequent decrypts use the cached passphrase silently.
* default-cache-ttl defines how long after last use the passphrase stays cached.
* max-cache-ttl defines the absolute maximum lifetime.
* For symmetric encryption, the same caching applies: decrypt once, and the passphrase is cached for the TTL.
* Cache is lost on reboot unless you re-enter the passphrase.


## 10. Troubleshooting

* Timers fail with decryption error: Check if gpg-agent cache expired. Re-run gpg --decrypt conf/secrets/restic.env.gpg to refresh.
* After reboot: Cache is cleared. Supply passphrase interactively again.
* Agent not running: Start with systemctl --user start gpg-agent.service.
* TTL not applied: Verify ~/.gnupg/gpg-agent.conf and reload with gpgconf --reload gpg-agent.
* Loopback fallback: If agent cannot cache, use --pinentry-mode loopback --passphrase-file /secure/path in scripts.
* Check agent status: Run gpgconf --list-dirs agent-socket to confirm socket path, or gpg-connect-agent /bye to verify agent is active.
* Reload agent manually: Use gpg-connect-agent reloadagent /bye to apply config changes immediately.
* Preset passphrase manually: Use gpg-preset-passphrase --preset --passphrase <your-passphrase> <cache-key> for advanced scenarios (requires enabling allow-preset-passphrase in gpg-agent.conf).


### Security Notes

* Secrets are GPG-encrypted; decrypted only in memory.
* Symmetric mode is simpler but requires secure passphrase handling.
* Avoid set -x in scripts.
* Always use HTTPS endpoints.
