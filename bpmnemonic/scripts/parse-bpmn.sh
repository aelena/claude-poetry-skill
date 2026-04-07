#!/usr/bin/env bash
# bpmnemonic: extract structured information from a .bpmn file.
#
# Usage: scripts/parse-bpmn.sh <file.bpmn>
#
# Output groups:
#   - Processes (id and name)
#   - Pools (participant id, name, processRef)
#   - Lanes (lane id, name, parent process)
#   - Tasks (id, name, type, lane)
#   - Events (id, name, kind)
#   - Gateways (id, name, type)
#   - Sequence flows (id, source, target, condition)
#   - Message flows (id, source, target)
#
# Uses xmlstarlet if available; falls back to grep+sed otherwise.

set -uo pipefail

FILE="${1:?usage: parse-bpmn.sh <file.bpmn>}"
[[ -f "$FILE" ]] || { echo "parse-bpmn: not found: $FILE" >&2; exit 2; }

if command -v xmlstarlet >/dev/null 2>&1; then
  echo "# parse-bpmn (xmlstarlet): $FILE"
  echo

  # Register namespace; tolerate variations
  NS='-N bpmn=http://www.omg.org/spec/BPMN/20100524/MODEL'

  echo "## Processes"
  xmlstarlet sel $NS -t -m "//bpmn:process" -v "concat(@id, ' | ', @name)" -n "$FILE" 2>/dev/null
  echo

  echo "## Pools"
  xmlstarlet sel $NS -t -m "//bpmn:participant" -v "concat(@id, ' | ', @name, ' -> ', @processRef)" -n "$FILE" 2>/dev/null
  echo

  echo "## Lanes"
  xmlstarlet sel $NS -t -m "//bpmn:lane" -v "concat(@id, ' | ', @name)" -n "$FILE" 2>/dev/null
  echo

  echo "## Tasks"
  for type in task userTask serviceTask sendTask receiveTask manualTask scriptTask businessRuleTask; do
    xmlstarlet sel $NS -t -m "//bpmn:$type" -v "concat('$type | ', @id, ' | ', @name)" -n "$FILE" 2>/dev/null
  done
  echo

  echo "## Events"
  for type in startEvent endEvent intermediateThrowEvent intermediateCatchEvent boundaryEvent; do
    xmlstarlet sel $NS -t -m "//bpmn:$type" -v "concat('$type | ', @id, ' | ', @name)" -n "$FILE" 2>/dev/null
  done
  echo

  echo "## Gateways"
  for type in exclusiveGateway parallelGateway inclusiveGateway eventBasedGateway complexGateway; do
    xmlstarlet sel $NS -t -m "//bpmn:$type" -v "concat('$type | ', @id, ' | ', @name)" -n "$FILE" 2>/dev/null
  done
  echo

  echo "## Sequence flows"
  xmlstarlet sel $NS -t -m "//bpmn:sequenceFlow" -v "concat(@id, ' | ', @sourceRef, ' -> ', @targetRef)" -n "$FILE" 2>/dev/null
  echo

  echo "## Message flows"
  xmlstarlet sel $NS -t -m "//bpmn:messageFlow" -v "concat(@id, ' | ', @sourceRef, ' -> ', @targetRef)" -n "$FILE" 2>/dev/null

  exit 0
fi

# Fallback: grep + sed (less precise, but no dependencies)
echo "# parse-bpmn (grep fallback — install xmlstarlet for richer output): $FILE"
echo

extract_attrs() {
  # extract id and name attributes from element lines matching $1
  local tag="$1"
  grep -oE "<(bpmn[0-9]*:)?${tag}[[:space:]][^/>]*" "$FILE" 2>/dev/null | \
    sed -E 's/.*id="([^"]*)".*name="([^"]*)".*/  \1 | \2/; s/.*id="([^"]*)"[^n]*$/  \1 | [unnamed]/' | \
    sort -u
}

echo "## Processes"
extract_attrs 'process'
echo

echo "## Pools (participants)"
extract_attrs 'participant'
echo

echo "## Lanes"
extract_attrs 'lane'
echo

echo "## Tasks"
for type in userTask serviceTask sendTask receiveTask manualTask scriptTask businessRuleTask; do
  hits=$(extract_attrs "$type")
  if [[ -n "$hits" ]]; then
    echo "### $type"
    echo "$hits"
  fi
done
echo

echo "## Events"
for type in startEvent endEvent intermediateThrowEvent intermediateCatchEvent boundaryEvent; do
  hits=$(extract_attrs "$type")
  if [[ -n "$hits" ]]; then
    echo "### $type"
    echo "$hits"
  fi
done
echo

echo "## Gateways"
for type in exclusiveGateway parallelGateway inclusiveGateway eventBasedGateway; do
  hits=$(extract_attrs "$type")
  if [[ -n "$hits" ]]; then
    echo "### $type"
    echo "$hits"
  fi
done
echo

echo "## Sequence flows (id | source -> target)"
grep -oE "<(bpmn[0-9]*:)?sequenceFlow[[:space:]][^/>]*" "$FILE" 2>/dev/null | \
  sed -E 's/.*id="([^"]*)".*sourceRef="([^"]*)".*targetRef="([^"]*)".*/  \1 | \2 -> \3/' | sort -u
echo

echo "## Message flows (id | source -> target)"
grep -oE "<(bpmn[0-9]*:)?messageFlow[[:space:]][^/>]*" "$FILE" 2>/dev/null | \
  sed -E 's/.*id="([^"]*)".*sourceRef="([^"]*)".*targetRef="([^"]*)".*/  \1 | \2 -> \3/' | sort -u

cat <<EOF >&2

(Tip: install xmlstarlet for cleaner XPath-based extraction:
  Linux:   apt install xmlstarlet
  macOS:   brew install xmlstarlet
  Windows: choco install xmlstarlet)
EOF

exit 0
