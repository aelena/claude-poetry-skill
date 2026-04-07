---
name: bpmnemonic
description: Translate BPMN 2.0 process diagrams (.bpmn / .bpmn20.xml files) into readable, structured Markdown documents — either a technical spec (specs.md) for engineers or a product requirements doc (prd.md) for stakeholders, or both. Extracts actors from pools/lanes, narrates the happy path from start events through end events, captures alternative flows from gateways, and surfaces error/timer events as exception flows. Use when the user asks to convert BPMN to spec, generate PRD from a process diagram, document a workflow, or invokes /bpmnemonic, /bpmn-to-spec, /flow-to-doc.
---

# bpmnemonic

**bpmnemonic** — BPMN + mnemonic. Turn a process diagram into a document you can actually read, search, and version-control. Because nobody opens a `.bpmn` file in their editor at 2am, but everyone reads markdown.

## Why this exists

BPMN files capture rich semantics — actors, decisions, exception paths, data flows, message exchanges — but only if you have a viewer open. The instant you need to:

- discuss the process in a PR review,
- ship requirements to a contractor,
- onboard a new engineer,
- or feed the process to a language model,

…the diagram becomes a liability. You need prose. You need it to match the diagram exactly. And you don't want to write it by hand every time the diagram changes.

This skill encodes the translation from the BPMN structure to one of two markdown shapes:

- **`specs.md`** — a technical specification for engineers. Numbered steps, exhaustive flows, data contracts, acceptance criteria.
- **`prd.md`** — a product requirements document for stakeholders. Problem statement, actors, user journey, success metrics, scope.

Both are derived from the same diagram. They differ in audience, vocabulary, and which BPMN elements get emphasized.

## Invocation

| Trigger | Behavior |
|---|---|
| `/bpmnemonic` or `/bpmn-to-spec` or `/flow-to-doc` | Default — analyze the file, ask which format to generate, then generate |
| `/bpmnemonic spec [path]` | Generate `specs.md` from the BPMN file |
| `/bpmnemonic prd [path]` | Generate `prd.md` from the BPMN file |
| `/bpmnemonic both [path]` | Generate both documents |
| `/bpmnemonic analyze [path]` | Run `scripts/analyze-bpmn.sh` and report element counts + complexity |
| Natural language: "convert this BPMN to a spec", "make a PRD from this diagram", "document this workflow" | Same |

### Stop / disable
Not session-based. One-shot per file.

## The translation playbook (5 steps)

### Step 1: Parse and inventory

Read the `.bpmn` file (it's just XML). Build an inventory:

- **Process** name, id, and any documentation
- **Participants** (`bpmn:participant`) — these become "actors" or "external systems"
- **Lanes** (`bpmn:lane` inside `bpmn:laneSet`) — these become "roles" or "responsibilities"
- **Tasks** (`bpmn:task`, `bpmn:userTask`, `bpmn:serviceTask`, `bpmn:sendTask`, `bpmn:receiveTask`, `bpmn:scriptTask`, `bpmn:businessRuleTask`, `bpmn:manualTask`) — these become numbered steps
- **Events** (`bpmn:startEvent`, `bpmn:endEvent`, `bpmn:intermediateThrowEvent`, `bpmn:intermediateCatchEvent`, `bpmn:boundaryEvent`) — triggers, terminations, error catches, timeouts
- **Gateways** (`bpmn:exclusiveGateway`, `bpmn:parallelGateway`, `bpmn:inclusiveGateway`, `bpmn:eventBasedGateway`) — branching points
- **Sequence flows** (`bpmn:sequenceFlow`) — the arrows
- **Message flows** (`bpmn:messageFlow`) — cross-pool communication, integration points
- **Data objects** (`bpmn:dataObject`, `bpmn:dataObjectReference`) — documents, records, payloads
- **Subprocesses** (`bpmn:subProcess`, `bpmn:callActivity`) — nested complexity

If `scripts/analyze-bpmn.sh` is run, it produces this inventory automatically.

### Step 2: Build the linear narrative (the happy path)

Walk the sequence flows from each start event to each end event, picking the path that *doesn't* deviate at any gateway (i.e. the most-likely-success path). This is the "happy path" — it'll be the spine of both the spec and the PRD.

Format it as numbered steps. Each step names the actor (from the lane) and the action (from the task name).

### Step 3: Branch out (alternative flows)

For each gateway encountered on the happy path, the *other* branches become **alternative flows** in the spec or **edge cases** in the PRD. Number them after the main flow.

### Step 4: Catch exceptions

Boundary events (`bpmn:boundaryEvent`) attached to tasks — error events, timer events, escalation events — become **exception flows**. These are usually missing from PRDs but crucial in specs.

### Step 5: Identify cross-pool communication

Message flows between pools become **integration points**. In the spec, these are external API contracts. In the PRD, they're "this depends on" sections.

## Choosing the output format

If the user doesn't specify, ask. Otherwise, use these heuristics:

| Diagram has... | Suggest |
|---|---|
| 1 pool, mostly user tasks, < 10 elements total | **PRD** — small enough to be a feature description |
| Multiple pools, message flows, error events | **specs.md** — engineering needs the detail |
| Subprocesses or call activities | **specs.md** + recommend translating each subprocess separately |
| A "decision table" gateway (DMN) | **both** — PRD describes the rule, spec captures the table |
| When in doubt | **both** — they cite each other |

## Execution flow (what Claude does)

1. **Read** the .bpmn file (it's XML — use the Read tool, then parse mentally or via `scripts/parse-bpmn.sh`).
2. **Inventory** the elements per Step 1.
3. **Suggest format** if not specified. Get confirmation.
4. **Walk** the happy path; build the linear narrative.
5. **Identify** alternative flows (gateway branches), exception flows (boundary events), and integration points (message flows).
6. **Render** the chosen template from `playbook/templates.md`, filling in real content.
7. **Preview** to the user before writing the file. Ask confirmation.
8. **Write** to `./specs.md` and/or `./prd.md`. If a file exists, diff and confirm before overwriting.

## Safety guardrails

- **Read-only on the source.** Never modify the `.bpmn` file. Only emit markdown.
- **Preserve original IDs.** Reference BPMN element IDs as comments in the generated markdown so future updates can be cross-referenced. (`<!-- from bpmn:userTask id="UserTask_1a2b3c" -->`)
- **Never invent flows.** If the diagram doesn't show a path, don't write one. If something is ambiguous, surface it as an open question in the doc rather than guessing.
- **Don't translate DMN tables inline** unless they're trivially small. Reference them, summarize the rule, and recommend a separate decision table doc.
- **Flag missing element names.** A `bpmn:task id="Task_42"` with no `name` attribute is a diagram bug. Surface it as `[unnamed task — needs label]` in the output instead of inventing a name.
- **Never overwrite existing specs.md / prd.md without preview + confirmation.** They may contain manual additions.

## Files in this skill

- `SKILL.md` — this file
- `playbook/elements.md` — BPMN element reference (what each tag means)
- `playbook/extraction.md` — how to read a .bpmn XML file: tag names, attributes, flow following
- `playbook/templates.md` — target structure for `specs.md` and `prd.md`
- `playbook/pitfalls.md` — common mistakes when narrating a process diagram
- `examples/01-approval.md` — small expense approval flow → both outputs
- `examples/02-loan.md` — loan application with multiple lanes and gateways → spec
- `examples/03-errors.md` — order fulfillment with timer/error events → spec
- `scripts/analyze-bpmn.sh` — count BPMN elements, give complexity score
- `scripts/parse-bpmn.sh` — extract structured info from a .bpmn file (best-effort, uses xmlstarlet if available)
- `README.md` — install + quickstart
