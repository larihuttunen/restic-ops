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

### 1. Install & Configure
Download the latest release (or clone source) to `/usr/local/bin/restic-ops`.

1.  **Create Configuration Directory:**
    ```sh
    mkdir -p /etc/restic-ops
    ```

2.  **Define Include/Exclude Rules:**
    Copy samples and edit to fit your needs.
    ```sh
    cp conf/include.sample.txt /etc/restic-ops/include.txt
    cp conf/exclude.sample.txt /etc/restic-ops/exclude.txt
    ```

3.  **Setup Encrypted Secrets:**
    Create a temporary `restic.env` file with your credentials (repo URL, passwords, S3/Azure keys).
    ```sh
    # Edit your secrets
    vi /etc/restic-ops/restic.env

    # Encrypt it (AES256) and remove the plaintext
    gpg --symmetric --cipher-algo AES256 /etc/restic-ops/restic.env
    rm /etc/restic-ops/restic.env
    ```

### 2. Initialize
1.  **Prime the GPG Agent:** (Required once per reboot/session)
    ```sh
    export GNUPGHOME=/root/.gnupg
    gpg -d /etc/restic-ops/restic.env.gpg >/dev/null
    ```

2.  **Initialize the Repo & Run First Backup:**
    ```sh
    /usr/local/bin/restic-ops/bin/init.sh
    /usr/local/bin/restic-ops/bin/backup.sh
    ```

### 3. Automate
Enable the provided systemd timers for daily backups and weekly retention.

```sh
cp systemd/restic-*.service systemd/restic-*.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now restic-backup.timer restic-retention.timer restic-prune.timer
```
