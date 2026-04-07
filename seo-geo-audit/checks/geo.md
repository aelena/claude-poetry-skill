# GEO checks — Generative Engine Optimization

**This is the novel part.** Classical SEO is about Google's crawler. GEO is about *language models* reading your content — for search results that cite, for assistants that answer questions, for agents that act on behalf of users. The rules are different.

The core insight: **LLMs prefer content that is structured, scannable, cited, and explicitly typed.** They reward clarity in ways human readers don't notice.

Severities: **high** = LLMs will skip or misrepresent your content · **medium** = LLMs will work harder to extract value · **low** = nice-to-have · **info** = signal only.

## Discoverability for LLMs

| ID | Check | Severity | What to look for |
|---|---|---|---|
| GEO-001 | `llms.txt` present at site root | high | The proposed standard ([llmstxt.org](https://llmstxt.org)). Tells LLMs what your project is and where the canonical docs live. If missing, recommend the `llms-txt` skill. |
| GEO-002 | `llms-full.txt` present | medium | Full-content variant for LLMs that want everything in one shot. |
| GEO-003 | `robots.txt` doesn't accidentally block LLM crawlers | medium | If `User-agent: GPTBot Disallow: /` is set intentionally, that's a policy choice — flag it as info. If accidental, flag as medium. |
| GEO-004 | `noai` / `noimageai` meta tags | info | Detect them. Don't judge. Just tell the user they're opted out. |

## Structured data (the highest-leverage GEO category)

| ID | Check | Severity | What to look for |
|---|---|---|---|
| GEO-005 | JSON-LD present on key pages | high | LLMs extract typed entities from JSON-LD verbatim. No JSON-LD = no entity extraction. |
| GEO-006 | `Article` / `BlogPosting` schema with `headline`, `author`, `datePublished` | high | Required for citation-grade content. Without these, LLMs can't attribute properly. |
| GEO-007 | `Organization` or `Person` schema for entities | medium | Helps LLMs disambiguate "Acme" your-company from "Acme" the cartoon. |
| GEO-008 | `FAQPage` schema on FAQ pages | high | FAQs are gold for LLM retrieval. Wrapping them in schema makes them perfectly extractable. |
| GEO-009 | `HowTo` schema on tutorials | medium | LLMs can render step-by-step content directly. |
| GEO-010 | `Product` schema on product pages | medium | Price, availability, ratings — all directly extractable. |
| GEO-011 | `BreadcrumbList` schema | low | Helps LLMs understand site hierarchy and parent context. |
| GEO-012 | Schema.org @context is correct | high | `"@context": "https://schema.org"` (not `http://` or missing). |
| GEO-013 | JSON-LD validates as JSON | high | Trailing commas, unescaped quotes — silently break extraction. |

## Content shape

| ID | Check | Severity | What to look for |
|---|---|---|---|
| GEO-014 | Median paragraph length under 100 words | medium | Short paragraphs are scannable. Wall-of-text paragraphs are skipped. |
| GEO-015 | Sentences average under 25 words | medium | Long sentences are harder for LLMs to chunk and embed cleanly. |
| GEO-016 | Headings are descriptive and self-contained | high | A heading like "Why this matters" is useless out of context. "Why retry budgets prevent thundering herds" is citable on its own. |
| GEO-017 | Lists are used where appropriate | medium | LLMs love structured lists — they extract them as discrete facts. Prose-encoded lists are lossy. |
| GEO-018 | Tables have `<thead>` and `<th>` headers | medium | Tables without headers are noise. With headers, they're structured data. |
| GEO-019 | Tables have `<caption>` or accompanying description | low | Helps LLMs know what the table is *about*, not just its contents. |
| GEO-020 | Code blocks have language hints | medium | ```` ```python ```` not just ```` ``` ````. LLMs use this for type inference and syntax-aware reasoning. |
| GEO-021 | Code blocks are not screenshots | high | A screenshot of code is invisible to text-only LLMs. Always use real code blocks. |

## Citation and trust signals

| ID | Check | Severity | What to look for |
|---|---|---|---|
| GEO-022 | Author name visible on articles | high | LLMs cite authors. No author = no citation = lower retrieval ranking. |
| GEO-023 | Publication date visible and machine-readable | high | `<time datetime="...">` or schema.org `datePublished`. |
| GEO-024 | Last-updated date present where relevant | medium | Especially for evergreen content. LLMs prefer recent. |
| GEO-025 | Outbound citations to authoritative sources | medium | Linked sources signal trustworthiness. Unlinked claims are flat. |
| GEO-026 | Claims are concrete, not hedged | low | "X is 3x faster" beats "X may be relatively performant in some cases". LLMs surface concrete claims. |
| GEO-027 | Numbers are specific, not vague | low | "98% uptime over 6 months" beats "highly reliable". |

## Multimodal context

| ID | Check | Severity | What to look for |
|---|---|---|---|
| GEO-028 | Image alt text describes content, not appearance | high | "Architecture diagram showing client-API-database flow" beats "diagram.png". |
| GEO-029 | Captions accompany important images | medium | Captions are read; alt is for accessibility. Both serve different LLM purposes. |
| GEO-030 | Diagrams have text equivalents nearby | medium | An LLM cannot read a Mermaid render in a screenshot. Provide the source or a paragraph summary. |

## Crawlability for LLMs

| ID | Check | Severity | What to look for |
|---|---|---|---|
| GEO-031 | Critical content rendered server-side | high | Content that only appears after JS execution is invisible to most LLM crawlers. |
| GEO-032 | No content gated behind cookie banners | medium | LLM crawlers don't click "accept". |
| GEO-033 | URL structure is human-readable | low | `/blog/retry-budgets-2024` beats `/p?id=4421`. |
| GEO-034 | One canonical URL per piece of content | high | Same as classical SEO — but doubly important for LLM dedup. |

## Anti-patterns to flag

| ID | Check | Severity | What to look for |
|---|---|---|---|
| GEO-035 | AI-generated content with no human review markers | info | Not bad per se, but worth flagging for the user's awareness. |
| GEO-036 | "Click to expand" sections hiding important content | medium | LLMs may not unfold accordions. Important content should be visible. |
| GEO-037 | Content split across many short pages (SEO-era pagination) | medium | LLMs prefer one long, well-structured page over 10 thin ones. |
