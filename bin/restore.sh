#!/usr/bin/env sh
# Usage: restore.sh <profile> <snapshot-id|latest> <target-dir> [--include ... | --exclude ...]
set -eu
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

PROFILE="${1:-}"; SNAP="${2:-}"; TARGET="${3:-}"
[ -n "$PROFILE" ] && [ -n "$SNAP" ] && [ -n "$TARGET" ] || {
  echo "Usage: $0 <profile> <snapshot-id|latest> <target-dir> [restic restore args]"; exit 1; }
shift 3 || true

SECRETS="$SCRIPT_DIR/../conf/secrets/${PROFILE}.env.gpg"
load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

mkdir -p "$TARGET"
log "Restoring snapshot '$SNAP' to '$TARGET' from $RESTIC_REPOSITORY"
restic restore "$SNAP" --target "$TARGET" "$@"
log "Restore completed"
