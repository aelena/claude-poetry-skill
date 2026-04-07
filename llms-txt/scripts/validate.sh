#!/usr/bin/env bash
# llms-txt: validate an llms.txt file against spec basics
#
# Usage: scripts/validate.sh [path/to/llms.txt]
# Default is ./llms.txt
#
# Exit codes:
#   0 — valid
#   1 — validation errors
#   2 — file not found

set -uo pipefail

FILE="${1:-llms.txt}"
[[ -f "$FILE" ]] || { echo "validate: file not found: $FILE" >&2; exit 2; }

ERR=0
WARN=0

# 1. First non-blank line must be H1
FIRST="$(grep -m1 -v '^[[:space:]]*$' "$FILE" || true)"
if [[ ! "$FIRST" =~ ^#[[:space:]] ]]; then
  echo "ERROR: first non-blank line must be an H1 (# Project Name), got: $FIRST" >&2
  ERR=1
elif [[ "$FIRST" =~ ^##[[:space:]] ]]; then
  echo "ERROR: first heading must be H1, not H2: $FIRST" >&2
  ERR=1
fi

# 2. Exactly one H1
H1_COUNT="$(grep -c '^#[[:space:]]' "$FILE" || true)"
if [[ "$H1_COUNT" -gt 1 ]]; then
  echo "ERROR: found $H1_COUNT H1 headings, expected exactly 1" >&2
  ERR=1
fi

# 3. Blockquote summary should appear in the first ~10 lines
if ! head -10 "$FILE" | grep -q '^>'; then
  echo "WARN: no blockquote summary (>) found in first 10 lines" >&2
  WARN=1
fi

# 4. No headings inside the context paragraph region
#    (between blockquote and first H2). Check for unexpected H3+ in that region.
AWK_CTX_CHECK='
  /^#[[:space:]]/   { in_h1=1; next }
  /^>/              { saw_bq=1; next }
  /^##[[:space:]]/  { in_sections=1 }
  in_sections       { next }
  /^###[[:space:]]/ { print "ERROR: heading inside context region (line " NR "): " $0; err=1 }
  END               { exit err }
'
if ! awk "$AWK_CTX_CHECK" "$FILE" >&2; then
  ERR=1
fi

# 5. Unclosed markdown links: [title](url with no closing paren
BROKEN="$(grep -nE '\[[^]]+\]\([^)]*$' "$FILE" || true)"
if [[ -n "$BROKEN" ]]; then
  echo "ERROR: unclosed markdown links:" >&2
  echo "$BROKEN" >&2
  ERR=1
fi

# 6. Link list items under H2 should follow `- [title](url)` shape
BAD_ITEMS="$(awk '
  /^##[[:space:]]/  { in_section=1; next }
  in_section && /^-[[:space:]]/ {
    if ($0 !~ /^-[[:space:]]\[[^]]+\]\([^)]+\)/) {
      print NR ": " $0
    }
  }
' "$FILE")"
if [[ -n "$BAD_ITEMS" ]]; then
  echo "WARN: list items not in '- [title](url): description' format:" >&2
  echo "$BAD_ITEMS" >&2
  WARN=1
fi

# Summary
if [[ $ERR -eq 0 && $WARN -eq 0 ]]; then
  echo "OK: $FILE is valid"
elif [[ $ERR -eq 0 ]]; then
  echo "OK with warnings: $FILE is valid but has style issues"
else
  echo "FAIL: $FILE has validation errors" >&2
fi
exit $ERR
