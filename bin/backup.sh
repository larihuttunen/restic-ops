#!/usr/bin/env sh
# restic-ops: backup wrapper with anomaly detection and external mount safety
set -eu
SCRIPT_DIR="$(CDPATH="" cd -- "$(dirname "$0")" && pwd)"
# shellcheck source=bin/common.sh
. "$SCRIPT_DIR/common.sh"

load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

[ -f "$INCLUDE_FILE" ] || { log "ERROR: include file missing: $INCLUDE_FILE"; exit 1; }

TMP_LOG=$(mktemp)
SAFE_INCLUDES=$(mktemp)
trap 'rm -f "$TMP_LOG" "$SAFE_INCLUDES"' EXIT

# --- 1. Internal Paths ---
cat "$INCLUDE_FILE" > "$SAFE_INCLUDES"

# --- 2. External Paths with Canary Check ---
INCLUDE_EXT="${CONF_DIR:-/etc/restic-ops}/include-external.txt"
if [ -f "$INCLUDE_EXT" ]; then
    while IFS= read -r ext_path || [ -n "$ext_path" ]; do
        # Skip comments and empty lines
        case "$ext_path" in "#"*|"") continue ;; esac
        
        # Check for canary marker
        if [ -f "${ext_path%/}/.restic.marker" ]; then
            printf "%s\n" "$ext_path" >> "$SAFE_INCLUDES"
            log "Included external path: $ext_path"
        else
            log "WARN: Marker missing or disk detached. Skipping: $ext_path"
        fi
    done < "$INCLUDE_EXT"
fi

log "Starting backup to $RESTIC_REPOSITORY"

set +e
restic -r "$RESTIC_REPOSITORY" backup \
  --files-from "$SAFE_INCLUDES" \
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
