#!/usr/bin/env sh
set -eu
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

[ -f "$INCLUDE_FILE" ] || { log "ERROR: include file missing: $INCLUDE_FILE"; exit 1; }

if ! restic -r "$RESTIC_REPOSITORY" snapshots >/dev/null 2>&1; then
    log "Repository $RESTIC_REPOSITORY not found – initialising"
    restic -r "$RESTIC_REPOSITORY" init
fi

log "Starting backup to $RESTIC_REPOSITORY"
restic -r "$RESTIC_REPOSITORY" backup \
  --files-from "$INCLUDE_FILE" \
  --exclude-file "$EXCLUDE_FILE" \
  --exclude-caches \
  --one-file-system \
  "$@"
