# BPMN element reference

The subset of BPMN 2.0 you'll actually encounter in real diagrams. Each entry: the XML tag, what it means, and how to render it in narrative form.

## Process container

| Tag | Meaning | Narrative form |
|---|---|---|
| `bpmn:process` | The process itself; everything else nests inside | The document title; `name` attribute becomes the H1 |
| `bpmn:collaboration` | A diagram with multiple pools | Indicates multi-actor process — render as multiple sections |
| `bpmn:participant` | A pool — a top-level actor (person, role, or external system) | Top-level "Actor" or "System" |
| `bpmn:laneSet` / `bpmn:lane` | A swimlane within a pool — sub-actors / roles | "Role" within an actor |

## Tasks (units of work)

| Tag | Meaning | Narrative cue |
|---|---|---|
| `bpmn:task` | Generic task | "performs" |
| `bpmn:userTask` | A human does this in a UI | "the user [name] {action}" |
| `bpmn:serviceTask` | An automated/system action (often an API call) | "the system {action}" |
| `bpmn:sendTask` | Sends a message | "sends a {message} to {target}" |
| `bpmn:receiveTask` | Waits for a message | "waits for a {message} from {source}" |
| `bpmn:manualTask` | A non-system manual step (paperwork, physical action) | "{actor} manually {action}" |
| `bpmn:scriptTask` | Runs a script (rules engine, transformation) | "runs the script that {action}" |
| `bpmn:businessRuleTask` | Evaluates a decision table (often DMN) | "evaluates the {rule name} rules" |
| `bpmn:subProcess` | An embedded subprocess (expandable) | "executes the {sub-name} subprocess" — translate separately if non-trivial |
| `bpmn:callActivity` | Calls another process by reference | "calls the {referenced process} process" |
| `bpmn:transaction` | A subprocess with transaction semantics (compensation) | "starts the transaction; on failure, compensation runs" |

## Events (start, intermediate, end)

| Tag | Meaning | Narrative form |
|---|---|---|
| `bpmn:startEvent` | Where the process begins | "Trigger:" / "Process starts when..." |
| `bpmn:endEvent` | A terminal state | "Outcome:" / "Process ends with..." |
| `bpmn:intermediateThrowEvent` | Mid-process: throws a signal/message/escalation | "{actor} sends/raises a {type}" |
| `bpmn:intermediateCatchEvent` | Mid-process: waits for a signal/message/timer | "Wait for {trigger}" |
| `bpmn:boundaryEvent` | Attached to a task — fires on error/timer/etc. while the task runs | "If {trigger} during {task}: ..." |

### Event subtypes (modifier tags inside the event)

| Inner tag | Means | Notes |
|---|---|---|
| `bpmn:messageEventDefinition` | Message-triggered | Look for matching `bpmn:messageFlow` to see source |
| `bpmn:timerEventDefinition` | Timer-triggered | The `bpmn:timeDuration` or `bpmn:timeDate` is the schedule |
| `bpmn:errorEventDefinition` | Error caught/thrown | The `errorRef` points to a defined `bpmn:error` |
| `bpmn:escalationEventDefinition` | Escalation (non-terminating error) | Used to bubble up to a higher level without aborting |
| `bpmn:signalEventDefinition` | Signal — broadcast across processes | Like a pub/sub channel |
| `bpmn:conditionalEventDefinition` | Condition becomes true | Often a data state change |
| `bpmn:terminateEventDefinition` | Hard stop — kills all parallel branches | Render as "Process is forcibly terminated" |
| `bpmn:cancelEventDefinition` | Inside a transaction subprocess | "Transaction cancelled" |
| `bpmn:compensateEventDefinition` | Compensation handler | "Compensation handler: {action}" |

## Gateways (branching)

| Tag | Symbol | Meaning | Narrative form |
|---|---|---|---|
| `bpmn:exclusiveGateway` | X (XOR) | Take exactly one outgoing path based on a condition | "If {condition}, then {flow A}; otherwise {flow B}" |
| `bpmn:parallelGateway` | + (AND) | Take **all** outgoing paths simultaneously | "In parallel: {flow A} and {flow B}" |
| `bpmn:inclusiveGateway` | O (OR) | Take **one or more** outgoing paths based on conditions | "Take any combination of: {flow A} (if X), {flow B} (if Y)" |
| `bpmn:eventBasedGateway` | ◇ event | Wait for the first of several events | "Wait for whichever happens first: {event A}, {event B}" |
| `bpmn:complexGateway` | * | Custom branching logic | "Custom logic: {described in attached notes}" — flag as needing manual review |

A gateway is "splitting" if it has one incoming and many outgoing flows; "joining" if many incoming and one outgoing. The same tag is used for both.

## Flows

| Tag | Meaning |
|---|---|
| `bpmn:sequenceFlow` | The arrow between two elements within the same pool. Has `sourceRef` and `targetRef`. |
| `bpmn:messageFlow` | The dashed arrow between elements in **different** pools. Represents an integration / handoff. |
| `bpmn:association` | A dotted line linking a data object or annotation to an element |

A `sequenceFlow` may have a `bpmn:conditionExpression` — that's the gateway condition.

## Data

| Tag | Meaning | Narrative form |
|---|---|---|
| `bpmn:dataObject` | A document, record, or payload that flows between tasks | "Data: {name}" — include in a "Data contracts" section |
| `bpmn:dataObjectReference` | A reference to a data object at a particular point | "with the {name} attached" |
| `bpmn:dataStoreReference` | A persistent data store (DB, file system) | "writes to / reads from {store}" |
| `bpmn:dataInput` / `bpmn:dataOutput` | Inputs and outputs of a task or process | List under each task in the spec |

## Annotations

| Tag | Meaning |
|---|---|
| `bpmn:textAnnotation` | A free-text comment attached to an element | Render as a callout / note in the spec |
| `bpmn:group` | A visual group (no semantic meaning, just a frame) | Skip — purely visual |

## What to ignore

Most of `bpmndi:*` (BPMN Diagram Interchange) — these are layout coordinates. They tell you where to draw a shape, not what the shape means. Skip the entire `bpmndi:*` namespace unless you need to confirm visual ordering.
