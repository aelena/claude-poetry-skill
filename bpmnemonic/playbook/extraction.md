# Reading a .bpmn file

A `.bpmn` file is XML. Modern tools (Camunda, Bizagi, Signavio, Activiti) emit standard BPMN 2.0 with the namespace prefix `bpmn:` (or `bpmn2:`). Some tools use the `omgdc` and `omgdi` namespaces instead of `bpmndi`. Be tolerant of both.

This file teaches you what to look for. The actual reading is done by Claude with the `Read` tool, optionally aided by `scripts/parse-bpmn.sh`.

## File shape

Every BPMN file has roughly this structure:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions
    xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
    xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
    targetNamespace="...">

  <bpmn:collaboration id="Collab_1">
    <bpmn:participant id="Pool_Customer" name="Customer" processRef="Process_Customer"/>
    <bpmn:participant id="Pool_Bank"     name="Bank"     processRef="Process_Bank"/>
    <bpmn:messageFlow id="Msg_1" sourceRef="Task_Submit" targetRef="Task_Receive"/>
  </bpmn:collaboration>

  <bpmn:process id="Process_Bank" name="Loan Application Processing">
    <bpmn:laneSet>
      <bpmn:lane id="Lane_Officer" name="Loan Officer">
        <bpmn:flowNodeRef>Task_Review</bpmn:flowNodeRef>
        <bpmn:flowNodeRef>Gateway_Decision</bpmn:flowNodeRef>
      </bpmn:lane>
      <bpmn:lane id="Lane_Manager" name="Branch Manager">
        <bpmn:flowNodeRef>Task_Approve</bpmn:flowNodeRef>
      </bpmn:lane>
    </bpmn:laneSet>

    <bpmn:startEvent id="Start_1" name="Application received"/>
    <bpmn:userTask id="Task_Review" name="Review application"/>
    <bpmn:exclusiveGateway id="Gateway_Decision" name="Approved?"/>
    <bpmn:userTask id="Task_Approve" name="Sign approval"/>
    <bpmn:endEvent id="End_Approved" name="Loan approved"/>
    <bpmn:endEvent id="End_Rejected" name="Loan rejected"/>

    <bpmn:sequenceFlow id="Flow_1" sourceRef="Start_1" targetRef="Task_Review"/>
    <bpmn:sequenceFlow id="Flow_2" sourceRef="Task_Review" targetRef="Gateway_Decision"/>
    <bpmn:sequenceFlow id="Flow_3" sourceRef="Gateway_Decision" targetRef="Task_Approve">
      <bpmn:conditionExpression>${creditScore > 700}</bpmn:conditionExpression>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="Flow_4" sourceRef="Gateway_Decision" targetRef="End_Rejected">
      <bpmn:conditionExpression>${creditScore <= 700}</bpmn:conditionExpression>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="Flow_5" sourceRef="Task_Approve" targetRef="End_Approved"/>
  </bpmn:process>

  <bpmndi:BPMNDiagram id="Diagram_1">
    <!-- visual coordinates — skip this entire region -->
  </bpmndi:BPMNDiagram>
</bpmn:definitions>
```

The `bpmn:definitions` root contains zero or more `bpmn:collaboration` (multi-pool diagrams) and one or more `bpmn:process` (the actual flows). The `bpmndi:BPMNDiagram` at the bottom is layout — ignore it for narration.

## Reading order

When generating a narrative, walk the file in this order:

1. **`bpmn:process` `name`** — the title of your output document
2. **`bpmn:participant`** (in `bpmn:collaboration`) — the top-level actors
3. **`bpmn:lane`** (inside `bpmn:laneSet`) — sub-roles per pool
4. **`bpmn:startEvent`** — find every start event; each is a possible entry point
5. **Sequence flows** — follow `sourceRef` → `targetRef`, building a graph from each start event
6. **`bpmn:endEvent`** — every terminal node; each is a possible outcome
7. **Gateways** — split points become branches; join points become merges
8. **Boundary events** — attached to a task via `attachedToRef`; these are exception paths
9. **Message flows** — cross-pool integration; collect them into an "Integrations" section

## Following a flow

Given a start event, walk like this:

```
current = startEvent
while current is not an endEvent:
    outgoing = sequenceFlows where sourceRef == current.id
    if current is a gateway:
        for each outgoing flow:
            this is an alternative path — follow each
    else:
        assert len(outgoing) == 1
        current = element with id == outgoing[0].targetRef
```

For an exclusive gateway, the **happy path** is the branch whose `bpmn:conditionExpression` is the "yes / approved / continue" semantic. The other branches are alternative or rejection flows. When ambiguous, pick the branch that leads to a `bpmn:endEvent` whose `name` contains positive words ("completed", "approved", "fulfilled"); the other branches become alternatives.

## Identifying lanes for an element

A task's lane is given by the `bpmn:flowNodeRef` listing inside a `bpmn:lane`:

```xml
<bpmn:lane id="Lane_Officer" name="Loan Officer">
  <bpmn:flowNodeRef>Task_Review</bpmn:flowNodeRef>
</bpmn:lane>
```

So `Task_Review` belongs to the "Loan Officer" lane. When narrating that task, the actor is "the Loan Officer".

If a task isn't listed in any lane (rare but possible), the actor is the pool (`bpmn:participant`). If neither, mark it as `[no actor — needs assignment]`.

## Identifying boundary events

A boundary event hangs off a task:

```xml
<bpmn:userTask id="Task_Review" name="Review application"/>
<bpmn:boundaryEvent id="Boundary_1" attachedToRef="Task_Review" cancelActivity="true">
  <bpmn:timerEventDefinition>
    <bpmn:timeDuration>PT48H</bpmn:timeDuration>
  </bpmn:timerEventDefinition>
</bpmn:boundaryEvent>
<bpmn:sequenceFlow id="Flow_Timeout" sourceRef="Boundary_1" targetRef="Task_Escalate"/>
```

Read this as: **"While the Loan Officer is reviewing the application, if 48 hours pass without completion, the task is cancelled and the flow continues to *Escalate*."**

`cancelActivity="true"` means it interrupts. `cancelActivity="false"` means the original task continues alongside the boundary handler.

## What to ignore

- Anything under `bpmndi:BPMNDiagram` — visual layout
- `bpmn:group` — purely visual grouping
- Empty `bpmn:textAnnotation` blocks — designer notes that didn't get written
- `bpmn:extensionElements` — vendor-specific extensions (Camunda, jBPM, etc.); read them if you recognize the vendor, ignore otherwise

## Vendor quirks (be tolerant)

- **Camunda** uses `camunda:*` extension elements for execution semantics. They're useful for understanding intent but not for narration.
- **Signavio** sometimes embeds documentation as `bpmn:documentation` blocks — use these as-is in the output if present.
- **Bizagi** uses non-standard `omgdi` namespace for diagrams. Same idea, different prefix.
- **Modeler.io / bpmn-js** files are clean BPMN 2.0 — easiest case.

If you see a namespace prefix you don't recognize, default to ignoring it unless the element name (after the colon) is a standard BPMN element.
