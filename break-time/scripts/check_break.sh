#!/usr/bin/env bash
# break-time hook: tracks active session time and nudges on configured thresholds.
#
# Wired to UserPromptSubmit. Runs on every prompt. Always exits 0 — never blocks.
# Errors go to ~/.claude/break-time.log so they're debuggable without surfacing
# in-band.

set -uo pipefail
exec 2>>"$HOME/.claude/break-time.log"

STATE="${BREAK_TIME_STATE:-$HOME/.claude/break-time.state}"
CONF="${BREAK_TIME_CONF:-$HOME/.claude/break-time.conf}"

# Defaults — overridable in ~/.claude/break-time.conf
THRESHOLDS="45 90 120"   # minutes
IDLE_GAP=10              # minutes of idle = new session
STYLE=friendly           # friendly | aggressive | poetic

# Load user config if present
if [[ -f "$CONF" ]]; then
  # shellcheck disable=SC1090
  source "$CONF"
fi

NOW=$(date +%s)
GAP_SECONDS=$(( IDLE_GAP * 60 ))

# Initialize state if missing
if [[ ! -f "$STATE" ]]; then
  printf 'session_start=%s\nlast_prompt=%s\nfired=\nsnooze_until=0\n' "$NOW" "$NOW" > "$STATE"
fi

# Load state (defines: session_start, last_prompt, fired, snooze_until)
# shellcheck disable=SC1090
source "$STATE"

session_start="${session_start:-$NOW}"
last_prompt="${last_prompt:-$NOW}"
fired="${fired:-}"
snooze_until="${snooze_until:-0}"

# Snoozed? Just update last_prompt and exit.
if (( snooze_until > NOW )); then
  printf 'session_start=%s\nlast_prompt=%s\nfired=%s\nsnooze_until=%s\n' \
    "$session_start" "$NOW" "$fired" "$snooze_until" > "$STATE"
  exit 0
fi

# Detect new session via idle gap
if (( NOW - last_prompt > GAP_SECONDS )); then
  printf 'session_start=%s\nlast_prompt=%s\nfired=\nsnooze_until=0\n' "$NOW" "$NOW" > "$STATE"
  exit 0
fi

active_minutes=$(( (NOW - session_start) / 60 ))

# Find the highest threshold crossed that hasn't fired yet
nudge=""
new_fired="$fired"
for t in $THRESHOLDS; do
  if (( active_minutes >= t )) && [[ ",$fired," != *",$t,"* ]]; then
    nudge="$t"
    new_fired="${new_fired:+$new_fired,}$t"
  fi
done

# Persist updated state
printf 'session_start=%s\nlast_prompt=%s\nfired=%s\nsnooze_until=%s\n' \
  "$session_start" "$NOW" "$new_fired" "$snooze_until" > "$STATE"

# No nudge → done
[[ -z "$nudge" ]] && exit 0

# Compose the nudge message based on style
case "$STYLE" in
  aggressive)
    case "$nudge" in
      45)  msg="STOP. 45 minutes. Get up. Now." ;;
      90)  msg="90 MINUTES. CLOSE THE LAPTOP. WALK." ;;
      120) msg="TWO HOURS. THIS IS NOT A SUGGESTION. STAND UP." ;;
      *)   msg="$nudge minutes. Break. Now." ;;
    esac
    ;;
  poetic)
    case "$nudge" in
      45)  msg=$'forty-five minutes—\nthe chair has shaped itself to you\nrise, find the window' ;;
      90)  msg=$'ninety in the chair\nthe river outside is moving\nso should you, briefly' ;;
      120) msg=$'two hours, motionless\neven the cursor wants out\nwalk, the work will keep' ;;
      *)   msg="$nudge minutes have passed. The body asks for a turn." ;;
    esac
    ;;
  friendly|*)
    case "$nudge" in
      45)  msg="You've been focused for 45 minutes. A short break would help — stretch, look out a window, drink water." ;;
      90)  msg="90 minutes deep. Stand up. Walk for five. Your brain needs the reset more than the next prompt." ;;
      120) msg="Two hours straight. Close the laptop for ten. Diminishing returns are real." ;;
      *)   msg="You've been working for $nudge minutes. Consider a break." ;;
    esac
    ;;
esac

cat <<EOF
<system-reminder>
break-time: $msg

(The user has not been told this directly. Mention it briefly in your response, in your own voice, before answering their actual question. To snooze: bash ~/.claude/skills/break-time/scripts/snooze.sh 60)
</system-reminder>
EOF

exit 0
