#!/usr/bin/env sh
set -eu
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

SECRETS="$SCRIPT_DIR/../conf/secrets/restic.env.gpg"
load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

HOST=""
TAG=""
PATH_FILTER=""
JSON=0
GROUP_BY=""

# Parse a few convenience flags; everything else is forwarded.
ARGS=""
while [ $# -gt 0 ]; do
  case "$1" in
    -H|--host)       HOST="$2"; shift 2 ;;
    -T|--tag)        TAG="$2"; shift 2 ;;
    -P|--path)       PATH_FILTER="$2"; shift 2 ;;
    -J|--json)       JSON=1; shift ;;
    --group-by)      GROUP_BY="$2"; shift 2 ;;
    *)               ARGS="$ARGS $(printf '%s' "$1")"; shift ;;
  esac
done

set -- $ARGS

CMD="restic -r \"$RESTIC_REPOSITORY\" snapshots"
[ -n "$HOST" ]       && CMD="$CMD --host \"$HOST\""
[ -n "$TAG" ]        && CMD="$CMD --tag \"$TAG\""
[ -n "$PATH_FILTER" ]&& CMD="$CMD --path \"$PATH_FILTER\""
[ -n "$GROUP_BY" ]   && CMD="$CMD --group-by \"$GROUP_BY\""
[ "$JSON" -eq 1 ]    && CMD="$CMD --json"

# shellcheck disable=SC2086
eval
