# Deployment Guide (Linux, systemd) — restic-ops

This guide covers installing and upgrading restic-ops using the self-extracting release.
Configuration is always stored in `/etc/restic-ops` and is never overwritten by upgrades.

---

## Dependencies

**Required (Linux):**
- restic
- gpg (and pinentry)
- systemd

**Optional:**
* `jq` (for enhanced stats output)
* `logrotate` (for log file management)

---

## Directory Layout

- **Code (versioned):** `/usr/local/lib/restic-ops/vN.N.N/`
- **Symlink:** `/usr/local/bin/restic-ops` → current version
- **Config (persistent):** `/etc/restic-ops/`
  - `include.txt`
  - `exclude.txt`
  - `restic.env.gpg` (encrypted secrets)

---

## Installation Steps

* **Install dependencies.**

* **Download and verify the release:**
- Download `restic-ops.run` and its `.asc` signature.
- Verify with GPG (see Releases.md).

* **Extract the release:**
```sh
mkdir -p /usr/local/lib/restic-ops/vN.N.N
cd /usr/local/lib/restic-ops/vN.N.N
/path/to/restic-ops.run
```

* **Symlink current version:**
```sh
ln -sfn /usr/local/lib/restic-ops/vN.N.N /usr/local/bin/restic-ops
```

* **Create persistent config:**
```sh
mkdir -p /etc/restic-ops
cp /usr/local/bin/restic-ops/conf/*.txt /etc/restic-ops/
vi /etc/restic-ops/include.txt
vi /etc/restic-ops/exclude.txt
```


* **Create and encrypt secrets:**
```sh
cp /usr/local/bin/restic-ops/conf/secrets/restic.env /etc/restic-ops/restic.env
vi /etc/restic-ops/restic.env
gpg --symmetric --cipher-algo AES256 /etc/restic-ops/restic.env
rm /etc/restic-ops/restic.env
```


* **Configure GPG Agent Persistence (40-Day Cache):**
To ensure headless backups work for extended periods without manual intervention, configure the GPG agent to cache the passphrase for 40 days ( seconds).

- **Configure TTL:**
Edit `/root/.gnupg/gpg-agent.conf`:
```ini
default-cache-ttl 3456000
max-cache-ttl 3456000
```

- **Restart Agent:**
```sh
gpgconf --kill gpg-agent
```

* **Prime gpg-agent cache:**
Run the helper script to interactively cache your passphrase. You will need to run this once every 40 days (or after a reboot).
```sh
/usr/local/bin/restic-ops/bin/prime-gpg.sh
```

## Initial Setup

* **Initialize repository:**
```sh
/usr/local/bin/restic-ops/bin/init.sh

```


* **Seed first backup:**
```sh
/usr/local/bin/restic-ops/bin/backup.sh

```



## Enable Automation (systemd)

1. **Copy systemd units:**
```sh
cp /usr/local/bin/restic-ops/systemd/restic-*.service /etc/systemd/system/
cp /usr/local/bin/restic-ops/systemd/restic-*.timer /etc/systemd/system/
systemctl daemon-reload

```


2. **Enable timers:**
```sh
systemctl enable --now restic-backup.timer restic-retention.timer restic-prune.timer

```


3. **(Optional) Enable persistent gpg-agent:**
If you prefer managing the agent via systemd to ensure it restarts automatically:
```sh
cp /usr/local/bin/restic-ops/systemd/gpg-agent-root.service /etc/systemd/system/
systemctl enable --now gpg-agent-root.service

```



## Upgrading

1. **Extract new release to a new versioned directory.**
2. **Switch symlink:**
```sh
rm /usr/local/bin/restic-ops
ln -sfn /usr/local/lib/restic-ops/vN.N.N /usr/local/bin/restic-ops

```


3. **Do not touch `/etc/restic-ops**`—your config stays put.
4. **Reload systemd and restart timers:**
```sh
systemctl daemon-reload
systemctl restart restic-backup.timer restic-retention.timer restic-prune.timer

```



## Verification

* **Headless decrypt test:**
```sh
env -i GNUPGHOME=/root/.gnupg gpg --batch --yes -d /etc/restic-ops/restic.env.gpg | head
```


* **Check timers:**
```sh
systemctl list-timers | grep restic
journalctl -u restic-backup.service -n 50

```



### Check Timers

See `cron/CRON.md` for scheduling via cron.

## See Also

* `docs/Admin.md` for daily operations and troubleshooting.
* `docs/Releases.md` for release verification.
* `cron/README.md` for BSD/cron scheduling.
