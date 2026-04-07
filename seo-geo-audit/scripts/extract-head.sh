#!/usr/bin/env bash
# seo-geo-audit: extract <head>-relevant content from a file
#
# Usage: scripts/extract-head.sh <file>
#
# Works for HTML, JSX, TSX, MDX, Astro, Vue. Output is line-prefixed
# so the consuming skill can cite file:line in findings.

set -uo pipefail

FILE="${1:?usage: extract-head.sh <file>}"
[[ -f "$FILE" ]] || { echo "extract-head: file not found: $FILE" >&2; exit 2; }

echo "# $FILE"
echo

# 1. Direct <head> tag (HTML, Astro, Vue templates)
echo "## <head> region"
awk '/<head[^>]*>/,/<\/head>/ { print NR": "$0 }' "$FILE" 2>/dev/null
echo

# 2. <title>
echo "## <title>"
grep -nE '<title[^>]*>|<Title[^>]*>' "$FILE" 2>/dev/null
echo

# 3. <meta> tags anywhere (JSX/TSX often put them in components)
echo "## <meta> tags"
grep -nE '<meta[[:space:]]|<Meta[[:space:]]' "$FILE" 2>/dev/null
echo

# 4. <link rel> tags
echo "## <link rel>"
grep -nE '<link[[:space:]][^>]*rel=' "$FILE" 2>/dev/null
echo

# 5. Next.js metadata exports
echo "## Next.js metadata exports"
grep -nE 'export\s+(const|let|var)\s+metadata\s*[:=]|export\s+async\s+function\s+generateMetadata' "$FILE" 2>/dev/null
echo

# 6. Nuxt useHead / useSeoMeta
echo "## Nuxt useHead / useSeoMeta"
grep -nE 'useHead\(|useSeoMeta\(' "$FILE" 2>/dev/null
echo

# 7. react-helmet / next/head
echo "## react-helmet / next/head"
grep -nE '<Helmet|<Head>|from\s+["'\'']next/head|from\s+["'\'']react-helmet' "$FILE" 2>/dev/null
echo

# 8. Astro frontmatter (between --- markers at top)
if head -1 "$FILE" 2>/dev/null | grep -q '^---'; then
  echo "## Astro frontmatter"
  awk '/^---$/{c++; next} c==1 {print NR": "$0}' "$FILE"
fi
