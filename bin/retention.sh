#!/usr/bin/env sh
# Usage: retention.sh <profile>
set -eu
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

PROFILE="${1:-}"
[ -n "$PROFILE" ] || { echo "Usage: $0 <profile>"; exit 1; }

SECRETS="$SCRIPT_DIR/../conf/secrets/${PROFILE}.env.gpg"
load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

# Retention policy: adjust to taste
KEEP_DAILY="${KEEP_DAILY:-14}"
KEEP_MONTHLY="${KEEP_MONTHLY:-6}"
KEEP_YEARLY="${KEEP_YEARLY:-3}"

log "Applying retention to $RESTIC_REPOSITORY (daily=$KEEP_DAILY monthly=$KEEP_MONTHLY yearly=$KEEP_YEARLY)"
restic forget --keep-daily "$KEEP_DAILY" --keep-monthly "$KEEP_MONTHLY" --keep-yearly "$KEEP_YEARLY" --prune
RC=$?
[ "$RC" -eq 0 ] || { log "ERROR: retention failed (rc=$RC)"; exit "$RC"; }
log "Retention completed"
