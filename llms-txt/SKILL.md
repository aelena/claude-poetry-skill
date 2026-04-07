---
name: llms-txt
description: Generate or update an llms.txt file at the root of a code repository, following the llmstxt.org spec — making the project navigable by language models. Use when the user asks to create llms.txt, generate an LLM index, document a repo for AI consumption, audit existing llms.txt, or invokes /llms-txt, /llms-txt full, /llms-txt validate.
---

# llms-txt

Create a high-quality `llms.txt` file at the root of a repository, following the [llmstxt.org](https://llmstxt.org/) proposed standard. The file is a curated, machine-readable index of the project — a "table of contents for LLMs" — that fits comfortably in a model's context window.

## Why this exists

LLMs reading a repo blind have to guess what matters. `llms.txt` lets a project *tell* them: here is the project, here is the summary, here are the canonical docs in priority order, here are the secondary resources you can skip if context is tight. It's `robots.txt` for the model era — except it helps the model do its job better, not worse.

## Invocation

| Trigger | Behavior |
|---|---|
| `/llms-txt` or `/llms-txt-gen` | Generate `llms.txt` at the repo root |
| `/llms-txt full` | Also generate `llms-full.txt` (concatenated full docs, no truncation) |
| `/llms-txt validate` | Validate an existing `llms.txt` against the spec |
| `/llms-txt update` | Refresh an existing `llms.txt` with current repo state, preserving manual edits |
| Natural language: "create an llms.txt", "make this repo LLM-friendly", "generate the llm index" | Same |

### Stop / disable

Not really applicable — this is a one-shot generator, not a session mode. Just don't invoke it.

## Execution flow

1. **Discover candidates.** Run `scripts/discover.sh` to enumerate:
   - Project metadata files: `README*`, `package.json`, `pyproject.toml`, `Cargo.toml`, `Gemfile`, `go.mod`, etc.
   - Root-level markdown: `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE`, `ARCHITECTURE.md`, etc.
   - `docs/` directory contents (`.md`, `.mdx`, `.rst`)
   - Other markdown at depth 2–3 (excluding `node_modules`, `.git`, `vendor`)

2. **Read and synthesize.** Read the README and primary metadata file. Extract:
   - Project name (from `package.json:name`, `pyproject.toml:[project].name`, or README H1)
   - One-sentence summary (from README's first paragraph or `package.json:description`)
   - Longer context (1–2 paragraphs from the README intro, no headings)

3. **Categorize candidates** into H2 sections. Reasonable defaults:
   - **Docs** — primary user-facing documentation
   - **Examples** — sample code, tutorials, quickstarts
   - **API Reference** — generated or hand-written API docs
   - **Optional** — secondary resources (CHANGELOG, contributing guides, RFCs, internal notes)

   The `## Optional` section has special meaning in the spec: LLMs with tight context budgets should skip it. Put anything non-essential there.

4. **Generate `llms.txt`** following the format in `format.md`. Strict structure:
   ```
   # Project Name

   > One-sentence summary in a blockquote.

   Optional 1-2 paragraph context, no headings.

   ## Section
   - [Title](relative-or-absolute-url): one-line description
   - [Title](url): description

   ## Optional
   - [Title](url): description
   ```

5. **Validate** with `scripts/validate.sh`. If errors, fix and re-validate.

6. **Preview** the generated file to the user before writing it. Ask confirmation.

7. **Write** to `./llms.txt`. If a file already exists, **diff against it** and ask before overwriting — preserve any manual sections the user added.

8. **Optional `llms-full.txt`** (only if `full` arg given): concatenate the full content of every linked doc into a single file, with `# File: <path>` headers between them. This is the "give me everything" variant.

## Safety guardrails

- **Never overwrite an existing `llms.txt` without preview + confirmation.** It may contain manual curation.
- **Never include secrets** in the generated file. Skip any candidate file matching `.env*`, `*.pem`, `*key*`, `credentials*`, `*.secret`. Warn the user if found.
- **Never link to private paths** (anything inside `.git/`, `node_modules/`, `vendor/`, `target/`, `build/`, `dist/`).
- **Don't invent URLs.** All links must point to real files in the repo (relative paths) or URLs explicitly present in the README. Don't guess the project's homepage.
- **Respect `.gitignore`.** If a candidate file is gitignored, don't index it.

## Style rules for the generated file

- **H1 is the project name**, nothing else. Not a slogan, not a tagline.
- **Blockquote summary is one sentence**, present tense, factual. No marketing language.
- **Descriptions on link items are one line**, ~12 words max. Tell the LLM *why* this file matters, not what it says verbatim.
- **Order matters within a section** — most important first. The model may stop reading partway through.
- **No emojis**, no decorative markdown, no nested lists. The format is intentionally flat.
- **Prefer relative paths** for files in the repo (`docs/getting-started.md`), absolute URLs only for external resources.

## Files in this skill

- `SKILL.md` — this file
- `format.md` — the llmstxt.org format reference, distilled
- `scripts/discover.sh` — enumerate candidate files for indexing
- `scripts/validate.sh` — lint a generated `llms.txt` against spec basics
