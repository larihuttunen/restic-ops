#!/usr/bin/env sh
set -eu

log() { printf '%s %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"; }

load_secrets() {
  CRED_FILE="$1"
  [ -f "$CRED_FILE" ] || { log "ERROR: secrets file not found: $CRED_FILE"; exit 1; }
  if command -v gpg >/dev/null 2>&1; then
    eval "$(gpg --batch --quiet --decrypt "$CRED_FILE")"
  else
    log "ERROR: gpg not available"; exit 1
  fi
}

require_env() {
  MISSING=0
  for v in "$@"; do
    if [ -z "${!v:-}" ]; then log "ERROR: missing env: $v"; MISSING=1; fi
  done
  [ "$MISSING" -eq 0 ] || exit 1
}
