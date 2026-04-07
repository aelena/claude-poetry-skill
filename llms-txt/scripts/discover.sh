#!/usr/bin/env bash
# llms-txt: enumerate candidate files for inclusion in llms.txt
#
# Usage: scripts/discover.sh [repo-root]
# Default repo-root is current directory.
#
# Output is grouped by category. The skill consumes this list and decides
# what to include — this script is just file discovery.

set -uo pipefail

ROOT="${1:-.}"
[[ -d "$ROOT" ]] || { echo "discover: not a directory: $ROOT" >&2; exit 2; }

EXCLUDE_PATHS=(
  -not -path "*/node_modules/*"
  -not -path "*/.git/*"
  -not -path "*/vendor/*"
  -not -path "*/target/*"
  -not -path "*/build/*"
  -not -path "*/dist/*"
  -not -path "*/.venv/*"
  -not -path "*/__pycache__/*"
)

echo "## Project metadata"
for f in README.md README.rst README.txt README \
         package.json pyproject.toml setup.py setup.cfg \
         Cargo.toml Gemfile go.mod composer.json \
         pom.xml build.gradle build.gradle.kts; do
  [[ -f "$ROOT/$f" ]] && echo "$f"
done
echo

echo "## Root markdown"
find "$ROOT" -maxdepth 1 -type f \( -name "*.md" -o -name "*.mdx" -o -name "*.rst" \) 2>/dev/null \
  | sed "s|^$ROOT/||" | sort
echo

echo "## docs/ directory"
if [[ -d "$ROOT/docs" ]]; then
  find "$ROOT/docs" -type f \( -name "*.md" -o -name "*.mdx" -o -name "*.rst" \) "${EXCLUDE_PATHS[@]}" 2>/dev/null \
    | sed "s|^$ROOT/||" | sort
fi
echo

echo "## doc/ directory"
if [[ -d "$ROOT/doc" ]]; then
  find "$ROOT/doc" -type f \( -name "*.md" -o -name "*.mdx" -o -name "*.rst" \) "${EXCLUDE_PATHS[@]}" 2>/dev/null \
    | sed "s|^$ROOT/||" | sort
fi
echo

echo "## examples/ directory"
if [[ -d "$ROOT/examples" ]]; then
  find "$ROOT/examples" -maxdepth 2 -type f \( -name "*.md" -o -name "README*" \) "${EXCLUDE_PATHS[@]}" 2>/dev/null \
    | sed "s|^$ROOT/||" | sort
fi
echo

echo "## Other markdown (depth 2-3)"
find "$ROOT" -mindepth 2 -maxdepth 3 -type f -name "*.md" \
  -not -path "$ROOT/docs/*" \
  -not -path "$ROOT/doc/*" \
  -not -path "$ROOT/examples/*" \
  "${EXCLUDE_PATHS[@]}" 2>/dev/null \
  | sed "s|^$ROOT/||" | sort | head -50
echo

echo "## Suspected secrets (DO NOT INDEX)"
find "$ROOT" -maxdepth 3 -type f \
  \( -name ".env*" -o -name "*.pem" -o -name "*key*" -o -name "credentials*" -o -name "*.secret" \) \
  "${EXCLUDE_PATHS[@]}" 2>/dev/null \
  | sed "s|^$ROOT/||" | sort
