#!/usr/bin/env sh
# restic-ops common helpers
# - Prefer site config under /etc/restic-ops (upgrade-safe)
# - Fall back to repo samples for first install
# - Decrypt GPG secrets via gpg-agent (no plaintext on disk)
# - Optional LOOPBACK=1 to force --pinentry-mode loopback (maintenance only)

set -eu

###############################################################################
# Logging
###############################################################################
log() { printf '%s %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"; }

###############################################################################
# Locate script & configuration
###############################################################################
# Absolute dir of the current script (bin/)
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"

# Site-wide config directory (persistent, never overwritten by upgrades)
CONF_DIR_DEFAULT="/etc/restic-ops"

# Allow override with environment (useful for testing)
CONF_DIR="${CONF_DIR:-$CONF_DIR_DEFAULT}"

# If include/exclude not present in /etc/restic-ops, fall back to repo's conf/
if [ ! -f "$CONF_DIR/include.txt" ] || [ ! -f "$CONF_DIR/exclude.txt" ]; then
  # repo conf contains *samples* only; good for first run/new hosts
  CONF_DIR="$SCRIPT_DIR/../conf"
fi

# Canonicalized config paths
INCLUDE_FILE="$CONF_DIR/include.txt"
EXCLUDE_FILE="$CONF_DIR/exclude.txt"

# Secrets path: for site config we expect /etc/restic-ops/restic.env.gpg
# If falling back to repo conf, we also allow conf/secrets/restic.env.gpg for legacy layouts.
if [ -f "$CONF_DIR/restic.env.gpg" ]; then
  SECRETS="$CONF_DIR/restic.env.gpg"
elif [ -f "$CONF_DIR/secrets/restic.env.gpg" ]; then
  SECRETS="$CONF_DIR/secrets/restic.env.gpg"
else
  # Last resort: allow explicit override via SECRETS env
  SECRETS="${SECRETS:-$CONF_DIR/restic.env.gpg}"
fi

###############################################################################
# Sanity checks (be helpful but strict)
###############################################################################
[ -f "$SECRETS" ] || {
  log "ERROR: secrets file not found: $SECRETS"
  log "Hint: place encrypted secrets at /etc/restic-ops/restic.env.gpg"
  exit 1
}

# include/exclude are optional for some workflows, but warn if missing
[ -f "$INCLUDE_FILE" ] || log "WARN: include file not found: $INCLUDE_FILE"
[ -f "$EXCLUDE_FILE" ] || log "WARN: exclude file not found: $EXCLUDE_FILE"

###############################################################################
# Secrets loader (GPG)
###############################################################################
# Default flow uses the interactive gpg-agent cache (no plaintext on disk).
# Break-glass maintenance: export LOOPBACK=1 to force loopback pinentry.
load_secrets() {
  CRED_FILE="$1"
  [ -f "$CRED_FILE" ] || { log "ERROR: secrets file not found: $CRED_FILE"; exit 1; }

  if command -v gpg >/dev/null 2>&1; then
    if [ "${LOOPBACK:-0}" = "1" ]; then
      # No TTY required; still no plaintext file stored
      eval "$(gpg --batch --quiet --pinentry-mode loopback --decrypt "$CRED_FILE")"
    else
      # Interactive-agent path: relies on gpg-agent cache if running headless
      eval "$(gpg --batch --quiet --decrypt "$CRED_FILE")"
    fi
  else
    log "ERROR: gpg not available"; exit 1
  fi
}

###############################################################################
# Env requirement checker
###############################################################################
require_env() {
  MISSING=0
  for v in "$@"; do
    # shellcheck disable=SC3028 # BusyBox/ash-friendly indirect test
    if [ -z "${!v:-}" ]; then
      log "ERROR: missing env: $v"
      MISSING=1
    fi
  done
  [ "$MISSING" -eq 0 ] || exit 1
}

###############################################################################
# Export a few paths for downstream scripts
###############################################################################
export INCLUDE_FILE EXCLUDE_FILE SECRE
