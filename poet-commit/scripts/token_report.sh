#!/usr/bin/env bash
# poet-commit: best-effort token usage report for the current Claude Code session.
#
# Strategy:
#   1. Slugify $PWD into the format Claude Code uses for ~/.claude/projects/<slug>/
#      (drive letter + path with separators replaced by '-', leading 'C--' style).
#   2. Find the most recently modified .jsonl in that dir.
#   3. Extract the last `usage` block and pull token counts out of it.
#
# Degrades gracefully: prints "(token usage unavailable)" on any failure.

set -uo pipefail

fail() {
  echo "(token usage unavailable: ${1:-unknown})"
  exit 0
}

PROJECTS_DIR="${HOME}/.claude/projects"
[[ -d "$PROJECTS_DIR" ]] || fail "no projects dir"

# Slugify $PWD the way Claude Code does:
#   /c/Users/anton/OneDrive/.../claude-poetry-skill
#     -> C--Users-anton-OneDrive-...-claude-poetry-skill
# Handle both Git-Bash style (/c/...) and Windows style (C:/...).
slugify() {
  local p="$1"
  # /c/Users/... -> C:/Users/...
  if [[ "$p" =~ ^/([a-zA-Z])/(.*)$ ]]; then
    p="${BASH_REMATCH[1]^^}:/${BASH_REMATCH[2]}"
  fi
  # Replace ':' with nothing, '/' and '\' with '-'
  p="${p//:/}"
  p="${p//\//-}"
  p="${p//\\/-}"
  echo "$p"
}

SLUG="$(slugify "$PWD")"
SESSION_DIR="${PROJECTS_DIR}/${SLUG}"

# If exact slug not found, try to find a dir that ends with the basename
if [[ ! -d "$SESSION_DIR" ]]; then
  BASE="$(basename "$PWD")"
  SESSION_DIR="$(find "$PROJECTS_DIR" -maxdepth 1 -type d -name "*${BASE}" 2>/dev/null | head -n1)"
fi
[[ -n "${SESSION_DIR:-}" && -d "$SESSION_DIR" ]] || fail "no session dir for $PWD"

# Most recent jsonl
JSONL="$(ls -t "$SESSION_DIR"/*.jsonl 2>/dev/null | head -n1)"
[[ -n "$JSONL" && -f "$JSONL" ]] || fail "no session jsonl"

# Take the last full JSONL line that contains "output_tokens" — that's the
# completed usage record for the most recent assistant turn. Extracting from a
# whole line (rather than a brace-delimited substring) avoids nested-object
# truncation bugs when fields like "cache_creation":{...} appear before output.
USAGE_LINE="$(grep '"output_tokens"' "$JSONL" | tail -n1)"
[[ -n "$USAGE_LINE" ]] || fail "no usage line with output_tokens"

extract() {
  # Take the LAST occurrence on the line (avoids picking up nested counters
  # like ephemeral_5m_input_tokens that share substring with input_tokens).
  echo "$USAGE_LINE" | grep -o "\"$1\":[0-9]*" | tail -n1 | cut -d: -f2
}

IN="$(extract input_tokens)"
OUT="$(extract output_tokens)"
CC="$(extract cache_creation_input_tokens)"
CR="$(extract cache_read_input_tokens)"

IN="${IN:-0}"; OUT="${OUT:-0}"; CC="${CC:-0}"; CR="${CR:-0}"
TOTAL=$((IN + OUT + CC + CR))

printf "tokens: in=%s out=%s cache_create=%s cache_read=%s total=%s\n" \
  "$IN" "$OUT" "$CC" "$CR" "$TOTAL"
