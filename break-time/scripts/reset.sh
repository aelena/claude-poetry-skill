#!/usr/bin/env bash
# break-time: reset the active session timer (treat now as session start).
# Clears all fired thresholds and any active snooze.

set -uo pipefail

STATE="${BREAK_TIME_STATE:-$HOME/.claude/break-time.state}"
NOW=$(date +%s)

printf 'session_start=%s\nlast_prompt=%s\nfired=\nsnooze_until=0\n' "$NOW" "$NOW" > "$STATE"
echo "break-time: session timer reset"
