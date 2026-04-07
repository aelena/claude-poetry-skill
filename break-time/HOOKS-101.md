# Hooks 101 — a beginner's guide to Claude Code hooks

You've used Claude Code. You've maybe heard the word "hooks" thrown around. You opened this file because you want to know what they are, what they're good for, and how to write one without breaking anything. Welcome.

By the end of this guide you'll have a working hook of your own and a mental model you can apply to anything else.

## What is a hook?

A hook is **a tiny shell command that Claude Code runs at specific moments** — when you submit a prompt, when Claude is about to call a tool, when a session starts, when a session ends. It's how you teach the harness to do things Claude itself can't.

The key insight: **Claude is not the harness.** Claude is the language model. The harness is the program around Claude that takes your input, calls Claude, runs tools, and shows you results. Hooks live in the harness, not in Claude.

That distinction matters because:
- **Claude can't read the wall clock between turns.** It only sees the conversation.
- **Claude can't scan a file unless you ask it to.** It doesn't know what's on disk.
- **Claude can't enforce a rule unless it remembers to.** It might forget.

Hooks fix all three. A hook runs every time, in milliseconds, with full access to your filesystem and shell. It can inject context that Claude *will* see, or block actions Claude shouldn't take.

## The events you can hook into

Claude Code fires events at well-defined moments. You attach hooks to events.

| Event | Fires when | Common uses |
|---|---|---|
| `SessionStart` | a Claude Code session begins | inject project context, load secrets, log start |
| `UserPromptSubmit` | you press enter on a prompt | preprocess input, **inject context**, track time, log activity |
| `PreToolUse` | Claude is about to call a tool | log, **block dangerous calls**, gate destructive actions |
| `PostToolUse` | a tool call finished | format output, post-process, auto-format on save |
| `Notification` | the harness wants your attention | desktop alerts, sound effects |
| `Stop` | Claude finishes its turn | log, summarize, persist |
| `SubagentStop` | a subagent finishes | aggregate, log |
| `SessionEnd` | the session ends | persist state, archive logs |

For most ambient skills, **`UserPromptSubmit`** is the workhorse. It fires on every prompt, has access to the prompt text, and can inject context. Almost everything in this guide will use it.

## Where hooks live

In `~/.claude/settings.json`. Here is the bare-minimum schema for a hook:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/my-first-hook.sh"
          }
        ]
      }
    ]
  }
}
```

Annotated:

- `"hooks"` — the top-level key. Everything inside is hook configuration.
- `"UserPromptSubmit"` — which event we're hooking into.
- `"matcher": "*"` — for which kinds of events. `*` means "all of them". For `PreToolUse` you'd use a tool name like `"Bash"` or a regex.
- `"hooks": [...]` — the list of hooks to run for this event/matcher combination. Yes, this is nested twice; that's just the schema.
- `"type": "command"` — there's only one type today. Always `"command"`.
- `"command"` — the literal shell command to run. Use absolute paths (`~` is fine, it expands).

You can have multiple hooks for the same event. They run in order.

## What a hook can do

A hook has three powers:

1. **Print to stdout.** The harness captures stdout and adds it as additional context. Claude sees it on its next turn. This is how you inject information into the conversation without the user typing it.
2. **Exit with a non-zero code.** For `PreToolUse` only, this *blocks* the tool call. Claude is told the action was denied. Use this for guardrails.
3. **Side effects.** A hook is a shell command. It can write files, log, mutate state, send notifications. Side effects don't show up in the conversation directly, but they shape future hook invocations.

## Your first hook in 5 lines

Open a new file at `~/my-first-hook.sh`:

```bash
#!/usr/bin/env bash
echo "<system-reminder>"
echo "It is now $(date '+%H:%M'). Be efficient."
echo "</system-reminder>"
```

Make it executable:

```bash
chmod +x ~/my-first-hook.sh
```

Add this to `~/.claude/settings.json` (merge with whatever's already there, don't overwrite):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "bash ~/my-first-hook.sh" }
        ]
      }
    ]
  }
}
```

Restart Claude Code. Submit any prompt. Claude will know what time it is and (probably) be slightly more concise.

That's a working hook. Five lines. Most magical five lines in the harness.

## State across hook invocations

Hooks are stateless processes. They start, run, exit. To remember things between calls, **write a file**. Anywhere on disk, but `~/.claude/` is conventional.

Here's a hook that counts how many prompts you've sent today:

```bash
#!/usr/bin/env bash
set -uo pipefail

STATE="$HOME/.claude/prompt-count.state"
TODAY="$(date '+%Y-%m-%d')"

# Initialize state if missing or outdated
if [[ ! -f "$STATE" ]] || ! grep -q "^date=$TODAY$" "$STATE"; then
  echo "date=$TODAY"  > "$STATE"
  echo "count=0"     >> "$STATE"
fi

# Read state
source "$STATE"
count=$((count + 1))

# Write new state
echo "date=$TODAY"   > "$STATE"
echo "count=$count" >> "$STATE"

# Inject context if it's a milestone
if (( count % 10 == 0 )); then
  echo "<system-reminder>The user has submitted $count prompts today.</system-reminder>"
fi
```

Source-able key=value flat files are usually all the persistence you need. They don't require `jq` or any other dependency, and `source` makes them painless to read.

## Debugging hooks

This is where most beginners get stuck. Three rules will save you hours:

### Rule 1: hooks fail silently by default

If your hook script throws an error, Claude Code won't tell you. The hook just produces no output and the prompt proceeds normally. To make errors visible, **always redirect stderr to a log file**:

```bash
#!/usr/bin/env bash
exec 2>>"$HOME/.claude/my-hook.log"
set -uo pipefail
# ... rest of your hook
```

Then `tail -f ~/.claude/my-hook.log` while you test.

### Rule 2: run the hook script manually first

Before wiring it up to settings.json, run it directly:

```bash
bash ~/my-first-hook.sh
```

If it produces the output you expect, *then* wire it up. If it doesn't, fix it now while you have a real terminal to debug in.

### Rule 3: use `set -uo pipefail`, but not `-e`

`-u` catches typo'd variables. `-o pipefail` catches failures in pipelines. `-e` causes the script to exit on *any* non-zero, which is too aggressive — `grep` returning 1 on no-match would kill your hook. Skip `-e` and handle errors explicitly.

## Safety: what hooks should never do

The harness will run your hook on every event. That's a lot of opportunities to break things. Avoid:

- **Slow network calls.** Every prompt waits for the hook to finish. A 2-second API call means a 2-second delay on every prompt forever.
- **`rm`, `git push`, `kill`, etc. without a guard.** The hook runs unattended. There is no confirmation step.
- **Assuming `$PWD` is the project.** It might be `~`. Use absolute paths to your state files. `$HOME/.claude/...` is your friend.
- **Printing giant blobs to stdout.** Claude sees all of it. Printing 10KB on every prompt will chew through your context window.
- **Modifying the prompt text itself.** You can inject context, but mangling the user's input is a bad idea — they'll be confused why Claude is answering a different question.

## Walkthrough: building `break-time` from scratch

Now we'll build a real ambient skill — a break-time reminder that nudges you when you've been working too long. By the end of this section you'll have a working version on your machine.

### Step 1: design the state

We need to track:
- When the active session started (so we can compute elapsed time)
- When the last prompt was (so we can detect "idle = new session")
- Which thresholds have already fired (so we don't spam)
- A snooze-until timestamp (so the user can mute it)

Flat key=value file:

```
session_start=1712515800
last_prompt=1712518500
fired=45
snooze_until=0
```

Lives at `~/.claude/break-time.state`. Sourceable in bash. No dependencies.

### Step 2: write the hook script

Save as `~/.claude/skills/break-time/scripts/check_break.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
exec 2>>"$HOME/.claude/break-time.log"

STATE="$HOME/.claude/break-time.state"
NOW=$(date +%s)
THRESHOLDS="45 90 120"   # minutes
IDLE_GAP=$((10 * 60))     # 10 minutes idle = new session

# Initialize if missing
if [[ ! -f "$STATE" ]]; then
  printf 'session_start=%s\nlast_prompt=%s\nfired=\nsnooze_until=0\n' "$NOW" "$NOW" > "$STATE"
fi
source "$STATE"

# Snoozed?
if (( ${snooze_until:-0} > NOW )); then
  sed -i "s/^last_prompt=.*/last_prompt=$NOW/" "$STATE"
  exit 0
fi

# Idle gap exceeded → new session
if (( NOW - last_prompt > IDLE_GAP )); then
  printf 'session_start=%s\nlast_prompt=%s\nfired=\nsnooze_until=0\n' "$NOW" "$NOW" > "$STATE"
  exit 0
fi

active_minutes=$(( (NOW - session_start) / 60 ))

# Check thresholds
nudge=""
new_fired="$fired"
for t in $THRESHOLDS; do
  if (( active_minutes >= t )) && [[ ",$fired," != *",$t,"* ]]; then
    nudge="$t"
    new_fired="${new_fired:+$new_fired,}$t"
  fi
done

# Persist new state
printf 'session_start=%s\nlast_prompt=%s\nfired=%s\nsnooze_until=%s\n' \
  "$session_start" "$NOW" "$new_fired" "${snooze_until:-0}" > "$STATE"

# Emit nudge if any
if [[ -n "$nudge" ]]; then
  case "$nudge" in
    45)  msg="You've been focused for 45 minutes. A short break would help — stretch, look out a window, drink water." ;;
    90)  msg="90 minutes deep. Stand up. Walk for five. Your brain needs the reset more than the next prompt." ;;
    120) msg="Two hours straight. Close the laptop for ten. Diminishing returns are real." ;;
  esac
  cat <<EOF
<system-reminder>
break-time: $msg
(Mention this briefly in your response, in your own voice, before answering the user's actual question. To snooze: bash ~/.claude/skills/break-time/scripts/snooze.sh 60)
</system-reminder>
EOF
fi
```

That's the whole hook. ~50 lines of bash. No dependencies. Read it line by line until it makes sense — every line is doing something specific.

### Step 3: wire it up

Add to `~/.claude/settings.json`:

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

If `settings.json` already has a `"hooks"` key, *merge* with it. Don't replace.

### Step 4: test it

You don't want to wait 45 minutes to test. Temporarily set `THRESHOLDS="1 2 3"` in the script. Restart Claude Code. Submit a prompt, wait a minute, submit another. Claude should mention the break.

Once it works, change the thresholds back to `"45 90 120"`.

### Step 5: add the snooze command

Save as `~/.claude/skills/break-time/scripts/snooze.sh`:

```bash
#!/usr/bin/env bash
MINUTES="${1:-60}"
STATE="$HOME/.claude/break-time.state"
NOW=$(date +%s)
UNTIL=$(( NOW + MINUTES * 60 ))

if [[ -f "$STATE" ]] && grep -q '^snooze_until=' "$STATE"; then
  sed -i "s/^snooze_until=.*/snooze_until=$UNTIL/" "$STATE"
else
  echo "snooze_until=$UNTIL" >> "$STATE"
fi
echo "break-time snoozed for $MINUTES minutes"
```

Now you can run `bash ~/.claude/skills/break-time/scripts/snooze.sh 90` to snooze for 90 minutes. Or have Claude run it for you when you say "snooze break-time".

That's it. You have a working ambient skill. Apply this same pattern to anything else.

## What to build next with hooks

Some ideas to spark imagination, easiest first:

- **`SessionStart` injects current git branch** — every Claude session opens knowing which branch you're on, no tool call needed.
- **`PostToolUse` on Edit auto-runs `prettier`** — file is formatted before you even see the diff.
- **`PreToolUse` on Bash matches `git push --force` and refuses** — your safety net for force-push accidents.
- **`PreToolUse` on Bash refuses any command on Friday after 5pm** — nobody deploys on Friday evening.
- **`UserPromptSubmit` injects current Linear ticket from `~/.linear-current`** — context follows you across sessions.
- **`PostToolUse` on `*` logs every tool call to a CSV** — full audit trail for billing or compliance.
- **`SessionEnd` runs `git stash`** — never lose uncommitted work.

Each one is ~30 lines of bash. Each one teaches you something about how the harness thinks. Once you've built three, you'll see hooks everywhere.

## Further reading

The official Claude Code docs cover the hook schema and event types in more detail. Search for "hooks" in the Claude Code documentation. This guide is the human-friendly companion — it's what you read when the docs assume too much.

Happy hooking.
