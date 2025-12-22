#!/usr/bin/env sh
set -eu
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

# Defaults (can be overridden in restic.env)
KEEP_LAST="${KEEP_LAST:-}"
KEEP_DAILY="${KEEP_DAILY:-31}"
KEEP_WEEKLY="${KEEP_WEEKLY:-}"
KEEP_MONTHLY="${KEEP_MONTHLY:-24}"
KEEP_YEARLY="${KEEP_YEARLY:-4}"

log "Applying retention to $RESTIC_REPOSITORY"

# Build command dynamically based on set variables
CMD="restic forget"
[ -n "$KEEP_LAST" ]    && CMD="$CMD --keep-last $KEEP_LAST"
[ -n "$KEEP_DAILY" ]   && CMD="$CMD --keep-daily $KEEP_DAILY"
[ -n "$KEEP_WEEKLY" ]  && CMD="$CMD --keep-weekly $KEEP_WEEKLY"
[ -n "$KEEP_MONTHLY" ] && CMD="$CMD --keep-monthly $KEEP_MONTHLY"
[ -n "$KEEP_YEARLY" ]  && CMD="$CMD --keep-yearly $KEEP_YEARLY"

# Run (without prune, as discussed)
# shellcheck disable=SC2086
$CMD
RC=$?

[ "$RC" -eq 0 ] || { log "ERROR: retention failed (rc=$RC)"; exit "$RC"; }
log "Retention policy applied"
