#!/usr/bin/env sh
# restic-ops: select a named profile and run an existing primitive
set -eu

PROGRAM=${0##*/}
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

PROFILE_ROOT=${RESTIC_OPS_PROFILE_ROOT:-/etc/restic-ops/profiles}

usage() {
    cat >&2 <<EOF
Usage:
  $PROGRAM PROFILE OPERATION [ARGUMENT ...]

Operations:
  init
  backup
  restore
  snapshots
  stats
  check
  retention
  prune
  unlock
  prime-gpg

Environment:
  RESTIC_OPS_PROFILE_ROOT
      Profile root directory.
      Default: /etc/restic-ops/profiles

Example:
  $PROGRAM CASE-2026-0001 backup
EOF
    exit 64
}

die() {
    code=$1
    shift
    printf '%s: %s\n' "$PROGRAM" "$*" >&2
    exit "$code"
}

[ "$#" -ge 2 ] || usage

PROFILE=$1
OPERATION=$2
shift 2

# Validate the profile identifier
case "$PROFILE" in
    ''|.|..|*[!A-Za-z0-9._-]*) die 64 "invalid profile name: $PROFILE" ;;
esac
[ "${#PROFILE}" -le 128 ] || die 64 "profile name exceeds 128 characters"

# Profile-specific paths
PROFILE_DIR=$PROFILE_ROOT/$PROFILE
CONF_DIR=$PROFILE_DIR
SECRETS=$PROFILE_DIR/restic.env.gpg
INCLUDE_FILE=$PROFILE_DIR/include.txt
EXCLUDE_FILE=$PROFILE_DIR/exclude.txt

# Validate the profile before invoking primitives
[ -d "$PROFILE_DIR" ] || die 66 "profile not found: $PROFILE"
[ -f "$SECRETS" ] || die 66 "encrypted secrets not found: $SECRETS"

# Map operations to primitives
case "$OPERATION" in
    init)      TARGET=$SCRIPT_DIR/init.sh ;;
    backup)    TARGET=$SCRIPT_DIR/backup.sh ;;
    restore)   TARGET=$SCRIPT_DIR/restore.sh ;;
    snapshots) TARGET=$SCRIPT_DIR/list.sh ;;
    stats)     TARGET=$SCRIPT_DIR/stats.sh ;;
    check)     TARGET=$SCRIPT_DIR/check.sh ;;
    retention) TARGET=$SCRIPT_DIR/retention.sh ;;
    prune)     TARGET=$SCRIPT_DIR/prune.sh ;;
    unlock)    TARGET=$SCRIPT_DIR/unlock.sh ;;
    prime-gpg) TARGET=$SCRIPT_DIR/prime-gpg.sh ;;
    *)         die 64 "unsupported operation: $OPERATION" ;;
esac

[ -f "$TARGET" ] && [ -x "$TARGET" ] || die 69 "operation script missing or not executable: $TARGET"

export SECRETS

# Interactive GPG Auto-Priming (Admin Context)
if ! gpg --batch --quiet --pinentry-mode loopback --decrypt "$SECRETS" >/dev/null 2>&1; then
    if [ -t 0 ]; then
        printf "Password required for profile/host: %s\n" "$PROFILE"
        stty -echo
        printf "Enter Password: "
        read -r PASS
        stty echo
        printf "\n"

        if ! printf "%s" "$PASS" | gpg --batch --quiet --no-tty --passphrase-fd 0 --decrypt "$SECRETS" >/dev/null 2>&1; then
            unset PASS
            die 1 "Decryption failed. Wrong password?"
        fi
        
        # Export for memory pass-through in common.sh
        export ADMIN_GPG_PASS="$PASS"
        
        # Ensure Admin Cache Isolation
        export RESTIC_CACHE_DIR="$HOME/.cache/restic-admin"
        mkdir -p "$RESTIC_CACHE_DIR"
    else
        die 1 "GPG decryption failed and no TTY available for prompt. Agent cache may be empty."
    fi
fi

# Export the selected profile context
export RESTIC_OPS_PROFILE=$PROFILE
export RESTIC_OPS_PROFILE_DIR=$PROFILE_DIR
export CONF_DIR INCLUDE_FILE EXCLUDE_FILE

# Execute the primitive
exec "$TARGET" "$@"
