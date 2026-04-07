#!/usr/bin/env bash
# poet-commit: commit staged changes with a message read from stdin or a file.
# Usage:
#   echo "message" | scripts/commit.sh
#   scripts/commit.sh path/to/message.txt
#
# Refuses to commit if:
#   - nothing is staged
#   - the message is empty
# Never uses --no-verify, --amend, or any destructive flag.

set -euo pipefail

# 1. Read the message
if [[ $# -ge 1 ]]; then
  if [[ ! -f "$1" ]]; then
    echo "poet-commit: message file not found: $1" >&2
    exit 2
  fi
  MSG="$(cat "$1")"
else
  MSG="$(cat)"
fi

if [[ -z "${MSG// }" ]]; then
  echo "poet-commit: refusing to commit with empty message" >&2
  exit 2
fi

# 2. Verify something is staged
if git diff --cached --quiet; then
  echo "poet-commit: nothing staged. stage your changes first (git add ...)" >&2
  exit 3
fi

# 3. Commit (no --no-verify, no --amend)
git commit -m "$MSG"
