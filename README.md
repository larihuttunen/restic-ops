# Quick Start

This repository now uses a **single-profile** workflow. Everything you need for backups lives in one encrypted file and a few helper scripts.

## Secrets
Create `conf/secrets/restic.env` with:

```sh
# Repository: choose one backend
export RESTIC_REPOSITORY="s3:https://s3.amazonaws.com/your-bucket/path"
# Or for Azure:
export RESTIC_REPOSITORY="azure:your-container-name:optional/prefix"

# Restic repository password
export RESTIC_PASSWORD="super-secret-password"

# S3 credentials
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."

# Azure credentials
export AZURE_ACCOUNT_NAME="..."
export AZURE_ACCOUNT_KEY="..."
# Optional: export AZURE_SAS_TOKEN="..."

# Optional: central cache directory
export RESTIC_CACHE_DIR="/var/cache/restic"
```

Encrypt and remove plaintext:

```sh
gpg --symmetric --cipher-algo AES256 conf/secrets/restic.env
rm conf/secrets/restic.env
```

## Scripts
- `bin/common.sh`: logging, decrypt secrets, validate env.
- `bin/backup.sh`, `bin/restore.sh`, `bin/retention.sh`: load secrets and run restic.

## Systemd Units
Timers and services for:
- Daily backup (`restic-backup.timer` / `restic-backup.service`)
- Weekly retention (`restic-retention.timer` / `restic-retention.service`)
- Weekly cache cleanup (`restic-cache-clean.timer` / `restic-cache-clean.service`)

## Quickstart Steps

1. Clone the repo:
    ```sh
    git clone <your-repo-url>
    cd <your-repo-dir>
    ```
2. Populate `conf/secrets/restic.env` with your values (using the template above) and encrypt it as shown.
3. Adjust your include/exclude lists in `conf/include.txt` and `conf/exclude.txt`.
4. Make the scripts executable:
    ```sh
    chmod +x bin/*.sh
    ```
5. Copy systemd units and enable the timers:
    ```sh
    sudo cp systemd/*.service systemd/*.timer /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable --now restic-backup.timer restic-retention.timer restic-cache-clean.timer
    ```
6. Check status:
    ```sh
    systemctl list-timers | grep restic
    ```

For full details and advanced configuration see the [Deployment Guide](Deployment.md).
