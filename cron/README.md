# CRON jobs: schedule restic-ops scripts without systemd

If you don’t (or can’t) use systemd timers to schedule your backups, retention, and prune jobs, you can achieve the same effect with traditional cron. This is the standard scheduler on BSD (FreeBSD, OpenBSD, NetBSD) and works on all Unix-like systems.

## Why use cron?

- **Universal:** Works everywhere, including BSDs and minimal Linux.
- **Simple:** No systemd dependencies.
- **Flexible:** Easy to adjust schedules, users, and logging.

---

## Example cron entries

Below are example lines for a root crontab (`crontab -e` as root), matching the systemd timer schedules and using your helper scripts:

```cron
# Environment for gpg-agent alignment (optional but recommended)
GNUPGHOME=/root/.gnupg

# Daily backup at 02:00
0 2 * * * /usr/local/bin/restic-ops/bin/backup.sh >> /var/log/restic-backup.log 2>&1

# Weekly retention on Sunday at 03:30
30 3 * * 0 /usr/local/bin/restic-ops/bin/retention.sh >> /var/log/restic-retention.log 2>&1

# Monthly prune (first Sunday at 04:00)
# Note: % must be escaped as \% in crontabs to avoid being interpreted as a newline
0 4 * * 0 [ $(date +\%d) -le 07 ] && /usr/local/bin/restic-ops/bin/prune.sh >> /var/log/restic-prune.log 2>&1

```

**If using `/etc/crontab` or `/etc/cron.d/restic**` (Standard on many Linux distros and some BSD configurations), add the user column (usually `root`):

```cron
# m h dom mon dow user command
0 2 * * * root /usr/local/bin/restic-ops/bin/backup.sh >> /var/log/restic-backup.log 2>&1
30 3 * * 0 root /usr/local/bin/restic-ops/bin/retention.sh >> /var/log/restic-retention.log 2>&1
0 4 * * 0 root test $(date +\%d) -le 07 && /usr/local/bin/restic-ops/bin/prune.sh >> /var/log/restic-prune.log 2>&1

```

---

## BSD-specific notes

* **Shell:** BSD cron uses `/bin/sh` by default. All restic-ops scripts are POSIX-compliant.
* **Environment:** * Set `GNUPGHOME=/root/.gnupg` at the top of your crontab for gpg-agent socket alignment.
* Scripts already decrypt secrets at runtime; no need to inline `gpg` in cron.


* **Logging:** * Output is redirected to log files in `/var/log/`.
* On OpenBSD/FreeBSD, set up `newsyslog.conf` to rotate these logs; use `logrotate` on Linux.


* **Permissions:** * Scripts must be executable: `chmod +x bin/*.sh`.
* If running as a non-root user, ensure access to all backup paths and GPG keyring.



---

## Customizing for your BSD system

* **Change times** as needed (see `man 5 crontab`).
* **Change log destinations** or pipe through `logger` for syslog integration:
```cron
0 2 * * * /usr/local/bin/restic-ops/bin/backup.sh 2>&1 | logger -t restic-backup

```


* **Check jobs:**
* `crontab -l` (per user).
* `cat /etc/crontab` or `ls /etc/cron.d/`.
* Review logs in `/var/log/`.



---

## Priming the gpg-agent cache

After a reboot or agent restart, prime the cache once interactively so the cron jobs can run headlessly:

```sh
export GNUPGHOME=/root/.gnupg
gpg -d /etc/restic-ops/restic.env.gpg >/dev/null

```

---

## See also

* `docs/Deployment.md` for environment, encryption, and troubleshooting details.
