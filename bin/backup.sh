#!/usr/bin/env sh
# Usage: backup.sh <profile> [extra restic backup args...]
set -eu
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

PROFILE="${1:-}"; [ -n "$PROFILE" ] || { echo "Usage: $0 <profile>"; exit 1; }
shift || true

SECRETS="$SCRIPT_DIR/../conf/secrets/${PROFILE}.env.gpg"
load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

INCLUDE_FILE="$SCRIPT_DIR/../conf/include.txt"
EXCLUDE_FILE="$SCRIPT_DIR/../conf/exclude.txt"
[ -f "$INCLUDE_FILE" ] || { log "ERROR: include file missing: $INCLUDE_FILE"; exit 1; }

log "Starting backup to $RESTIC_REPOSITORY (profile=$PROFILE)"
restic backup \
  --files-from "$INCLUDE_FILE" \
  --exclude-file "$EXCLUDE_FILE" \
  --exclude-caches \
  --one-file-system \
  "$@"
RC=$?
[ "$RC" -eq 0 ] || { log "ERROR: backup failed (rc=$RC)"; exit "$RC"; }
log "Backup completed"
