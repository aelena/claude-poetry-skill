#!/usr/bin/env bash
# vibeasfunc: extract VBA modules from an .xlsm / .xlsb / .docm file.
#
# Usage: scripts/extract-vba.sh <office-file> [output-dir]
#
# Best-effort. Tries `olevba` (from oletools) first. Falls back to telling
# the user how to export modules manually from the host application.
#
# This script never modifies the source file.

set -uo pipefail

FILE="${1:?usage: extract-vba.sh <office-file> [output-dir]}"
OUT="${2:-./vba-extracted}"

[[ -f "$FILE" ]] || { echo "extract-vba: file not found: $FILE" >&2; exit 2; }

mkdir -p "$OUT"

# Strategy 1: olevba (from python-oletools)
if command -v olevba >/dev/null 2>&1; then
  echo "extract-vba: using olevba"
  olevba --no-deobf --code "$FILE" > "$OUT/$(basename "$FILE").olevba.txt" 2>/dev/null || {
    echo "extract-vba: olevba failed (file may have no VBA, or be encrypted)" >&2
    exit 3
  }
  echo "extract-vba: extracted to $OUT/$(basename "$FILE").olevba.txt"
  echo "extract-vba: review the file, then point analyze-vba.sh at individual module sections"
  exit 0
fi

# Strategy 2: tell the user how to export manually
cat <<EOF >&2
extract-vba: olevba not found. Two options:

  1. Install python-oletools and re-run:
       pip install oletools
       scripts/extract-vba.sh "$FILE"

  2. Export modules manually from the host application (Excel/Word/Access):
       - Open the file
       - Press Alt+F11 to open the VBA editor
       - In the Project Explorer, right-click each module
       - File > Export File...
       - Save as .bas (modules) / .cls (classes) / .frm (forms)
       - Then run: scripts/analyze-vba.sh path/to/exported.bas

This script will not run Office or modify your file.
EOF
exit 4
