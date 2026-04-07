---
name: poet-commit
description: Compose git commit messages as Japanese short-form poems (haiku, senryū, tanka, renga). Use when the user asks for a poetic, lyrical, haiku, tanka, renga, or otherwise artistic commit message — or invokes /poet, /poet-commit, "commit as a haiku", "make this commit a poem". Auto-picks form by diff size unless overridden. Supports a --yolo mode for chaotic auto-commits.
---

# poet-commit

Turn a `git commit` into a small piece of poetry. Inspired by the **caveman** plugin's invocation/stop pattern: clear triggers, clear arguments, clear off-switch.

## Invocation

| Trigger | Behavior |
|---|---|
| `/poet` or `/poet-commit` | Default — auto-picks form by diff size, hybrid mode (conventional message + poem appended), preview before commit |
| `/poet haiku` · `senryu` · `tanka` · `renga` | Force a specific form |
| `/poet pure` | Poem-only commit message (no conventional prefix) |
| `/poet free` | Imaginative — ignore the diff content, write from the vibe |
| `/poet grounded` | Strictly derived from the diff (default) |
| `/poet --no-commit` | Print poem only, do not commit |
| `/poet --yolo` | Chaos mode: random form, random grounded/free, random pure/hybrid, **commit immediately without preview** |
| Natural language: "commit this as a haiku", "make the commit poetic", "tanka commit" | Same as `/poet <form>` |

Arguments combine: `/poet tanka grounded`, `/poet renga pure`, etc.

### Stop / disable

- "stop poet" · "normal commits" · "no more poems" → disable for the session, fall back to ordinary commit messages.
- Always disabled automatically when the diff looks security-sensitive (see Safety below).

## Auto-form selection (when no form is specified)

Inspect `git diff --staged --name-only` (fallback to unstaged):

| Files changed | Form |
|---|---|
| 1 file | **haiku** (5-7-5) — or **senryū** if the change is a bug fix / human-flavored |
| 2–4 files | **tanka** (5-7-5-7-7) |
| 5+ files | **renga** — one 5-7-5 stanza per logical concern, then a closing 7-7 |

Override with an explicit form arg at any time.

## Execution flow

1. **Read the diff.** Run `git status --short` and `git diff --staged`. If nothing is staged, fall back to `git diff` and warn the user that nothing will be committed unless they stage first. If both are empty, refuse.
2. **Summarize the change** internally in one sentence. Identify a "kigo" — a single concrete technical motif (e.g. *cache*, *retry*, *boundary*, *migration*) that will anchor the poem if grounded.
3. **Pick the form** from explicit arg, otherwise auto-select by file count (see table above).
4. **Pick the mode** — grounded (default) or free if the user asked. In `--yolo`, randomize.
5. **Generate the poem** following `forms.md` syllable rules. Count syllables carefully; revise if off. No emojis. Plain ASCII or basic Unicode only. Do not invent technical claims that aren't in the diff when in grounded mode.
6. **Assemble the message:**
   - **hybrid** (default): one conventional commit subject line (`type(scope): summary`), blank line, `---`, blank line, the poem.
   - **pure**: just the poem. Subject line is the poem's first line; body is the rest.
7. **Preview & confirm.** Show the user the assembled message and ask for confirmation before committing. Skip this step **only** when `--yolo` is set.
8. **Commit** by running `scripts/commit.sh` with the assembled message piped via heredoc (never `--no-verify`, never `--amend`).
9. **Report tokens.** Run `scripts/token_report.sh` and print its one-line output. If it fails, print `(token usage unavailable)` and continue.

## Safety guardrails

- **Confirm before committing** in all modes except `--yolo`. Even in `--yolo`, refuse silently-destructive things (force push, amend, no-verify) — `--yolo` is chaotic about *form*, not about *git safety*.
- **Never** stage files automatically. The user controls the index.
- **Never** use `git commit --no-verify`, `--amend`, or `git push`. Commits only.
- **Secret-sniff.** If the staged diff touches `.env*`, `*.pem`, `*key*`, `credentials*`, `*.secret`, or contains lines matching `(?i)(api[_-]?key|secret|password|token)\s*[:=]`, abort poetry, warn the user, and fall back to a plain conventional commit message (still requiring confirmation).
- **Empty index.** If nothing is staged, do not commit. Offer to print the poem only.
- **Hooks.** If a pre-commit hook fails, do **not** retry with `--no-verify`. Report the failure to the user and stop.

## Style rules for the poem itself

- Honor syllable counts strictly. Count out loud (silently) before emitting.
- One concrete image per stanza. Avoid abstractions like "code" or "system" unless they earn their place.
- A *kireji* (cutting word / turn) somewhere — a dash, a colon, a line break that pivots.
- No emojis, no markdown inside the poem block, no quotation marks around lines.
- English syllables, not strict Japanese moras. Read naturally.
- Grounded mode: the kigo must come from the diff. Free mode: anything goes, but stay tonally appropriate (don't write a love poem for a security patch).

## Example output (hybrid haiku, grounded, retry-loop fix)

```
fix(api): clamp retry backoff to 30s ceiling

---

exponential dusk
the server, patient at last
counts to thirty, sleeps
```

See `examples.md` for more.

## Files in this skill

- `SKILL.md` — this file
- `forms.md` — syllable rules and structural notes for each form
- `examples.md` — curated good and bad poetic commits
- `scripts/commit.sh` — runs the actual `git commit` with a heredoc message
- `scripts/token_report.sh` — best-effort token usage report from the session JSONL
