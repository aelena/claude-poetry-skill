#!/usr/bin/env bash
# break-time: snooze nudges for N minutes (default 60).
# Usage: snooze.sh [minutes]

set -uo pipefail

MINUTES="${1:-60}"
if ! [[ "$MINUTES" =~ ^[0-9]+$ ]]; then
  echo "snooze: invalid minutes value: $MINUTES" >&2
  exit 2
fi

STATE="${BREAK_TIME_STATE:-$HOME/.claude/break-time.state}"
NOW=$(date +%s)
UNTIL=$(( NOW + MINUTES * 60 ))

# Initialize state if missing
if [[ ! -f "$STATE" ]]; then
  printf 'session_start=%s\nlast_prompt=%s\nfired=\nsnooze_until=%s\n' "$NOW" "$NOW" "$UNTIL" > "$STATE"
else
  if grep -q '^snooze_until=' "$STATE"; then
    sed -i.bak "s/^snooze_until=.*/snooze_until=$UNTIL/" "$STATE" && rm -f "$STATE.bak"
  else
    echo "snooze_until=$UNTIL" >> "$STATE"
  fi
fi

# Human-readable until
if date -d "@$UNTIL" '+%H:%M' >/dev/null 2>&1; then
  HUMAN="$(date -d "@$UNTIL" '+%H:%M')"
else
  HUMAN="$(date -r "$UNTIL" '+%H:%M' 2>/dev/null || echo "+${MINUTES}m")"
fi

echo "break-time: snoozed for $MINUTES minutes (until $HUMAN)"
