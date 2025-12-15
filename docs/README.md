# restic-ops

Minimal, storage-agnostic restic toolkit:
- **Daily backups** via systemd timer or cron
- **Restore** by snapshot ID or `latest`
- **Retention**: keep daily/monthly/annual snapshots (forget+prune)
- Secrets in **GPG-encrypted .env.gpg** files (no IAM dependency)

## Quick start
1. Edit `conf/include.txt` and `conf/exclude.txt`.
2. Create `conf/secrets/<profile>.env` with `export` lines, then encrypt with GPG:
   ```sh
   gpg --encrypt --recipient YOUR_KEY_ID conf/secrets/<profile>.env
   rm conf/secrets/<profile>.env
  

