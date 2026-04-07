# llms.txt format reference

Distilled from [llmstxt.org](https://llmstxt.org/). The format is intentionally tiny — that's the point.

## Structure

```
# Project Name                                  ← H1, required, project name only

> One-sentence summary in a blockquote.         ← required, single line

Optional longer context. One or two paragraphs   ← optional, no headings allowed
of plain markdown — no headings, no lists.       ← here, just paragraphs.

## Section Name                                  ← H2, repeatable
- [Link title](url): one-line description        ← list of links with descriptions
- [Link title](url): description

## Another Section
- [Link title](url): description

## Optional                                      ← special H2 (literal name)
- [Link title](url): description                 ← items the LLM may skip if context is tight
```

## Rules

1. **H1** appears exactly once, at the top. It is the project name. Nothing else.
2. **Blockquote summary** appears immediately after the H1 (blank line between is fine). One sentence. This is what the LLM uses to decide whether to keep reading.
3. **Optional context paragraphs** can follow the blockquote. They must be plain markdown paragraphs — no headings, no lists, no code fences. This region ends at the first H2.
4. **H2 sections** group related links. Section names are free-form except for `## Optional`, which has the special meaning below.
5. **List items** under each H2 must be markdown links with optional descriptions:
   `- [Title](url): description`
   The colon and description are optional but recommended.
6. **`## Optional`** is a reserved section name. Anything listed here may be skipped by an LLM with limited context. Put secondary resources (changelogs, RFCs, contributing guides, internal notes) here.

## Two file variants

| File | Purpose | Size |
|---|---|---|
| `llms.txt` | The **index** — links and descriptions only. Always small, fits in any context window. | A few KB at most. |
| `llms-full.txt` | The **content** — every linked doc concatenated into one file with `# File: <path>` headers. For LLMs that want the whole thing in one shot. | Can be megabytes. |

`llms.txt` is the canonical file. `llms-full.txt` is optional and complementary.

## Minimal valid example

```
# acme-cli

> Command-line client for the Acme API, with offline mode and shell completions.

## Docs
- [Getting started](docs/getting-started.md): install, auth, first request
- [Configuration](docs/config.md): config file format and environment variables

## Optional
- [Changelog](CHANGELOG.md): release history
```

That's a complete, valid `llms.txt`. The format rewards restraint.

## Common mistakes to avoid

- Multiple H1s (only one allowed).
- Headings inside the context paragraphs region.
- Marketing language in the blockquote ("the world's best CLI for…").
- Links without descriptions (allowed, but wasteful — the description is where you guide the LLM).
- Linking everything. The whole point is curation. If a file isn't important, leave it out (or put it under `## Optional`).
- Inventing URLs that don't resolve.
