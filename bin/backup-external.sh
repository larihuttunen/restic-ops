#!/usr/bin/env sh
# ==============================================================================
# MANUAL BACKUP SCRIPT - EXTERNAL DISK
# Features: Auto-init, Canary Checks, Symmetric Encryption, Anomaly Detection
# ==============================================================================
set -eu

SCRIPT_DIR="$(CDPATH="" cd -- "$(dirname "$0")" && pwd)"

# Override default secrets path before loading common.sh
export SECRETS="/etc/restic-ops/restic.env.external-disk.gpg"

# shellcheck source=bin/common.sh
. "$SCRIPT_DIR/common.sh"

# Overwrite default include/exclude from common.sh
INCLUDE_FILE="/etc/restic-ops/include-external.txt"
EXCLUDE_FILE="/etc/restic-ops/exclude-external.txt"
export INCLUDE_FILE EXCLUDE_FILE

CANARY_NAME=".restic.marker"

# Essential for manual runs (GPG Pinentry)
GPG_TTY=$(tty || true)
export GPG_TTY

printf "========================================\n"
printf "[INFO] Manual Host Backup: External Disk\n"
printf "========================================\n"

# --- 1. Validation of Control Files ---
if [ ! -f "$SECRETS" ]; then
    printf "[ERROR] Config file missing: %s\n" "$SECRETS"
    exit 1
fi
if [ ! -f "$INCLUDE_FILE" ]; then
    printf "[ERROR] Include file missing: %s\n" "$INCLUDE_FILE"
    exit 1
fi

# --- 2. Canary Check (Source Safety) ---
printf "[INFO] Checking source mount points (Canaries)...\n"

while IFS= read -r dir || [ -n "$dir" ]; do
    # Skip comments and empty lines
    case "$dir" in
        "#"*|"") continue ;;
    esac

    CANARY_PATH="${dir%/}/$CANARY_NAME"
    if [ ! -f "$CANARY_PATH" ]; then
        printf "   [ERROR] CRITICAL: Canary missing in: %s\n" "$dir"
        printf "           Is the source disk mounted? Aborting.\n"
        exit 1
    fi
done < "$INCLUDE_FILE"

printf "[OK] All source mounts verified.\n"

# --- 3. Secure Decryption ---
printf "[INFO] Decrypting configuration...\n"
load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

printf "[INFO] Target Repository: %s\n" "$RESTIC_REPOSITORY"

# --- 4. Repository Check & Auto-Init ---
printf "[INFO] Verifying Repository status...\n"

if ! restic -r "$RESTIC_REPOSITORY" cat config >/dev/null 2>&1; then
    printf "[WARN] Repository does not exist or is inaccessible.\n\n"
    printf "    Would you like to initialize a new repository at:\n"
    printf "    %s\n\n" "$RESTIC_REPOSITORY"
    printf "    Initialize? (y/N): "
    
    read -r CONFIRM
    case "$CONFIRM" in
        [Yy]*)
            printf "[INFO] Initializing new repository...\n"
            restic -r "$RESTIC_REPOSITORY" init
            printf "[OK] Repository initialized.\n"
            ;;
        *)
            printf "[FAIL] Aborting backup.\n"
            exit 1
            ;;
    esac
else
    printf "[OK] Repository found and accessible.\n"
fi

# --- 5. Execution & Anomaly Detection ---
printf "========================================\n"
printf "[INFO] Starting Restic Backup...\n"
printf "========================================\n"

TMP_LOG=$(mktemp)
trap 'rm -f "$TMP_LOG"' EXIT

set +e
restic -r "$RESTIC_REPOSITORY" backup \
    --files-from="$INCLUDE_FILE" \
    --exclude-file="$EXCLUDE_FILE" \
    --exclude-caches \
    --one-file-system \
    --verbose \
    "$@" > "$TMP_LOG" 2>&1
EXIT_CODE=$?
set -e

ADDED_LINE=$(grep "Added to the repository:" "$TMP_LOG" || true)

if printf "%s" "$ADDED_LINE" | grep -qE "GiB|TiB"; then
    printf "========================================\n"
    printf "[ANOMALY] Exceptional data growth detected!\n"
    printf "%s\n" "$ADDED_LINE"
    printf "========================================\n"
    printf "Changes compared to the previous snapshot:\n\n"
    
    "$SCRIPT_DIR/stats.sh" -H "$(hostname)" --diff || true
    
    printf "\n========================================\n"
    printf "Original Restic Log:\n"
    printf "========================================\n\n"
elif [ $EXIT_CODE -ne 0 ]; then
    printf "[FAIL] Backup failed (Exit code: %d)\n\n" "$EXIT_CODE"
else
    printf "[OK] Backup finished successfully. %s\n\n" "${ADDED_LINE:-No changes.}"
fi

cat "$TMP_LOG"
exit $EXIT_CODE
