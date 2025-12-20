#!/usr/bin/env sh
set -eu
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

if ! restic -r "$RESTIC_REPOSITORY" snapshots >/dev/null 2>&1; then
    log "Repository $RESTIC_REPOSITORY not found - initialising"
    restic -r "$RESTIC_REPOSITORY" init
fi
