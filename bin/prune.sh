#!/usr/bin/env sh
set -eu
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

SECRETS="$SCRIPT_DIR/../conf/secrets/restic.env.gpg"
load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

# Note: prune is separate from forget; it actually removes unreferenced data.
# Keep output visible for operators; allow extra args to pass through.
log "Pruning repository $RESTIC_REPOSITORY"
restic -r "$RESTIC_REPOSITORY" prune "$@"
RC=$?
[ "$RC" -eq 0 ] || {[ "$RC" -eq 0 ] || { log "ERROR: prune failed (rc=$RC)"; exit "$RC"; }
