#!/usr/bin/env sh
# restic-ops: prime-gpg.sh
# Used to interactively cache the GPG passphrase for headless operations.
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

# Ensure GNUPGHOME is set correctly for root operations
export GNUPGHOME="${GNUPGHOME:-/root/.gnupg}"

log "Priming GPG agent cache for secrets: $SECRETS"

# Attempt a decryption to trigger the passphrase prompt
# This will cache the passphrase in the gpg-agent according to your TTL settings.
if gpg --batch --quiet --decrypt "$SECRETS" > /dev/null 2>&1; then
    log "SUCCESS: GPG agent is already primed."
else
    log "Action Required: Please enter the passphrase to prime the agent."
    # Running without --batch to allow interactive pinentry
    if gpg --decrypt "$SECRETS" > /dev/null; then
        log "SUCCESS: GPG agent has been primed for the configured TTL."
    else
        log "ERROR: Failed to prime GPG agent."
        exit 1
    fi
fi
