#!/usr/bin/env bash
# vibeasfunc: count VBA constructs in a source file and score complexity.
#
# Usage: scripts/analyze-vba.sh <path-to-bas-or-cls-or-frm-file>
#
# Reads exported VBA modules (.bas, .cls, .frm) and counts language
# constructs to give a rough complexity estimate. Always exit 0 — this
# is a probe, not a gate.

set -uo pipefail

FILE="${1:?usage: analyze-vba.sh <vba-file>}"
[[ -f "$FILE" ]] || { echo "analyze-vba: not found: $FILE" >&2; exit 2; }

count() {
  # grep -c always prints a number; suppress its non-zero exit on no-match.
  grep -ciE "$1" "$FILE" 2>/dev/null || true
}

LINES=$(wc -l < "$FILE")

SUBS=$(count '^[[:space:]]*(public|private)?[[:space:]]*sub[[:space:]]+')
FUNCS=$(count '^[[:space:]]*(public|private)?[[:space:]]*function[[:space:]]+')
PROPS=$(count '^[[:space:]]*(public|private)?[[:space:]]*property[[:space:]]+(get|let|set)')

DIM=$(count '^[[:space:]]*dim[[:space:]]+')
PUBLIC_VAR=$(count '^[[:space:]]*public[[:space:]]+[a-z_][a-z0-9_]*[[:space:]]+as[[:space:]]+')

VARIANT=$(count '\bas[[:space:]]+variant\b')
OBJECT=$(count '\bas[[:space:]]+object\b')

ON_ERR_RESUME=$(count 'on[[:space:]]+error[[:space:]]+resume[[:space:]]+next')
ON_ERR_GOTO=$(count 'on[[:space:]]+error[[:space:]]+goto')
GOTO=$(count '^[[:space:]]*goto[[:space:]]+')

FOR_EACH=$(count '^[[:space:]]*for[[:space:]]+each')
FOR_LOOP=$(count '^[[:space:]]*for[[:space:]]+[a-z_][a-z0-9_]*[[:space:]]*=')
DO_WHILE=$(count '^[[:space:]]*do[[:space:]]+while')
DO_UNTIL=$(count '^[[:space:]]*do[[:space:]]+until')

WITH_BLOCK=$(count '^[[:space:]]*with[[:space:]]+')
SELECT_CASE=$(count '^[[:space:]]*select[[:space:]]+case')

CELLS=$(count '\bcells[[:space:]]*\(')
RANGE=$(count '\brange[[:space:]]*\(')
SHEETS=$(count '\bsheets[[:space:]]*\(')
ACTIVE=$(count '\bactive(sheet|cell|workbook)\b')

CREATEOBJECT=$(count '\bcreateobject[[:space:]]*\(')
USERFORM=$(count '\busserform\b|\bform\b')
APP_ONTIME=$(count '\bapplication\.ontime\b')

# Crude complexity score
COMPLEXITY=0
COMPLEXITY=$(( COMPLEXITY + LINES / 10 ))
COMPLEXITY=$(( COMPLEXITY + (SUBS + FUNCS) * 2 ))
COMPLEXITY=$(( COMPLEXITY + ON_ERR_RESUME * 5 ))
COMPLEXITY=$(( COMPLEXITY + ON_ERR_GOTO * 3 ))
COMPLEXITY=$(( COMPLEXITY + GOTO * 5 ))
COMPLEXITY=$(( COMPLEXITY + VARIANT * 3 ))
COMPLEXITY=$(( COMPLEXITY + PUBLIC_VAR * 4 ))
COMPLEXITY=$(( COMPLEXITY + ACTIVE * 2 ))
COMPLEXITY=$(( COMPLEXITY + CREATEOBJECT * 3 ))
COMPLEXITY=$(( COMPLEXITY + USERFORM * 10 ))
COMPLEXITY=$(( COMPLEXITY + APP_ONTIME * 5 ))

if   (( COMPLEXITY < 30  )); then GRADE="S (small)"
elif (( COMPLEXITY < 80  )); then GRADE="M (medium)"
elif (( COMPLEXITY < 150 )); then GRADE="L (large)"
elif (( COMPLEXITY < 300 )); then GRADE="XL (extra large)"
else                             GRADE="XXL (consider splitting before migrating)"
fi

cat <<EOF
# vibeasfunc analysis: $FILE

## Size
- lines: $LINES
- subs: $SUBS
- functions: $FUNCS
- properties: $PROPS

## Variables
- Dim: $DIM
- Public (module-level): $PUBLIC_VAR
- as Variant: $VARIANT
- as Object: $OBJECT

## Control flow
- For loops: $FOR_LOOP
- For Each: $FOR_EACH
- Do While: $DO_WHILE
- Do Until: $DO_UNTIL
- Select Case: $SELECT_CASE
- With blocks: $WITH_BLOCK

## Error handling (the migration headache)
- On Error Resume Next: $ON_ERR_RESUME
- On Error GoTo: $ON_ERR_GOTO
- Goto: $GOTO

## Excel COM
- Cells(...): $CELLS
- Range(...): $RANGE
- Sheets(...): $SHEETS
- Active*: $ACTIVE

## External / risky
- CreateObject: $CREATEOBJECT
- UserForm references: $USERFORM
- Application.OnTime: $APP_ONTIME

## Complexity score: $COMPLEXITY
## Migration size: $GRADE

## Recommended next steps
EOF

if (( ON_ERR_RESUME + ON_ERR_GOTO > 5 )); then
  echo "- High error-handling load — read playbook/pitfalls.md (rule 3) and plan to introduce Result<T> early"
fi
if (( VARIANT > 5 )); then
  echo "- Many Variant types — read playbook/pitfalls.md (rule 2). Define discriminated unions first."
fi
if (( PUBLIC_VAR > 0 )); then
  echo "- Module-level public variables present. Plan to eliminate via parameter passing."
fi
if (( USERFORM > 0 )); then
  echo "- UserForm references found. Read playbook/pitfalls.md (rule 4) — UI needs its own architecture pass, not a console rewrite."
fi
if (( ACTIVE > 0 )); then
  echo "- ActiveSheet/ActiveCell usage. Pass sheet references explicitly during migration."
fi
if (( APP_ONTIME > 0 )); then
  echo "- Application.OnTime — consider Quartz.NET or BackgroundService instead of Task.Delay."
fi
echo "- Read SKILL.md and follow the 5-step playbook"

exit 0
