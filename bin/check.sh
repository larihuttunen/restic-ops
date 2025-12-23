#!/usr/bin/env sh
set -eu
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

log "Checking repository integrity for $RESTIC_REPOSITORY"

# Runs restic check.
# Any arguments passed to this script (like --read-data-subset=1G) 
# are forwarded directly to restic.
restic -r "$RESTIC_REPOSITORY" check "$@"
RC=$?

[ "$RC" -eq 0 ] || { log "ERROR: check failed (rc=$RC)"; exit "$RC"; }
