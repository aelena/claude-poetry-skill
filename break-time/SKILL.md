---
name: break-time
description: Track wall-clock time across a Claude Code session and nudge the user to take a break at configurable intervals (default 45/90/120 minutes). Uses a UserPromptSubmit hook to inject break reminders into the next response. Includes commands to snooze and reset the timer. Use when the user asks to set up break reminders, work-rest cycles, time-aware nudges, or invokes /break, /break-time, /snooze, /pomodoro-ish.
---

# break-time

An ambient skill that nudges you to take a break when you've been heads-down too long. Claude itself can't track wall-clock time across responses — it only sees the conversation. **Hooks** run *outside* Claude in the harness and can inject context Claude wouldn't otherwise have. That's how this works.

If you've never written a hook, read `HOOKS-101.md` first. It's a standalone tutorial — copy-paste-friendly, ~15 minutes to read, and it's the foundation for *any* ambient skill you might want to build later.

## What it does

- Tracks the start of the current "active session" (resets after 10 minutes of idle).
- On every prompt you submit, computes how long you've been actively working.
- When you cross a configurable threshold (default 45, 90, 120 minutes), injects a one-shot nudge into Claude's context. Claude will mention it briefly in its next response, in its own voice, before answering your question.
- You can snooze it (`/snooze 60`) or reset it (`/break-reset`).
- Each threshold fires only once per active session — no spam.

## Invocation

The skill is two things: a **passive hook** (runs automatically once installed) and a few **active commands** for managing it.

| Trigger | Behavior |
|---|---|
| *(automatic)* | The hook fires on every prompt. No invocation needed once installed. |
| `/break` or `/break-time` | Show current state: how long the active session has been running, when the next threshold fires, snooze status. |
| `/snooze [N]` | Snooze nudges for N minutes (default 60). |
| `/break-reset` | Reset the active session timer (treat *now* as session start). |
| `/break-time configure` | Walk the user through editing thresholds in `~/.claude/break-time.conf`. |
| Natural language: "snooze break-time", "I'm taking a break now", "stop the timer" | Same |

### Disable
Remove the hook block from `~/.claude/settings.json`. The skill files can stay; without the hook wired up, they're inert.

## Installation

1. Copy `break-time/` to `~/.claude/skills/break-time/`.
2. Add the hook block from `example-settings.json` to your `~/.claude/settings.json` (the file already exists; merge, don't overwrite).
3. Restart Claude Code so the harness picks up the new hook.
4. That's it. The hook runs on every prompt from now on.

Full beginner walkthrough is in `HOOKS-101.md`.

## How the hook works (mechanically)

1. You submit a prompt.
2. The harness calls `bash ~/.claude/skills/break-time/scripts/check_break.sh` *before* Claude sees the prompt.
3. The hook reads `~/.claude/break-time.state` (a flat key-value file), computes elapsed time, and decides if any threshold has been crossed.
4. If a threshold fires, the hook prints a `<system-reminder>` block to stdout. The harness captures stdout and adds it as additional context for Claude's next turn.
5. Claude sees the reminder and weaves it into its response: *"By the way, you've been heads-down for 90 minutes — stand up and walk for five before we keep going. Now, about your question..."*
6. Each fired threshold is recorded in the state file so it doesn't fire again until the active session resets.

## Configuration

State and config live in `~/.claude/`:
- `break-time.state` — runtime state (session_start, fired thresholds, snooze)
- `break-time.conf` — optional user config (thresholds, idle gap, message style)

If `break-time.conf` is missing, defaults are used:

```bash
THRESHOLDS="45 90 120"   # minutes — when to nudge
IDLE_GAP=10              # minutes of idle = new session
STYLE=friendly           # friendly | aggressive | poetic
```

`STYLE=poetic` makes the nudge a haiku (cross-skill love letter to `poet-commit`).

## Safety guardrails

- **Never blocks a prompt.** The hook always exits 0 — if it fails, the user's work is unaffected.
- **Always logs to a file** (`~/.claude/break-time.log`) so debugging is possible without surfacing errors in-band.
- **Capped output.** The nudge is one short paragraph. Never floods the context window.
- **Snooze respected always.** If the user has snoozed, the hook still tracks time but emits nothing.
- **No network calls.** Pure local file I/O. Never delays the prompt.

## Files in this skill

- `SKILL.md` — this file
- `HOOKS-101.md` — **standalone tutorial on writing hooks** (publishable)
- `example-settings.json` — copy-paste hook config for `~/.claude/settings.json`
- `scripts/check_break.sh` — the hook itself
- `scripts/snooze.sh` — snooze nudges for N minutes
- `scripts/reset.sh` — reset the active session timer
- `scripts/state.sh` — print current state (used by `/break`)
- `README.md` — short install instructions
