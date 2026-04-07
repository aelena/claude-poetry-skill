#!/usr/bin/env bash
# bpmnemonic: count BPMN elements in a .bpmn file and report complexity.
#
# Usage: scripts/analyze-bpmn.sh <file.bpmn>
#
# Best-effort grep-based parser — works without xmlstarlet. For richer
# extraction (attribute values, flow following), use scripts/parse-bpmn.sh.

set -uo pipefail

FILE="${1:?usage: analyze-bpmn.sh <file.bpmn>}"
[[ -f "$FILE" ]] || { echo "analyze-bpmn: not found: $FILE" >&2; exit 2; }

# Match elements regardless of namespace prefix (bpmn:, bpmn2:, or none)
count() {
  grep -ciE "<(bpmn[0-9]*:)?$1[[:space:]>]" "$FILE" 2>/dev/null || true
}

LINES=$(wc -l < "$FILE")

PROCESSES=$(count 'process')
COLLABS=$(count 'collaboration')
PARTICIPANTS=$(count 'participant')
LANES=$(count 'lane')

# Tasks (sum of all task subtypes)
TASK=$(count 'task')
USER_TASK=$(count 'userTask')
SERVICE_TASK=$(count 'serviceTask')
SEND_TASK=$(count 'sendTask')
RECEIVE_TASK=$(count 'receiveTask')
MANUAL_TASK=$(count 'manualTask')
SCRIPT_TASK=$(count 'scriptTask')
RULE_TASK=$(count 'businessRuleTask')
SUBPROCESS=$(count 'subProcess')
CALL_ACTIVITY=$(count 'callActivity')

# Events
START=$(count 'startEvent')
END=$(count 'endEvent')
INT_THROW=$(count 'intermediateThrowEvent')
INT_CATCH=$(count 'intermediateCatchEvent')
BOUNDARY=$(count 'boundaryEvent')

# Event subtypes (modifiers)
TIMER=$(count 'timerEventDefinition')
ERROR=$(count 'errorEventDefinition')
MESSAGE=$(count 'messageEventDefinition')
ESCALATION=$(count 'escalationEventDefinition')
SIGNAL=$(count 'signalEventDefinition')
COMPENSATE=$(count 'compensateEventDefinition')

# Gateways
EXCL_GW=$(count 'exclusiveGateway')
PAR_GW=$(count 'parallelGateway')
INC_GW=$(count 'inclusiveGateway')
EVENT_GW=$(count 'eventBasedGateway')
COMPLEX_GW=$(count 'complexGateway')

# Flows
SEQ_FLOW=$(count 'sequenceFlow')
MSG_FLOW=$(count 'messageFlow')

# Data
DATA_OBJ=$(count 'dataObject')
DATA_STORE=$(count 'dataStoreReference')

# Documentation
DOCS=$(count 'documentation')

# Total tasks (subtract the generic 'task' count to avoid double counting,
# since generic 'task' substring matches userTask, serviceTask, etc.)
# Better: just sum the specific subtypes; ignore generic count.
TOTAL_TASKS=$(( USER_TASK + SERVICE_TASK + SEND_TASK + RECEIVE_TASK + MANUAL_TASK + SCRIPT_TASK + RULE_TASK ))
TOTAL_GATEWAYS=$(( EXCL_GW + PAR_GW + INC_GW + EVENT_GW + COMPLEX_GW ))
TOTAL_EVENTS=$(( START + END + INT_THROW + INT_CATCH + BOUNDARY ))

# Complexity score
COMPLEXITY=0
COMPLEXITY=$(( COMPLEXITY + TOTAL_TASKS * 2 ))
COMPLEXITY=$(( COMPLEXITY + TOTAL_GATEWAYS * 4 ))
COMPLEXITY=$(( COMPLEXITY + TOTAL_EVENTS * 2 ))
COMPLEXITY=$(( COMPLEXITY + BOUNDARY * 3 ))         # boundary events add real complexity
COMPLEXITY=$(( COMPLEXITY + MSG_FLOW * 3 ))         # cross-pool integration
COMPLEXITY=$(( COMPLEXITY + LANES * 1 ))
COMPLEXITY=$(( COMPLEXITY + PARTICIPANTS * 2 ))
COMPLEXITY=$(( COMPLEXITY + SUBPROCESS * 8 ))      # nested complexity
COMPLEXITY=$(( COMPLEXITY + CALL_ACTIVITY * 6 ))

if   (( COMPLEXITY < 20  )); then GRADE="S (small — single page)"
elif (( COMPLEXITY < 50  )); then GRADE="M (medium — multi-section spec)"
elif (( COMPLEXITY < 100 )); then GRADE="L (large — both spec and PRD recommended)"
elif (( COMPLEXITY < 200 )); then GRADE="XL (very large — translate subprocesses separately)"
else                              GRADE="XXL (consider splitting the diagram before translating)"
fi

# Recommended output format
if (( PARTICIPANTS >= 2 || MSG_FLOW > 0 || BOUNDARY > 2 )); then
  RECOMMEND="specs.md (technical depth needed)"
elif (( TOTAL_TASKS <= 6 && TOTAL_GATEWAYS <= 2 && BOUNDARY == 0 )); then
  RECOMMEND="prd.md (small enough for a feature description)"
else
  RECOMMEND="both (the spec captures detail; the PRD frames the value)"
fi

cat <<EOF
# bpmnemonic analysis: $FILE

## Size
- lines: $LINES
- processes: $PROCESSES
- collaborations: $COLLABS

## Actors
- pools (participants): $PARTICIPANTS
- lanes: $LANES

## Tasks ($TOTAL_TASKS total)
- userTask: $USER_TASK
- serviceTask: $SERVICE_TASK
- sendTask: $SEND_TASK
- receiveTask: $RECEIVE_TASK
- manualTask: $MANUAL_TASK
- scriptTask: $SCRIPT_TASK
- businessRuleTask: $RULE_TASK
- subProcess: $SUBPROCESS
- callActivity: $CALL_ACTIVITY

## Events ($TOTAL_EVENTS total)
- startEvent: $START
- endEvent: $END
- intermediateThrow: $INT_THROW
- intermediateCatch: $INT_CATCH
- boundaryEvent: $BOUNDARY

### Event subtypes
- timer: $TIMER
- error: $ERROR
- message: $MESSAGE
- escalation: $ESCALATION
- signal: $SIGNAL
- compensate: $COMPENSATE

## Gateways ($TOTAL_GATEWAYS total)
- exclusive: $EXCL_GW
- parallel: $PAR_GW
- inclusive: $INC_GW
- eventBased: $EVENT_GW
- complex: $COMPLEX_GW

## Flows
- sequenceFlow: $SEQ_FLOW
- messageFlow: $MSG_FLOW

## Data
- dataObject: $DATA_OBJ
- dataStoreReference: $DATA_STORE

## Documentation blocks
- bpmn:documentation: $DOCS

## Complexity score: $COMPLEXITY
## Translation size: $GRADE
## Recommended output: $RECOMMEND

## Notes
EOF

if (( BOUNDARY > 0 )); then
  echo "- $BOUNDARY boundary event(s) — these are exception flows; make sure they get their own section in the spec"
fi
if (( MSG_FLOW > 0 )); then
  echo "- $MSG_FLOW message flow(s) — these are integration boundaries; render in the Integration Points section, not inline in either pool's flow"
fi
if (( SUBPROCESS + CALL_ACTIVITY > 0 )); then
  echo "- $((SUBPROCESS + CALL_ACTIVITY)) subprocess/callActivity — recommend translating each separately"
fi
if (( COMPLEX_GW > 0 )); then
  echo "- complex gateway(s) found — these need manual review; the skill cannot infer their semantics"
fi
if (( DOCS > 0 )); then
  echo "- $DOCS documentation block(s) found — preserve these verbatim in the output"
fi

exit 0
