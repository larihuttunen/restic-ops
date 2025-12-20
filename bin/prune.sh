#!/usr/bin/env sh
set -eu
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

log "Pruning repository $RESTIC_REPOSITORY"
restic -r "$RESTIC_REPOSITORY" prune "$@"
RC=$?
[ "$RC" -eq 0 ] || { log "ERROR: prune failed (rc=$RC)"; exit "$RC"; }
