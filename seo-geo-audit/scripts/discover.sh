#!/usr/bin/env bash
# seo-geo-audit: discover frontend source files for auditing
#
# Usage: scripts/discover.sh [framework] [repo-root]
#   framework: next | astro | nuxt | sveltekit | remix | gatsby | vite | vue | html | auto
#   repo-root: defaults to current directory
#
# Outputs grouped lists. Skill consumes them and decides what to audit.

set -uo pipefail

FRAMEWORK="${1:-auto}"
ROOT="${2:-.}"
[[ -d "$ROOT" ]] || { echo "discover: not a directory: $ROOT" >&2; exit 2; }

EXCLUDES=(
  -not -path "*/node_modules/*"
  -not -path "*/.git/*"
  -not -path "*/dist/*"
  -not -path "*/build/*"
  -not -path "*/.next/*"
  -not -path "*/.nuxt/*"
  -not -path "*/out/*"
  -not -path "*/.svelte-kit/*"
  -not -path "*/coverage/*"
)

# Auto-detect framework if not specified
if [[ "$FRAMEWORK" == "auto" ]]; then
  if [[ -f "$ROOT/package.json" ]]; then
    if grep -q '"next"' "$ROOT/package.json" 2>/dev/null; then
      FRAMEWORK=next
    elif grep -q '"astro"' "$ROOT/package.json" 2>/dev/null; then
      FRAMEWORK=astro
    elif grep -q '"nuxt"' "$ROOT/package.json" 2>/dev/null; then
      FRAMEWORK=nuxt
    elif grep -q '"@sveltejs/kit"' "$ROOT/package.json" 2>/dev/null; then
      FRAMEWORK=sveltekit
    elif grep -q '"@remix-run' "$ROOT/package.json" 2>/dev/null; then
      FRAMEWORK=remix
    elif grep -q '"gatsby"' "$ROOT/package.json" 2>/dev/null; then
      FRAMEWORK=gatsby
    elif grep -q '"vue"' "$ROOT/package.json" 2>/dev/null; then
      FRAMEWORK=vue
    else
      FRAMEWORK=vite
    fi
  else
    FRAMEWORK=html
  fi
fi
echo "## Framework: $FRAMEWORK"
echo

echo "## package.json / config"
for f in package.json next.config.js next.config.mjs astro.config.mjs nuxt.config.ts \
         svelte.config.js vite.config.ts vite.config.js gatsby-config.js remix.config.js; do
  [[ -f "$ROOT/$f" ]] && echo "$f"
done
echo

echo "## Pages / routes"
case "$FRAMEWORK" in
  next)
    [[ -d "$ROOT/app" ]] && find "$ROOT/app" -type f \( -name "page.*" -o -name "layout.*" -o -name "head.*" \) "${EXCLUDES[@]}" 2>/dev/null | sed "s|^$ROOT/||"
    [[ -d "$ROOT/pages" ]] && find "$ROOT/pages" -type f \( -name "*.tsx" -o -name "*.jsx" -o -name "*.ts" -o -name "*.js" -o -name "*.mdx" \) "${EXCLUDES[@]}" 2>/dev/null | sed "s|^$ROOT/||"
    ;;
  astro)
    [[ -d "$ROOT/src/pages" ]] && find "$ROOT/src/pages" -type f \( -name "*.astro" -o -name "*.md" -o -name "*.mdx" \) 2>/dev/null | sed "s|^$ROOT/||"
    ;;
  nuxt)
    [[ -d "$ROOT/pages" ]] && find "$ROOT/pages" -type f \( -name "*.vue" -o -name "*.md" \) 2>/dev/null | sed "s|^$ROOT/||"
    ;;
  sveltekit)
    [[ -d "$ROOT/src/routes" ]] && find "$ROOT/src/routes" -type f \( -name "+page.*" -o -name "+layout.*" \) 2>/dev/null | sed "s|^$ROOT/||"
    ;;
  remix)
    [[ -d "$ROOT/app/routes" ]] && find "$ROOT/app/routes" -type f \( -name "*.tsx" -o -name "*.jsx" \) 2>/dev/null | sed "s|^$ROOT/||"
    ;;
  gatsby)
    [[ -d "$ROOT/src/pages" ]] && find "$ROOT/src/pages" -type f \( -name "*.tsx" -o -name "*.jsx" -o -name "*.md" -o -name "*.mdx" \) 2>/dev/null | sed "s|^$ROOT/||"
    ;;
  vue)
    find "$ROOT/src" -type f -name "*.vue" "${EXCLUDES[@]}" 2>/dev/null | sed "s|^$ROOT/||" | head -100
    ;;
  html)
    find "$ROOT" -maxdepth 3 -type f -name "*.html" "${EXCLUDES[@]}" 2>/dev/null | sed "s|^$ROOT/||"
    ;;
  *)
    find "$ROOT/src" -type f \( -name "*.tsx" -o -name "*.jsx" -o -name "*.vue" -o -name "*.html" \) "${EXCLUDES[@]}" 2>/dev/null | sed "s|^$ROOT/||" | head -100
    ;;
esac
echo

echo "## Layouts / shells (head injection happens here)"
find "$ROOT" -type f \( -name "_app.*" -o -name "_document.*" -o -name "layout.*" -o -name "Layout.*" -o -name "+layout.*" -o -name "RootLayout.*" \) "${EXCLUDES[@]}" 2>/dev/null | sed "s|^$ROOT/||" | head -20
echo

echo "## Content (markdown / mdx)"
[[ -d "$ROOT/content" ]] && find "$ROOT/content" -type f \( -name "*.md" -o -name "*.mdx" \) 2>/dev/null | sed "s|^$ROOT/||" | head -50
echo

echo "## Public assets"
for f in public/robots.txt public/sitemap.xml public/llms.txt public/llms-full.txt \
         static/robots.txt static/sitemap.xml static/llms.txt \
         robots.txt sitemap.xml llms.txt llms-full.txt; do
  [[ -f "$ROOT/$f" ]] && echo "$f"
done

exit 0
