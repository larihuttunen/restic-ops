#!/usr/bin/env sh
set -eu
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

SNAP="${1:-}"
TARGET="${2:-}"
if [ -z "$SNAP" ] || [ -z "$TARGET" ]; then
  echo "Usage: $0 <snapshot-id|latest> <target-dir> [restic restore args]"
  exit 1
fi
shift 2 || true

load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

mkdir -p "$TARGET"
log "Restoring snapshot '$SNAP' to '$TARGET' from $RESTIC_REPOSITORY"
restic restore "$SNAP" --target "$TARGET" "$@"
log "Restore completed"
