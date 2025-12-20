# Admin Guide — restic-ops

This guide covers daily and periodic operations after deployment.  
Assume you are working as root (`sudo su -`).

---

## Listing snapshots

```sh
/usr/local/bin/restic-ops/bin/list.sh --json
# Add --host, --tag, --path, --group-by as needed
````

***

## Stats

```sh
/usr/local/bin/restic-ops/bin/stats.sh --mode restore-size --latest 1
/usr/local/bin/restic-ops/bin/stats.sh -H <host> --since 30d --mode raw-data
```

***

## Prune (heavy maintenance, scheduled monthly)

```sh
/usr/local/bin/restic-ops/bin/prune.sh
# Example: dry run
/usr/local/bin/restic-ops/bin/prune.sh --dry-run
```

***

## Manual runs and tests

```sh
/usr/local/bin/restic-ops/bin/backup.sh
/usr/local/bin/restic-ops/bin/retention.sh
/usr/local/bin/restic-ops/bin/prune.sh
```

***

## Config files (persistent)

*   `/etc/restic-ops/include.txt`
*   `/etc/restic-ops/exclude.txt`
*   `/etc/restic-ops/restic.env.gpg`

*(Sample defaults live under `/usr/local/bin/restic-ops/conf/*.sample`, never edited.)*

***

## Priming the gpg-agent cache (after reboot)

```sh
export GNUPGHOME=/root/.gnupg
gpg -d /etc/restic-ops/restic.env.gpg >/dev/null
```

***

## Troubleshooting

*   **Headless decrypt test:**
    ```sh
    env -i GNUPGHOME=/root/.gnupg gpg --batch --yes -d /etc/restic-ops/restic.env.gpg | head
    ```
*   **Logs:**
    *   systemd: `journalctl -u restic-backup.service -n 50`
    *   cron (BSD): `/var/log/restic-*.log`

***

## See also

*   `docs/Deployment.md` for install/upgrade.
*   `docs/CRON.md` for BSD/cron scheduling.
