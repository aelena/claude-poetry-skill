# Classical SEO checks

Severities: **high** = blocks indexing or rankings · **medium** = noticeable impact · **low** = nice-to-have · **info** = informational only.

Each check below describes *what to look for* and *why it matters*. Claude runs these as reasoning steps over the extracted `<head>` data and source files — they are not regex matches.

## Per-page essentials

| ID | Check | Severity | What to look for |
|---|---|---|---|
| SEO-001 | `<title>` present | high | Every page has a `<title>` element. None empty. |
| SEO-002 | `<title>` unique per page | high | No two pages share the same title. Duplicates dilute rankings. |
| SEO-003 | `<title>` length 30–60 chars | medium | Outside this range Google truncates or pads with site name. |
| SEO-004 | `<meta name="description">` present | high | Every page has a description. None empty, none auto-generated. |
| SEO-005 | Description length 50–160 chars | medium | Outside this range, Google rewrites your snippet. |
| SEO-006 | Description is *content*, not boilerplate | medium | "Welcome to our site" is a fail. Should describe the page. |
| SEO-007 | `<link rel="canonical">` present | high | Prevents duplicate-content penalties. Especially critical for pagination, query params. |
| SEO-008 | `<meta name="viewport">` mobile-friendly | high | `width=device-width, initial-scale=1`. Missing = mobile penalty. |
| SEO-009 | `<html lang="...">` set | medium | Helps Google serve the right locale. |

## Semantic structure

| ID | Check | Severity | What to look for |
|---|---|---|---|
| SEO-010 | Exactly one `<h1>` per page | high | Multiple H1s confuse the page-topic signal. Zero is worse. |
| SEO-011 | Heading hierarchy is sequential | medium | No `<h2>` followed directly by `<h4>`. |
| SEO-012 | Headings describe content, not visual style | medium | "Click here", "Section 1" → fail. Headings are for crawlers, not designers. |
| SEO-013 | Semantic landmarks present | medium | `<main>`, `<nav>`, `<header>`, `<footer>`, `<article>`. Improves crawler understanding. |
| SEO-014 | Internal links use descriptive anchor text | medium | "Click here", "Read more" → fail. "Read our migration guide" → pass. |

## Images and media

| ID | Check | Severity | What to look for |
|---|---|---|---|
| SEO-015 | All `<img>` have `alt` attribute | high | Missing alt = inaccessible *and* unindexed in image search. |
| SEO-016 | Decorative images have `alt=""` | low | Empty alt is correct for decoration. Missing alt is wrong. |
| SEO-017 | Images use modern formats where possible | info | WebP, AVIF preferred over PNG/JPG for content images. |
| SEO-018 | Images have explicit dimensions | medium | `width` and `height` attrs prevent layout shift (CLS impacts ranking). |

## Social / sharing

| ID | Check | Severity | What to look for |
|---|---|---|---|
| SEO-019 | Open Graph tags present | medium | `og:title`, `og:description`, `og:image`, `og:url`, `og:type`. |
| SEO-020 | Twitter Card tags present | low | `twitter:card`, `twitter:title`, `twitter:image`. |
| SEO-021 | OG image dimensions correct | low | 1200×630 minimum for proper rendering on most platforms. |

## Technical / site-wide

| ID | Check | Severity | What to look for |
|---|---|---|---|
| SEO-022 | `robots.txt` exists | medium | Repo root or `public/`. Should not block important paths. |
| SEO-023 | `sitemap.xml` exists or is generated | medium | Static file or framework-generated. Linked from `robots.txt`. |
| SEO-024 | No `noindex` on important pages | high | A `<meta name="robots" content="noindex">` left in production = invisible page. |
| SEO-025 | HTTPS-only canonical URLs | high | Canonicals must be HTTPS, not HTTP. |
| SEO-026 | No orphan pages | medium | Every page should be reachable from at least one internal link or the sitemap. |

## Anti-patterns to flag

| ID | Check | Severity | What to look for |
|---|---|---|---|
| SEO-027 | Keyword stuffing in title or description | medium | Repeated keywords, comma-separated keyword lists. |
| SEO-028 | Hidden text (`display:none` content) | high | Old-school SEO trick that now triggers penalties. |
| SEO-029 | Cloaking via user-agent sniffing | high | Serving different content to crawlers vs users. |
| SEO-030 | Pagination without `rel="prev"`/`rel="next"` | low | Less critical than it used to be, but still good hygiene. |
