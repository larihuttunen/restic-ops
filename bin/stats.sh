#!/usr/bin/env sh
# restic-ops: stats wrapper with useful flags for operators.
# Features:
#  - --mode restore-size|raw-data|blobs-per-file|total-bytes
#  - Filters: --host, --tag, --path, --since, --until
#  - Select snapshots via --snapshot <ID> (repeatable) or --latest [N]
#  - --json passthrough
#  - --summary: pretty summary if jq is available (optional)
#  - Safe defaults, strict error handling
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

SECRETS="$CONF_DIR/restic.env.gpg"
load_secrets "$SECRETS"
require_env RESTIC_REPOSITORY RESTIC_PASSWORD

# ---------- defaults & helpers ----------

MODE=""            # restic stats --mode
JSON=0             # output JSON if 1
SUMMARY=0          # pretty summary (requires jq)
HOST=""
TAG=""
PATH_FILTER=""
SINCE=""
UNTIL=""
LATEST=""          # integer (default 1 if just -L/--latest is given)
SNAPSHOT_IDS=""    # space-separated list

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
Usage: bin/stats.sh [options] [-- restic-stats-extra-args...]

Modes:
  -m, --mode <mode>        One of: restore-size | raw-data | blobs-per-file | total-bytes

Filters (passed to `restic`):
  -H, --host <host>
  -T, --tag <tag>
  -P, --path <path>
      --since <date|duration>   e.g. 2025-01-01 or 30d
      --until <date|duration>

Snapshot selection:
  -S, --snapshot <ID>      (repeatable)
  -L, --latest [N]         Resolve latest N snapshot IDs matching filters (default N=1)

Output:
  -J, --json               Emit restic JSON directly
      --summary           If jq is present, print a human summary (works best with --json)

Other:
  -h, --help               Show this help

Examples:
  bin/stats.sh --mode restore-size
  bin/stats.sh -H host1 -T critical --since 30d --mode raw-data
  bin/stats.sh --latest       # stats for very latest snapshot (any host)
  bin/stats.sh -H host2 --latest 3 --mode restore-size
  bin/stats.sh --snapshot 1234abcd --snapshot deadbeef --json --summary
USAGE
}

# ---------- parse args ----------
EXTRA=""
while [ $# -gt 0 ]; do
  case "$1" in
    -m|--mode)        MODE="${2:-}"; shift 2 ;;
    -J|--json)        JSON=1; shift ;;
    --summary)        SUMMARY=1; shift ;;
    -H|--host)        HOST="${2:-}"; shift 2 ;;
    -T|--tag)         TAG="${2:-}"; shift 2 ;;
    -P|--path)        PATH_FILTER="${2:-}"; shift 2 ;;
    --since)          SINCE="${2:-}"; shift 2 ;;
    --until)          UNTIL="${2:-}"; shift 2 ;;
    -S|--snapshot)    SNAPSHOT_IDS="${SNAPSHOT_IDS} ${2:-}"; shift 2 ;;
    -L|--latest)
      # Optional numeric argument for --latest. If next token looks like a number, take it.
      if [ $# -ge 2 ] && printf '%s' "$2" | grep -Eq '^[0-9]+$'; then
        LATEST="$2"; shift 2
      else
        LATEST="1"; shift
      fi
      ;;
    -h|--help) usage; exit 0 ;;
    --) shift; EXTRA="$*"; break ;;
    *)  EXTRA="$EXTRA $(printf '%s' "$1")"; shift ;;
  esac
done

# Trim leading spaces
SNAPSHOT_IDS="$(printf '%s' "$SNAPSHOT_IDS" | sed 's/^ *//')"
EXTRA="$(printf '%s' "$EXTRA" | sed 's/^ *//')"

# Validate mode (if provided)
if [ -n "$MODE" ]; then
  case "$MODE" in
    restore-size|raw-data|blobs-per-file|total-bytes) : ;;
    *) die "Invalid --mode '$MODE'. Allowed: restore-size|raw-data|blobs-per-file|total-bytes" ;;
  esac
fi

# ---------- resolve --latest into --snapshot IDs if requested ----------
resolve_latest_ids() {
  # Build a snapshots query with same filters to keep results consistent
  # Prefer JSON+jq if available (more reliable). Fallback to column parsing.
  LATEST_N="$1"

  SNAP_CMD="restic -r \"$RESTIC_REPOSITORY\" snapshots --latest $LATEST_N"
  [ -n "$HOST" ]        && SNAP_CMD="$SNAP_CMD --host \"$HOST\""
  [ -n "$TAG" ]         && SNAP_CMD="$SNAP_CMD --tag \"$TAG\""
  [ -n "$PATH_FILTER" ] && SNAP_CMD="$SNAP_CMD --path \"$PATH_FILTER\""
  [ -n "$SINCE" ]       && SNAP_CMD="$SNAP_CMD --since \"$SINCE\""
  [ -n "$UNTIL" ]       && SNAP_CMD="$SNAP_CMD --until \"$UNTIL\""

  if command -v jq >/dev/null 2>&1; then
    SNAP_CMD="$SNAP_CMD --json"
    # shellcheck disable=SC2086
    IDS="$(eval "$SNAP_CMD" | jq -r '.[].short_id' 2>/dev/null || true)"
  else
    # Fallback: parse the "restic snapshots" table; ID is first column after header separator.
    # We use --compact to make parsing more stable.
    SNAP_CMD="$SNAP_CMD --compact"
    # shellcheck disable=SC2086
    IDS="$(eval "$SNAP_CMD" \
        | awk 'BEGIN{skip=1} /^ID[[:space:]]/ {next} /^[[:space:]]*$/ {next} /^---/ {next} {print $1}' )"
  fi

  IDS="$(printf '%s\n' "$IDS" | sed '/^$/d' | tr '\n' ' ')"
  [ -n "$IDS" ] || die "No snapshots found for --latest $LATEST_N with the given filters"
  printf '%s\n' "$IDS"
}

if [ -n "$LATEST" ]; then
  RESOLVED="$(resolve_latest_ids "$LATEST")"
  SNAPSHOT_IDS="$(printf '%s %s' "$SNAPSHOT_IDS" "$RESOLVED" | sed 's/^ *//')"
fi

# ---------- build the restic stats command ----------
CMD="restic -r \"$RESTIC_REPOSITORY\" stats"

[ -n "$MODE" ]        && CMD="$CMD --mode \"$MODE\""
[ -n "$HOST" ]        && CMD="$CMD --host \"$HOST\""
[ -n "$TAG" ]         && CMD="$CMD --tag \"$TAG\""
[ -n "$PATH_FILTER" ] && CMD="$CMD --path \"$PATH_FILTER\""
[ -n "$SINCE" ]       && CMD="$CMD --since \"$SINCE\""
[ -n "$UNTIL" ]       && CMD="$CMD --until \"$UNTIL\""

# Attach snapshots (may be multiple)
if [ -n "$SNAPSHOT_IDS" ]; then
  for sid in $SNAPSHOT_IDS; do
    CMD="$CMD --snapshot \"$sid\""
  done
fi

[ $JSON -eq 1 ] && CMD="$CMD --json"

# Include any extra args the operator wants to pass straight through
[ -n "$EXTRA" ] && CMD="$CMD $EXTRA"

# ---------- run ----------
# shellcheck disable=SC2086
OUTPUT="$(eval "$CMD")" || {
  printf '%s\n' "$OUTPUT" >&2 || true
  die "restic stats command failed"
}

# Print raw or JSON output first
printf '%s\n' "$OUTPUT"

# Optionally, add a summary if jq exists and user requested --summary
if [ $SUMMARY -eq 1 ] && command -v jq >/dev/null 2>&1; then
  # Try to summarize bytes/num_files when JSON mode is on; otherwise attempt a heuristic.
  if [ $JSON -eq 1 ]; then
    # Newer restic returns objects with "total_size" and "total_file_count" depending on mode.
    BYTES="$(printf '%s\n' "$OUTPUT" | jq -r '..|.total_size? // empty' | head -n1)"
    FILES="$(printf '%s\n' "$OUTPUT" | jq -r '..|.total_file_count? // empty' | head -n1)"
    [ -n "${BYTES:-}" ] || BYTES=0
    [ -n "${FILES:-}" ] || FILES=0

    hr_bytes() {  # human-readable bytes
      num="$1"; awk -v n="$num" 'function human(x){ s="B KB MB GB TB PB"; split(s,a," "); i=1; while (x>=1024 && i<6){x/=1024; i++} printf "%.2f %s", x, a[i]; } BEGIN{ human(n) }'
    }
    printf '\nSummary: %s across %s files\n' "$(hr_bytes "$BYTES")" "$FILES"
  else
    # Heuristic: try to pull numbers from the text output (not guaranteed across restic versions).
    printf '\n(For a reliable summary, add --json --summary when jq is installed.)\n'
  fi
fi
