# CRON jobs: schedule restic scripts without systemd

If you don’t (or can’t) use systemd timers to schedule your backups, retention pruning and cache cleaning, you can achieve the same effect with traditional cron. Cron is a simple scheduler available on virtually every Unix-like system. This document shows how to translate the schedules defined in the systemd units into a set of entries for your crontab.

## Why use cron?

Systemd timers are convenient when you run a systemd-enabled distribution. They integrate nicely with the rest of the init system and can track the last run, show status and enforce ordering. However, if you’re on a platform without systemd, or you simply prefer the familiar cron syntax, a few lines in your `crontab` will do exactly the same work:

  * Kick off your backup every night at a fixed hour instead of via a `restic-backup.timer`.
  * Run the retention cleanup once per week in place of your `restic-retention.timer`.
  * Purge the local restic cache once per week instead of using `restic-cache-clean.timer`.

## Example cron entries

Below are example lines you can drop into your crontab or a file under `/etc/cron.d`. Adjust the paths to point at where you installed your scripts (the examples assume they live in `/usr/local/bin/restic-ops/bin/`) and where you keep your cache (`/var/cache/restic`):

```cron
# Daily backup at 02:00 – run your helper script and send all output to a logfile
0 2 * * * /usr/local/bin/restic-ops/bin/backup.sh >> /var/log/restic-backup.log 2>&1

# Weekly retention cleanup on Sunday at 03:30 – prune old snapshots
30 3 * * 0 /usr/local/bin/restic-ops/bin/retention.sh >> /var/log/restic-retention.log 2>&1

# Weekly cache cleanup on Sunday at 04:00 – run the restic cache cleanup directly
0 4 * * 0 /usr/bin/restic cache --cleanup --max-age 30 --cache-dir /var/cache/restic >> /var/log/restic-cache-clean.log 2>&1
```

**Notes:**

  * Make sure your scripts are executable (`chmod +x bin/*.sh`). If the location differs, substitute your own path. For example, if you cloned into `/home/youruser/restic-ops` then the first line becomes `0 2 * * * /home/youruser/restic-ops/bin/backup.sh >> /var/log/restic-backup.log 2>&1`.
  * The cache cleanup line doesn’t call a script; it shows how to run the restic cache cleanup directly. If you wrote your own wrapper (similar to the other helpers), call that script instead of the bare `restic cache --cleanup`.
  * You can adjust times (the hour/minute fields) to suit your own policy, just as you would the `OnCalendar` values in the systemd units.
  * Logging: by redirecting stdout and stderr to files under `/var/log` you capture logs for later inspection. You’ll likely want to set up a `logrotate` rule so these files don’t grow without bound.

## Installing the cron jobs

To install these entries, you have a couple of options:

  * Edit your own crontab: run `crontab -e` as the user that should execute the jobs (often root, if you need access to arbitrary files) and paste in the three lines.
  * Create a dedicated file under `/etc/cron.d`: name it something like `/etc/cron.d/restic`, prefix each line with a username (for example, `root`) and save it. Files in `/etc/cron.d` must have the format:
    ```text
    # m h dom mon dow user command
    0 2 * * * root /path/to/backup.sh >> /var/log/restic-backup.log 2>&1
    … etc …
    ```
    Cron will pick up any valid files in `/etc/cron.d` automatically.

After saving your edits, you can list installed cron entries with `crontab -l` (for the current user) or by inspecting `/etc/cron.d/restic`. Make sure the syntax is correct: an incorrect entry will cause cron to reject the entire file.

## Further customization

  * Change the schedule: modify the numbers in the left-hand fields as you would for any cron job. See `man 5 crontab` for details about minute, hour, day, month and weekday specifications.
  * Change the destination of your logs: point them at other files, or pipe through `logger` if you’d prefer journald integration.
  * Add environment: if you need certain environment variables (such as secrets loaded from your encrypted file), either:  
    – Put an `ENV=value` declaration at the top of your crontab.  
    – Prefix the commands with an `eval "$(gpg --quiet --batch --decrypt /path/to/restic.env.gpg)" && …` clause to decrypt before running.  
    – Source your `common.sh` from within the scripts themselves (our helpers already do that).

For the canonical, more detailed explanation of variables, encryption and other topics, consult the [Deployment Guide](../docs/Deployment.md).
