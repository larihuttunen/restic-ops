#!/usr/bin/env sh
# restic-ops: actionable stats and anomaly analysis for operators.
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

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -m|--mode)        MODE="${2:-}"; shift 2 ;;
    --dirs)           MODE="dirs"; shift ;;
    --diff)           MODE="diff"; shift ;;
    --top-files)      MODE="top-files"; shift ;;
    -H|--host)        HOST="${2:-}"; shift 2 ;;
    -L|--latest)      LATEST="${2:-}"; shift 2 ;;
    -S|--snapshot)    SNAPSHOT_IDS="${SNAPSHOT_IDS} ${2:-}"; shift 2 ;;
    -h|--help)
      printf "Usage: stats.sh [-H host] [--diff | --dirs | --top-files | -m raw] [-L N] [snapshot_ids...]\n"
      exit 0 
      ;;
    -*)               die "Unknown option: $1" ;;
    *)                
      # Capture bare positional arguments as snapshot IDs
      SNAPSHOT_IDS="${SNAPSHOT_IDS} $1"
      shift 
      ;;
  esac
done

# Smart default for anomaly detection:
# If backup.sh triggers '--diff' without specifying '-L 2', auto-correct it.
if [ "$MODE" = "diff" ] && [ "$LATEST" = "1" ] && [ -z "$SNAPSHOT_IDS" ]; then
  LATEST="2"
fi

# Fetch IDs if not provided manually
if [ -z "$SNAPSHOT_IDS" ]; then
  SNAP_CMD="restic -r \"$RESTIC_REPOSITORY\" snapshots --latest $LATEST --compact"
  [ -n "$HOST" ] && SNAP_CMD="$SNAP_CMD --host \"$HOST\""
  
  # Strict regex matching: fetch ONLY the 8-character hex IDs.
  FETCHED_IDS=$(eval "$SNAP_CMD" | awk '/^[0-9a-f]{8}[[:space:]]/ {print $1}')
  
  # If diffing, we must have exactly 2. Restic grouping might return more.
  # Safely grab the last 2 chronologically.
  if [ "$MODE" = "diff" ]; then
    FETCHED_IDS=$(printf '%s\n' "$FETCHED_IDS" | tail -n 2)
  fi
  
  SNAPSHOT_IDS=$(printf '%s' "$FETCHED_IDS" | tr '\n' ' ' | sed 's/ *$//')
  
  [ -n "$SNAPSHOT_IDS" ] || die "No snapshots found for the given filters."
fi

# Ensure jq is installed (only required for JSON-based analytic modes, not diff/raw)
if [ "$MODE" != "raw" ] && [ "$MODE" != "diff" ] && ! command -v jq >/dev/null 2>&1; then
    die "jq is required for '$MODE' mode."
fi

# Route to the correct operation mode
case "$MODE" in
    diff)
        ID_COUNT=$(printf '%s\n' "$SNAPSHOT_IDS" | wc -w)
        if [ "$ID_COUNT" -ne 2 ]; then
            die "Mode 'diff' requires exactly 2 snapshots (e.g., -L 2). Found: $ID_COUNT ($SNAPSHOT_IDS)"
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
        die "Invalid mode: $MODE. Allowed: --dirs, --top-files, --diff, or -m raw."
        ;;
esac
