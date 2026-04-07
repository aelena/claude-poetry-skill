# break-time

An ambient Claude Code skill that nudges you to take a break when you've been heads-down too long. Runs as a `UserPromptSubmit` hook — Claude itself can't track wall-clock time across responses, but a hook can.

## Quick install

1. Copy this folder to `~/.claude/skills/break-time/`:
   ```bash
   cp -r break-time ~/.claude/skills/break-time
   ```

2. Wire up the hook in `~/.claude/settings.json`. Merge this into the existing file (don't overwrite):
   ```json
   {
     "hooks": {
       "UserPromptSubmit": [
         {
           "matcher": "*",
           "hooks": [
             {
               "type": "command",
               "command": "bash ~/.claude/skills/break-time/scripts/check_break.sh"
             }
           ]
         }
       ]
     }
   }
   ```

3. Restart Claude Code so the harness picks up the new hook.

4. Done. Defaults: nudges at 45, 90, 120 minutes of active work. Idle for 10+ minutes resets the session.

## Configure

Optional `~/.claude/break-time.conf`:

```bash
THRESHOLDS="30 60 90"   # minutes — when to nudge
IDLE_GAP=15             # minutes of idle = new session
STYLE=poetic            # friendly | aggressive | poetic
```

## Commands

| Command | Effect |
|---|---|
| `bash ~/.claude/skills/break-time/scripts/state.sh` | Show current state |
| `bash ~/.claude/skills/break-time/scripts/snooze.sh 60` | Snooze for 60 minutes |
| `bash ~/.claude/skills/break-time/scripts/reset.sh` | Reset session timer |

Or just say things in chat — "snooze break-time", "show me break-time state", "reset the break timer" — and Claude will run the right command for you.

## How it works

Read `HOOKS-101.md` for the full beginner-friendly explanation of hooks. It's a standalone tutorial — useful even if you never install this skill.

## Files

- `SKILL.md` — skill definition Claude loads
- `HOOKS-101.md` — **standalone tutorial on writing Claude Code hooks** (publishable)
- `example-settings.json` — copy-paste hook config
- `scripts/check_break.sh` — the hook itself
- `scripts/snooze.sh` — snooze for N minutes
- `scripts/reset.sh` — reset session timer
- `scripts/state.sh` — print human-readable state
