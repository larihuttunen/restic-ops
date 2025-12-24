#!/bin/bash

# ==============================================================================
# MANUAL BACKUP SCRIPT - EXTERNAL DISK
# Configuration: /etc/restic-ops/restic.env.external-disk.gpg (Symmetric)
# Sources:       /etc/restic-ops/include-external.txt
# Excludes:      /etc/restic-ops/exclude-external.txt
# Features:      Auto-init, Canary Checks, Symmetric Encryption
# ==============================================================================

set -e  # Exit on error
set -u  # Exit on unset variables
set -o pipefail

# --- 1. Configuration & Constants ---
CONFIG_FILE="/etc/restic-ops/restic.env.external-disk.gpg"
INCLUDE_FILE="/etc/restic-ops/include-external.txt"
EXCLUDE_FILE="/etc/restic-ops/exclude-external.txt"
CANARY_NAME=".restic.marker"

# Essential for manual runs (GPG Pinentry)
export GPG_TTY=$(tty)

echo "========================================"
echo "🛡️  Manual Host Backup: External Disk"
echo "========================================"

# --- 2. Validation of Control Files ---
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Error: Config file missing: $CONFIG_FILE"
    exit 1
fi
if [[ ! -f "$INCLUDE_FILE" ]]; then
    echo "❌ Error: Include file missing: $INCLUDE_FILE"
    exit 1
fi

# --- 3. Canary Check (Source Safety) ---
echo "🔍 Checking source mount points (Canaries)..."

while IFS= read -r dir || [ -n "$dir" ]; do
    [[ "$dir" =~ ^#.*$ ]] || [[ -z "$dir" ]] && continue

    CANARY_PATH="${dir%/}/$CANARY_NAME"
    if [[ ! -f "$CANARY_PATH" ]]; then
        echo "   ❌ CRITICAL: Canary missing in: $dir"
        echo "      Is the source disk mounted? Aborting."
        exit 1
    fi
done < "$INCLUDE_FILE"

echo "✅ All source mounts verified."

# --- 4. Secure Decryption ---
echo "🔐 Decrypting configuration..."
source <(gpg --decrypt --quiet "$CONFIG_FILE")

if [[ -z "${RESTIC_REPOSITORY:-}" ]]; then
    echo "❌ Error: RESTIC_REPOSITORY not found in config."
    exit 1
fi

echo "📂 Target Repository: $RESTIC_REPOSITORY"

# --- 5. Repository Check & Auto-Init ---
echo "🔍 Verifying Repository status..."

# Try to read the repo config. If this fails, the repo likely doesn't exist.
if ! restic cat config >/dev/null 2>&1; then
    echo "⚠️  Repository does not exist or is inaccessible."
    echo ""
    echo "    Would you like to initialize a new repository at:"
    echo "    $RESTIC_REPOSITORY"
    echo ""
    read -p "    Initialize? (y/N): " -r CONFIRM
    
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "🔨 Initializing new repository..."
        restic init
        echo "✅ Repository initialized."
    else
        echo "❌ Aborting backup."
        exit 1
    fi
else
    echo "✅ Repository found and accessible."
fi

# --- 6. Execution ---
echo "🚀 Starting Restic Backup..."
echo "----------------------------------------"

restic backup \
    --files-from="$INCLUDE_FILE" \
    --exclude-file="$EXCLUDE_FILE" \
    --verbose

echo "----------------------------------------"
echo "✅ Backup process finished."
