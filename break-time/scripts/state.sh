#!/usr/bin/env bash
# break-time: print current state in human-readable form.
# Used by /break to show how long the active session has been running.

set -uo pipefail

STATE="${BREAK_TIME_STATE:-$HOME/.claude/break-time.state}"
CONF="${BREAK_TIME_CONF:-$HOME/.claude/break-time.conf}"

THRESHOLDS="45 90 120"
[[ -f "$CONF" ]] && source "$CONF"

if [[ ! -f "$STATE" ]]; then
  echo "break-time: no state yet (hook hasn't run, or state was reset)"
  exit 0
fi

# shellcheck disable=SC1090
source "$STATE"
NOW=$(date +%s)

active_minutes=$(( (NOW - ${session_start:-$NOW}) / 60 ))
since_last_prompt=$(( (NOW - ${last_prompt:-$NOW}) / 60 ))

echo "break-time state:"
echo "  active session: ${active_minutes} min"
echo "  since last prompt: ${since_last_prompt} min"
echo "  thresholds fired: ${fired:-none}"

if (( ${snooze_until:-0} > NOW )); then
  remaining=$(( (snooze_until - NOW) / 60 ))
  echo "  snoozed: yes (${remaining} min remaining)"
else
  echo "  snoozed: no"
fi

# Find next threshold
next=""
for t in $THRESHOLDS; do
  if (( active_minutes < t )) && [[ ",${fired:-}," != *",$t,"* ]]; then
    next="$t"
    break
  fi
done

if [[ -n "$next" ]]; then
  remaining=$(( next - active_minutes ))
  echo "  next nudge: at ${next} min (in ${remaining} min)"
else
  echo "  next nudge: none scheduled this session"
fi
