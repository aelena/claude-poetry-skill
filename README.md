# claude-poetry-skill

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that turns `git commit` into a small piece of poetry — haiku, senryu, tanka, or renga — either grounded in the actual diff or freely imagined.

Inspired by [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) for its invocation/stop pattern.

## What it does

- Reads the staged diff and summarizes it.
- Picks a poetic form automatically by file count (1 → haiku, 2–4 → tanka, 5+ → renga), or uses the form you ask for.
- Writes the poem (no emojis, strict syllable counts).
- Either replaces the commit message entirely (`pure` mode) or appends the poem after a conventional `type(scope): summary` line (`hybrid` mode, default).
- Previews and asks before committing — except in `--yolo` mode, which randomizes everything and commits immediately.
- Reports session token usage after the commit.

## Layout

```
poet-commit/
├── SKILL.md             ← skill definition Claude loads
├── forms.md             ← syllable rules for each form
├── examples.md          ← good and bad poetic commits
└── scripts/
    ├── commit.sh        ← runs git commit with the assembled message
    └── token_report.sh  ← extracts token usage from session JSONL
```

## Install

Copy the `poet-commit/` folder into your Claude Code skills directory:

```bash
cp -r poet-commit ~/.claude/skills/poet-commit
# or clone and copy:
git clone https://github.com/aelena/claude-poetry-skill && cp -r claude-poetry-skill/poet-commit ~/.claude/skills/poet-commit
```

Then in any Claude Code session, invoke:

```
/poet-commit
```

Or just say "commit this as a haiku".

## Invocation cheatsheet

| You say | What happens |
|---|---|
| `/poet-commit` | Auto-form, hybrid, grounded, preview before commit |
| `/poet-commit haiku` · `senryu` · `tanka` · `renga` | Force a form |
| `/poet-commit pure` | Poem-only commit message |
| `/poet-commit free` | Imaginative, ignore diff content |
| `/poet-commit --no-commit` | Print poem only |
| `/poet-commit --yolo` | Random everything, commit immediately |
| "stop poet" / "normal commits" | Disable for the session |

See `poet-commit/SKILL.md` for the full spec.

## Modality examples

The same conceptual change — *fixing a retry loop that was hammering an API* — rendered through every modality the skill supports.

### `/poet-commit haiku` — default form, hybrid, grounded

```
fix(api): clamp retry backoff to 30s ceiling

---

exponential dusk
the server, patient at last
counts to thirty, sleeps
```

### `/poet-commit senryu` — wry, human-flavored, hybrid

```
fix(api): stop hammering upstream on 429

---

we knocked ten times a second
on a door already open
no one was angry
```

### `/poet-commit tanka` — five lines, emotional pivot, hybrid

```
refactor(api): centralize retry policy in one client

---

the cache, evicted
keys we promised to remember
gone with the morning
we rewrite the contract twice
hoping the readers forgive
```

### `/poet-commit renga` — multi-stanza chain for big diffs, hybrid

```
chore(db): migrate sessions table to uuid pks

---

migrations advance
the old column waves once more
then disappears

new tests bloom in rows
patient as the morning sun
green from end to end

we close the branch, exhale
the river finds its new bed
```

### `/poet-commit pure` — poem-only commit message, no conventional prefix

```
the off-by-one bug
hiding for two release cycles
waves as it leaves
```

### `/poet-commit free` — imaginative, ignores diff content

```
margins widen out
where the cursor used to pause
a reader arrives
```

### `/poet-commit --no-commit` — print only, do not commit

Same outputs as above, but the skill prints to the terminal and stops. Useful for drafting before staging.

### `/poet-commit --yolo` — chaos: random form, random mode, immediate commit

```
chore: things changed and the wind knew first

---

a flag flips at noon
no one watching the dial
the build turns over
the reviewer sleeps in late
the river finds a new stone
```

(That one happened to roll *tanka* + *free* + *pure*. Next run might be a renga grounded in the diff. The dice decide.)

### Stop the skill

> stop poet

or

> normal commits

Disables poetry for the rest of the session — your next commit goes through with a plain conventional message.

## Safety

- Never `--no-verify`, never `--amend`, never `git push`.
- Refuses to commit when nothing is staged.
- Sniffs for secrets in the diff (`.env`, keys, credentials, tokens) and falls back to a plain conventional message if found.
- `--yolo` randomizes the *poem*, not git safety.

## Related skills

Part of a family of small, opinionated Claude Code skills:

- [llms-txt](https://github.com/aelena/llms-txt) — generate llms.txt index files
- [seo-geo-audit](https://github.com/aelena/seo-geo-audit) — frontend SEO + GEO auditing
- [break-time](https://github.com/aelena/break-time) — ambient break reminders via hooks
- [vibeasfunc](https://github.com/aelena/vibeasfunc) — VBA → functional C# modernization
- [bpmnemonic](https://github.com/aelena/bpmnemonic) — BPMN → specs.md / prd.md translation
- [repo-badges](https://github.com/aelena/repo-badges) — auto-detect toolchain and insert shields.io badges
