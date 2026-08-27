#!/usr/bin/env sh
# restic-ops: backup wrapper with anomaly detection
set -eu
SCRIPT_DIR="$(CDPATH="" cd -- "$(dirname "$0")" && pwd)"
# shellcheck source=bin/common.sh
. "$SCRIPT_DIR/common.sh"

load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

[ -f "$INCLUDE_FILE" ] || { log "ERROR: include file missing: $INCLUDE_FILE"; exit 1; }

TMP_LOG=$(mktemp)
trap 'rm -f "$TMP_LOG"' EXIT

log "Starting backup to $RESTIC_REPOSITORY"

set +e
restic -r "$RESTIC_REPOSITORY" backup \
  --files-from "$INCLUDE_FILE" \
  --exclude-file "$EXCLUDE_FILE" \
  --exclude-caches \
  --one-file-system \
  "$@" > "$TMP_LOG" 2>&1
EXIT_CODE=$?
set -e

ADDED_LINE=$(grep "Added to the repository:" "$TMP_LOG" || true)

# Threshold: Trigger diff analysis if growth is in GiB or TiB
if printf "%s" "$ADDED_LINE" | grep -qE "GiB|TiB"; then
    printf "========================================\n"
    printf "[ANOMALY] Exceptional data growth detected!\n"
    printf "%s\n" "$ADDED_LINE"
    printf "========================================\n"
    printf "Changes compared to the previous snapshot:\n\n"
    
    # Calls the updated stats.sh to show exactly what caused the anomaly
    "$SCRIPT_DIR/stats.sh" -H "$(hostname)" -L 2 -m diff || true
    
    printf "\n========================================\n"
    printf "Original Restic Log:\n"
    printf "========================================\n\n"
elif [ $EXIT_CODE -ne 0 ]; then
    printf "[FAIL] Backup failed (Exit code: %d)\n\n" "$EXIT_CODE"
else
    printf "[OK] Routine backup successful. %s\n\n" "${ADDED_LINE:-No changes.}"
fi

cat "$TMP_LOG"
exit $EXIT_CODE
