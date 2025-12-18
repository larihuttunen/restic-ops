# Deployment Guide (Linux, systemd) — restic-ops

This guide covers installing and upgrading restic-ops using the self-extracting release.  
Configuration is always in `/etc/restic-ops` and is never overwritten by upgrades.

---

## Dependencies

**Required (Linux):**
- restic
- gpg (and pinentry)
- bash
- systemd

**Optional:**
- jq (for enhanced stats output)
- logrotate (for log file management)

---

## Directory Layout

- **Code (versioned):** `/usr/local/lib/restic-ops/v0.2.0/`
- **Symlink:** `/usr/local/bin/restic-ops` → current version
- **Config (persistent):** `/etc/restic-ops/`
  - `include.txt`
  - `exclude.txt`
  - `restic.env.gpg` (encrypted secrets)

---

## Installation Steps

1. **Install dependencies.**
2. **Download and verify the release:**
   - Download `restic-ops.run` and its `.asc` signature.
   - Verify with GPG (see Releases.md).
3. **Extract the release:**
   ```sh
   mkdir -p /usr/local/lib/restic-ops/v0.2.0
   cd /usr/local/lib/restic-ops/v0.2.0
   /path/to/restic-ops.run
````

4.  **Symlink current version:**
    ```sh
    ln -sfn /usr/local/lib/restic-ops/v0.2.0 /usr/local/bin/restic-ops
    ```
5.  **Create persistent config:**
    ```sh
    mkdir -p /etc/restic-ops
    cp /usr/local/bin/restic-ops/conf/include.sample.txt /etc/restic-ops/include.txt
    cp /usr/local/bin/restic-ops/conf/exclude.sample.txt /etc/restic-ops/exclude.txt
    vi /etc/restic-ops/include.txt
    vi /etc/restic-ops/exclude.txt
    ```
6.  **Create and encrypt secrets:**
    ```sh
    vi /etc/restic-ops/restic.env
    gpg --symmetric --cipher-algo AES256 /etc/restic-ops/restic.env
    rm /etc/restic-ops/restic.env
    ```
7.  **Prime gpg-agent cache (once per reboot/agent restart):**
    ```sh
    export GNUPGHOME=/root/.gnupg
    gpg -d /etc/restic-ops/restic.env.gpg >/dev/null
    ```

***

## Initial Setup

*   **Initialize repository:**
    ```sh
    /usr/local/bin/restic-ops/bin/init.sh
    ```
*   **Seed first backup:**
    ```sh
    /usr/local/bin/restic-ops/bin/backup.sh
    ```

***

## Enable Automation (systemd)

1.  **Copy systemd units:**
    ```sh
    cp /usr/local/bin/restic-ops/systemd/restic-*.service /etc/systemd/system/
    cp /usr/local/bin/restic-ops/systemd/restic-*.timer /etc/systemd/system/
    systemctl daemon-reload
    ```
2.  **Enable timers:**
    ```sh
    systemctl enable --now restic-backup.timer restic-retention.timer restic-prune.timer
    ```
3.  **(Optional) Enable persistent gpg-agent:**
    ```sh
    cp /usr/local/bin/restic-ops/systemd/gpg-agent-root.service /etc/systemd/system/
    systemctl enable --now gpg-agent-root.service
    ```

***

## Upgrading

1.  **Extract new release to a new versioned directory.**
2.  **Switch symlink:**
    ```sh
    ln -sfn /usr/local/lib/restic-ops/v0.2.1 /usr/local/bin/restic-ops
    ```
3.  **Do not touch `/etc/restic-ops`**—your config stays put.
4.  **Reload systemd and restart timers:**
    ```sh
    systemctl daemon-reload
    systemctl restart restic-backup.timer restic-retention.timer restic-prune.timer
    ```

***

## Verification

*   **Headless decrypt test:**
    ```sh
    env -i GNUPGHOME=/root/.gnupg gpg --batch --yes -d /etc/restic-ops/restic.env.gpg | head
    ```
*   **Check timers:**
    ```sh
    systemctl list-timers | grep restic
    journalctl -u restic-backup.service -n 50
    ```

***

## For BSD or cron-based installs

See `docs/CRON.md` for scheduling via cron.

***

## See also

*   `docs/Admin.md` for daily operations and troubleshooting.
*   `docs/CRON.md` for BSD/cron scheduling.
*   `docs/Releases.md` for release verification.
