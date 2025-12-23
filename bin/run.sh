#!/usr/bin/env sh
# restic-admin context switcher
# Usage: ./run.sh <hostname> <command> [args...]

set -eu

# 1. Resolve Admin Root
ADMIN_ROOT="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
# Handle symlinked bin directory
if [ -L "$ADMIN_ROOT" ] || [ "$(basename "$ADMIN_ROOT")" = "bin" ]; then
    # If we are in bin/, the root is one level up
    # However, for the symlink setup, we need the relative etc/ next to the wrapper
    # We assume run.sh is called via the symlink or from the root
    ETC_DIR="$PWD/etc"
    BIN_DIR="$PWD/bin"
    # Fallback if PWD is not the root
    if [ ! -d "$ETC_DIR" ]; then
       ETC_DIR="$ADMIN_ROOT/../etc"
       BIN_DIR="$ADMIN_ROOT"
    fi
else
    BIN_DIR="$ADMIN_ROOT/bin"
    ETC_DIR="$ADMIN_ROOT/etc"
fi

# 2. Fix Environment
export GNUPGHOME="$HOME/.gnupg"
export GPG_TTY=$(tty)
export RESTIC_CACHE_DIR="$HOME/.cache/restic-admin"
mkdir -p "$RESTIC_CACHE_DIR"

# 3. Usage / Help
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <host> <command> [args...]"
    exit 1
fi

# 4. Parse Arguments
HOST="$1"
CMD="$2"
shift 2

# 5. Construct Paths
case "$CMD" in
    *.sh) TOOL_NAME="$CMD" ;;
    *)    TOOL_NAME="${CMD}.sh" ;;
esac

TOOL_PATH="$BIN_DIR/$TOOL_NAME"
SECRETS_FILE="$ETC_DIR/${HOST}-restic.env.gpg"

if [ ! -f "$SECRETS_FILE" ]; then
    echo "❌ Error: Config '$SECRETS_FILE' not found."
    exit 1
fi

# 6. Auto-Priming & Pass-Through
echo "🚀 [Admin Console] Target: $HOST | Tool: $TOOL_NAME"
export SECRETS="$SECRETS_FILE"

# Try to read silently first (if Agent happens to have it)
if ! gpg --batch --quiet --pinentry-mode loopback --decrypt "$SECRETS" >/dev/null 2>&1; then
    echo "🔐 Password required for host: $HOST"
    
    # Securely read password
    stty -echo
    printf "Enter Password: "
    read PASS
    stty echo
    echo ""

    # VALIDATE: Check if password is correct
    if ! echo "$PASS" | gpg --batch --quiet --no-tty --passphrase-fd 0 --decrypt "$SECRETS" >/dev/null 2>&1; then
        echo "❌ Decryption failed. Wrong password?"
        unset PASS
        exit 1
    fi
    
    # EXPORT: Pass the password to common.sh in memory
    export ADMIN_GPG_PASS="$PASS"
fi

exec "$TOOL_PATH" "$@"
