#!/usr/bin/env sh
# Usage: retention.sh
set -eu
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

SECRETS="$SCRIPT_DIR/../conf/secrets/restic.env.gpg"
load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

KEEP_DAILY="${KEEP_DAILY:-31}"
KEEP_MONTHLY="${KEEP_MONTHLY:-24}"
KEEP_YEARLY="${KEEP_YEARLY:-4}"

log "Applying retention to $RESTIC_REPOSITORY (daily=$KEEP_DAILY monthly=$KEEP_MONTHLY yearly=$KEEP_YEARLY)"
restic forget --keep-daily "$KEEP_DAILY" --keep-monthly "$KEEP_MONTHLY" --keep-yearly "$KEEP_YEARLY" --prune
RC=$?
[ "$RC" -eq 0 ] || { log "ERROR: retention failed (rc=$RC)"; exit "$RC"; }
log "Retention completed"
