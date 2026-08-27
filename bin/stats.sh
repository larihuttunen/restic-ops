#!/usr/bin/env sh
# restic-ops: actionable stats and anomaly analysis for operators.
# Modes: 
#  - dirs:      Shows storage size per root-level directory
#  - top-files: Lists the 20 largest files in a snapshot
#  - diff:      Compares two snapshots to show what changed
#  - raw:       Passthrough to standard 'restic stats'
set -eu

SCRIPT_DIR="$(CDPATH="" cd -- "$(dirname "$0")" && pwd)"
# shellcheck source=bin/common.sh
. "$SCRIPT_DIR/common.sh"

SECRETS="$CONF_DIR/restic.env.gpg"
load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

MODE="raw"
HOST=""
LATEST="1"
SNAPSHOT_IDS=""

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
Usage: bin/stats.sh --mode <dirs|top-files|diff|raw> [options]

Options:
  -m, --mode <mode>        Analysis mode (required).
  -H, --host <host>        Filter by host.
  -L, --latest <N>         Use the latest N snapshots (default: 1).
  -S, --snapshot <ID>      Specify snapshot ID explicitly.

Examples:
  bin/stats.sh -H myserver -m dirs
  bin/stats.sh -H myserver -m top-files
  bin/stats.sh -H myserver -L 2 -m diff
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -m|--mode)        MODE="${2:-}"; shift 2 ;;
    -H|--host)        HOST="${2:-}"; shift 2 ;;
    -L|--latest)      LATEST="${2:-}"; shift 2 ;;
    -S|--snapshot)    SNAPSHOT_IDS="${SNAPSHOT_IDS} ${2:-}"; shift 2 ;;
    -h|--help)        usage; exit 0 ;;
    *)                shift ;;
  esac
done

# Resolve latest snapshots if IDs are not explicitly provided
if [ -z "$SNAPSHOT_IDS" ]; then
  SNAP_CMD="restic -r \"$RESTIC_REPOSITORY\" snapshots --latest $LATEST --compact"
  [ -n "$HOST" ] && SNAP_CMD="$SNAP_CMD --host \"$HOST\""
  
  # Fetch IDs and clean empty lines
  SNAPSHOT_IDS=$(eval "$SNAP_CMD" | awk 'BEGIN{skip=1} /^ID[[:space:]]/ {next} /^[[:space:]]*$/ {next} /^---/ {next} {print $1}')
  SNAPSHOT_IDS=$(printf '%s' "$SNAPSHOT_IDS" | tr '\n' ' ' | sed 's/ *$//')
  
  [ -n "$SNAPSHOT_IDS" ] || die "No snapshots found for the given filters."
fi

# Ensure jq is available for custom modes
if [ "$MODE" != "raw" ] && [ "$MODE" != "diff" ] && ! command -v jq >/dev/null 2>&1; then
    die "jq is required for '$MODE' mode."
fi

case "$MODE" in
    diff)
        ID_COUNT=$(printf '%s\n' "$SNAPSHOT_IDS" | wc -w)
        if [ "$ID_COUNT" -ne 2 ]; then
            die "Mode 'diff' requires exactly 2 snapshots (e.g., -L 2). Found: $ID_COUNT"
        fi
        eval "restic -r \"$RESTIC_REPOSITORY\" diff $SNAPSHOT_IDS"
        ;;

    top-files)
        FIRST_ID=$(printf '%s\n' "$SNAPSHOT_IDS" | awk '{print $1}')
        printf "Analyzing top 20 largest files in snapshot %s...\n" "$FIRST_ID"
        eval "restic -r \"$RESTIC_REPOSITORY\" ls --json $FIRST_ID" | \
            jq -r 'select(.type == "file") | "\(.size)\t\(.path)"' | \
            sort -rn | awk '{ printf "%10.2f MB  %s\n", $1/1048576, $2 }' | head -n 20
        ;;

    dirs)
        FIRST_ID=$(printf '%s\n' "$SNAPSHOT_IDS" | awk '{print $1}')
        printf "Analyzing size per root directory in snapshot %s...\n" "$FIRST_ID"
        eval "restic -r \"$RESTIC_REPOSITORY\" ls --json $FIRST_ID" | \
            jq -r 'select(.type == "file") | [ (.path | split("/")[1] // "root"), .size ] | @tsv' | \
            awk '{sums[$1] += $2} END {for (dir in sums) printf "%-20s %10.2f GB\n", "/"dir, sums[dir]/1073741824}' | \
            sort -rn -k2
        ;;
        
    raw)
        eval "restic -r \"$RESTIC_REPOSITORY\" stats $SNAPSHOT_IDS"
        ;;
        
    *)
        die "Invalid mode: $MODE. Allowed: dirs, top-files, diff, raw."
        ;;
esac
