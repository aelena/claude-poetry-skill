#!/usr/bin/env bash
# seo-geo-audit: check whether the repo has an llms.txt and llms-full.txt
#
# Usage: scripts/check-llms-txt.sh [repo-root]
#
# Output: one line per file checked. Exit 0 always — this is a probe, not a gate.

set -uo pipefail

ROOT="${1:-.}"

LOCATIONS=(
  "llms.txt"
  "public/llms.txt"
  "static/llms.txt"
  "src/static/llms.txt"
)
LOCATIONS_FULL=(
  "llms-full.txt"
  "public/llms-full.txt"
  "static/llms-full.txt"
  "src/static/llms-full.txt"
)

found_index=0
found_full=0

for loc in "${LOCATIONS[@]}"; do
  if [[ -f "$ROOT/$loc" ]]; then
    echo "llms.txt: PRESENT at $loc"
    found_index=1
    break
  fi
done
[[ $found_index -eq 0 ]] && echo "llms.txt: MISSING (recommend running the llms-txt skill)"

for loc in "${LOCATIONS_FULL[@]}"; do
  if [[ -f "$ROOT/$loc" ]]; then
    echo "llms-full.txt: PRESENT at $loc"
    found_full=1
    break
  fi
done
[[ $found_full -eq 0 ]] && echo "llms-full.txt: MISSING (optional, lower priority)"
