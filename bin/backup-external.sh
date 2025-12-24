#!/bin/bash

# ==============================================================================
# MANUAL BACKUP SCRIPT - EXTERNAL DISK
# Configuration: /etc/restic-ops/restic.env.external-disk.gpg (Symmetric)
# Sources:       /etc/restic-ops/include-external.txt
# Excludes:      /etc/restic-ops/exclude-external.txt
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
echo "🛡️  Safe Backup: External Mount Check"
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

# --- 3. Canary Check (The Safety Logic) ---
echo "🔍 Checking mount points (Canaries)..."

# Verify every path in the include file contains the marker
while IFS= read -r dir || [ -n "$dir" ]; do
    # Skip comments and empty lines
    [[ "$dir" =~ ^#.*$ ]] || [[ -z "$dir" ]] && continue

    CANARY_PATH="${dir%/}/$CANARY_NAME"

    if [[ -f "$CANARY_PATH" ]]; then
        echo "   ✅ Found canary in: $dir"
    else
        echo "   ❌ CRITICAL: Canary missing in: $dir"
        echo "      Expected file: $CANARY_PATH"
        echo "      Is the disk mounted? Aborting backup."
        exit 1
    fi
done < "$INCLUDE_FILE"

echo "✅ All source mounts verified."

# --- 4. Secure Decryption & Sourcing ---
echo "🔐 Decrypting configuration..."

# Decrypt variables directly into memory.
# Since this uses symmetric encryption, GPG will prompt for the file passphrase.
source <(gpg --decrypt --quiet "$CONFIG_FILE")

# Verify Repo Variable
if [[ -z "${RESTIC_REPOSITORY:-}" ]]; then
    echo "❌ Error: RESTIC_REPOSITORY not found in encrypted config."
    exit 1
fi

echo "📂 Target Repository: $RESTIC_REPOSITORY"

# --- 5. Execution ---
echo "🚀 Starting Restic Backup..."
echo "----------------------------------------"

# Run backup using the verified include list and exclusions
restic backup \
    --files-from="$INCLUDE_FILE" \
    --exclude-file="$EXCLUDE_FILE" \
    --verbose

echo "----------------------------------------"
echo "✅ Backup process finished."
