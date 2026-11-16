#!/usr/bin/env sh
# restic-ops: execute an operation across all configured profiles sequentially
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PROFILE_ROOT=${RESTIC_OPS_PROFILE_ROOT:-/etc/restic-ops/profiles}

if [ "$#" -lt 1 ]; then
    printf "Usage: foreach.sh OPERATION [ARGUMENT ...]\n" >&2
    exit 64
fi

OPERATION=$1
shift 1

if [ ! -d "$PROFILE_ROOT" ]; then
    printf "No profiles found in %s\n" "$PROFILE_ROOT" >&2
    exit 0
fi

for path in "$PROFILE_ROOT"/*; do
    [ -d "$path" ] || continue
    PROFILE=$(basename "$path")
    
    printf "\n========================================\n"
    printf "PROFILE: %s\n" "$PROFILE"
    printf "========================================\n"
    
    # Use '|| true' so a failure in one profile doesn't stop the loop
    "$SCRIPT_DIR/selector.sh" "$PROFILE" "$OPERATION" "$@" || printf "[FAIL] Failed: %s\n" "$PROFILE"
done
