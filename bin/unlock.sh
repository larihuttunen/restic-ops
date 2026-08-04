#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH="" cd -- "$(dirname "$0")" && pwd)"
# shellcheck source=bin/common.sh
. "$SCRIPT_DIR/common.sh"

load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

log "Removing stale locks from $RESTIC_REPOSITORY"

if ! restic -r "$RESTIC_REPOSITORY" unlock; then
    log "ERROR: failed to remove stale locks from $RESTIC_REPOSITORY"
    exit 1
fi

log "Unlock completed"
