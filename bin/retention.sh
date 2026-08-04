#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH="" cd -- "$(dirname "$0")" && pwd)"
# shellcheck source=bin/common.sh
. "$SCRIPT_DIR/common.sh"

load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

#
# Retention defaults.
#
# NOTE:
#   ${VAR-default}
#     -> applies default only if VAR is UNSET
#
#   ${VAR:-default}
#     -> applies default if VAR is UNSET OR EMPTY
#
# We intentionally use '-' so that users can disable a policy
# component by setting it empty in restic.env:
#
#   export KEEP_DAILY=
#
# while preserving defaults for deployments that do not define
# the variable at all.
#
KEEP_LAST="${KEEP_LAST-}"
KEEP_DAILY="${KEEP_DAILY-31}"
KEEP_WEEKLY="${KEEP_WEEKLY-}"
KEEP_MONTHLY="${KEEP_MONTHLY-24}"
KEEP_YEARLY="${KEEP_YEARLY-4}"

log "Applying retention to $RESTIC_REPOSITORY"

#
# Allow complete retention disablement.
#
# Useful for IR repositories where deletion should be explicit.
#
if [ -z "$KEEP_LAST$KEEP_DAILY$KEEP_WEEKLY$KEEP_MONTHLY$KEEP_YEARLY" ]; then
    log "No retention policy configured; skipping."
    exit 0
fi

#
# Build command safely without eval/string expansion.
#
set -- restic forget

[ -n "$KEEP_LAST" ]    && set -- "$@" --keep-last "$KEEP_LAST"
[ -n "$KEEP_DAILY" ]   && set -- "$@" --keep-daily "$KEEP_DAILY"
[ -n "$KEEP_WEEKLY" ]  && set -- "$@" --keep-weekly "$KEEP_WEEKLY"
[ -n "$KEEP_MONTHLY" ] && set -- "$@" --keep-monthly "$KEEP_MONTHLY"
[ -n "$KEEP_YEARLY" ]  && set -- "$@" --keep-yearly "$KEEP_YEARLY"

"$@"
RC=$?

[ "$RC" -eq 0 ] || {
    log "ERROR: retention failed (rc=$RC)"
    exit "$RC"
}

log "Retention policy applied"
