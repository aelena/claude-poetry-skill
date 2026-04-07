# claude-poetry-skill

A Claude Code skill that turns `git commit` into a small piece of poetry — haiku, senryū, tanka, or renga — either grounded in the actual diff or freely imagined.

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

## Install (as a skill)

This repo is the **source of truth**. To activate the skill, copy the `poet-commit/` folder into your Claude skills directory:

```bash
# from this repo
cp -r poet-commit ~/.claude/skills/poet-commit
```

Then in any Claude Code session, invoke:

```
/poet-commit
```

Or just say "commit this as a haiku".

## Invocation cheatsheet

| You say | What happens |
|---|---|
| `/poet` | Auto-form, hybrid, grounded, preview before commit |
| `/poet haiku` · `senryu` · `tanka` · `renga` | Force a form |
| `/poet pure` | Poem-only commit message |
| `/poet free` | Imaginative, ignore diff content |
| `/poet --no-commit` | Print poem only |
| `/poet --yolo` | Random everything, commit immediately |
| "stop poet" / "normal commits" | Disable for the session |

See `poet-commit/SKILL.md` for the full spec.

## Future: ship as a plugin

Once the skill stabilizes, drop a `plugin.json` next to `poet-commit/` and a marketplace manifest, and it can be installed via `/plugin install` instead of a manual copy. Same files, different shipping crate.

## Safety

- Never `--no-verify`, never `--amend`, never `git push`.
- Refuses to commit when nothing is staged.
- Sniffs for secrets in the diff (`.env`, keys, credentials, tokens) and falls back to a plain conventional message if found.
- `--yolo` randomizes the *poem*, not git safety.
