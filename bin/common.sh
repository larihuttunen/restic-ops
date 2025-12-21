#!/usr/bin/env sh
# restic-ops common helpers
set -eu

###############################################################################
# Logging
###############################################################################
log() { printf '%s %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"; }

###############################################################################
# Locate script & configuration
###############################################################################
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
CONF_DIR_DEFAULT="/etc/restic-ops"
CONF_DIR="${CONF_DIR:-$CONF_DIR_DEFAULT}"

if [ ! -f "$CONF_DIR/include.txt" ] || [ ! -f "$CONF_DIR/exclude.txt" ]; then
  CONF_DIR="$SCRIPT_DIR/../conf"
fi

INCLUDE_FILE="$CONF_DIR/include.txt"
EXCLUDE_FILE="$CONF_DIR/exclude.txt"

if [ -f "$CONF_DIR/restic.env.gpg" ]; then
  SECRETS="$CONF_DIR/restic.env.gpg"
elif [ -f "$CONF_DIR/secrets/restic.env.gpg" ]; then
  SECRETS="$CONF_DIR/secrets/restic.env.gpg"
else
  SECRETS="${SECRETS:-$CONF_DIR/restic.env.gpg}"
fi

###############################################################################
# Sanity checks
###############################################################################
[ -f "$SECRETS" ] || {
  log "ERROR: secrets file not found: $SECRETS"
  exit 1
}

###############################################################################
# Secrets loader (GPG)
###############################################################################
load_secrets() {
  CRED_FILE="$1"
  if command -v gpg >/dev/null 2>&1; then
    if [ "${LOOPBACK:-0}" = "1" ]; then
      eval "$(gpg --batch --quiet --pinentry-mode loopback --decrypt "$CRED_FILE")"
    else
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
    val=$(eval "echo \"\${$v:-}\"")
    if [ -z "$val" ]; then
      log "ERROR: missing env: $v"
      MISSING=1
    fi
  done
  [ "$MISSING" -eq 0 ] || exit 1
}

export INCLUDE_FILE EXCLUDE_FILE SECRETS
