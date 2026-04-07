#!/usr/bin/env bash
# seo-geo-audit: find <script type="application/ld+json"> blocks
#
# Usage: scripts/find-jsonld.sh <file-or-directory>
#
# Outputs each block prefixed with its file:line so the consuming
# skill can cite them in findings.

set -uo pipefail

TARGET="${1:?usage: find-jsonld.sh <file-or-directory>}"
[[ -e "$TARGET" ]] || { echo "find-jsonld: not found: $TARGET" >&2; exit 2; }

EXCLUDES=(
  -not -path "*/node_modules/*"
  -not -path "*/.git/*"
  -not -path "*/dist/*"
  -not -path "*/build/*"
  -not -path "*/.next/*"
)

scan_file() {
  local f="$1"
  local in_block=0
  local start_line=0
  local block=""
  local lineno=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))
    if [[ "$in_block" -eq 0 ]]; then
      if echo "$line" | grep -qE '<script[^>]*type=["'\'']application/ld\+json["'\'']'; then
        in_block=1
        start_line=$lineno
        block=""
        # Capture content after the opening tag on the same line, if any
        after="$(echo "$line" | sed -E 's|^.*<script[^>]*type=["'\'']application/ld\+json["'\''][^>]*>||')"
        if [[ -n "$after" ]]; then
          if echo "$after" | grep -q '</script>'; then
            block="$(echo "$after" | sed 's|</script>.*||')"
            echo "## $f:$start_line"
            echo "$block"
            echo
            in_block=0
            block=""
            continue
          fi
          block="$after"
        fi
      fi
    else
      if echo "$line" | grep -q '</script>'; then
        before="$(echo "$line" | sed 's|</script>.*||')"
        block="${block}${before}"
        echo "## $f:$start_line"
        echo "$block"
        echo
        in_block=0
        block=""
      else
        block="${block}"$'\n'"${line}"
      fi
    fi
  done < "$f"
}

if [[ -f "$TARGET" ]]; then
  scan_file "$TARGET"
else
  while IFS= read -r f; do
    scan_file "$f"
  done < <(find "$TARGET" -type f \( -name "*.html" -o -name "*.htm" -o -name "*.jsx" -o -name "*.tsx" -o -name "*.vue" -o -name "*.astro" -o -name "*.mdx" \) "${EXCLUDES[@]}" 2>/dev/null)
fi
