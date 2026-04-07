# Pitfalls when narrating a process diagram

The mistakes that turn an honest translation into a misleading document.

## 1. Inventing decisions the diagram doesn't make

A gateway with no `conditionExpression` on its outgoing flows is **ambiguous by design** — the modeler hasn't decided what determines the branch yet. Don't invent one. Don't write "if the credit score is above 700" if the diagram only labels the gateway "Approved?" and the branches as "yes" / "no".

**Tell:** confident `if X > Y` conditions in the spec that aren't in the diagram.
**Fix:** write the gateway as "based on whether the application is approved" and surface "the criteria for approval are not specified in the diagram" as an open question.

## 2. Dropping unnamed elements

A `bpmn:task id="Task_42"` with no `name` attribute is *not* a step you can ignore — it's a step the modeler forgot to label. Skipping it makes the narrative wrong; the next reader has no idea something is missing.

**Tell:** the spec has fewer steps than the diagram has tasks.
**Fix:** render every unnamed element as `[unnamed task — needs label]` or `[unnamed gateway — needs label]`. Surface the count in the open questions section.

## 3. Treating `bpmn:task` as the same as `bpmn:userTask`

Generic `bpmn:task` means "we haven't decided who does this or how". User task means "a human in a UI". Service task means "an automated system call". The actor and the implementation are different. Conflating them produces a spec that says "the system does X" when X is actually a paper form.

**Fix:** preserve the task type in the narrative voice. Use the cue language from `playbook/elements.md`.

## 4. Picking the wrong happy path

When an exclusive gateway has two branches and neither label sounds clearly positive, the "happy path" is genuinely ambiguous. Don't guess.

**Tell:** the spec confidently picks a path, but the diagram could plausibly mean either.
**Fix:** when uncertain, **show both as equal main flows**. Or surface as an open question. The diagram is the source of truth — if it doesn't say which is the success case, the spec shouldn't either.

## 5. Translating subprocesses inline

A `bpmn:subProcess` with 20 elements inside is its own document. Inlining it makes the parent document unreadable.

**Tell:** the spec has nested numbered lists 5 levels deep.
**Fix:** treat each non-trivial subprocess as a separate document. Reference it from the parent. Suggest the user runs the skill on the subprocess separately.

## 6. Translating message flows as control flows

A `bpmn:messageFlow` between pools is *not* part of the sender's flow — it's an integration boundary. The sender continues; the receiver may or may not be running. Treating it as "and then the customer does X" implies synchronous handoff that may not exist.

**Fix:** keep message flows in their own "Integrations" section. Don't weave them into either pool's main flow narration.

## 7. Losing parallel-gateway semantics

A `bpmn:parallelGateway` with three outgoing flows means **all three happen, possibly concurrently**. Narrating it as "first A, then B, then C" is wrong.

**Fix:** "In parallel, the system performs A, B, and C. Once all three complete, the process continues to step N." Be explicit about the join.

## 8. Skipping boundary events because they look like noise

A boundary event hanging off a task is often the *most important* part of the process — it's the timeout, the error path, the escalation. If you only narrate the happy path, you've documented the process as if nothing ever goes wrong.

**Fix:** boundary events get their own "Exception flows" section. Every one. By name.

## 9. Treating `bpmn:documentation` as filler

Many diagrams have `bpmn:documentation` blocks attached to elements with the modeler's free-text intent. These are gold. They explain *why* a step exists, which the diagram itself can't show.

**Fix:** when present, include the documentation verbatim (or lightly edited) in the relevant section. Cite it. The modeler took the time to write it.

## 10. Generating both specs.md and prd.md identically

If your specs.md and prd.md are the same content with different headers, you've missed the point. The audiences are different. The vocabulary is different. The level of detail is different. The PRD is allowed to skip integration points; the spec is allowed to skip success metrics.

**Fix:** when generating both, write the spec first, then write the PRD as a *summary and reframing* of the spec, not a copy.

## 11. Stale document syndrome

The diagram is the source of truth. The generated docs are derivatives. The instant they diverge, the docs lie. The skill should make this hard:

- Always include the source filename and generation date in the header.
- Always preserve BPMN element IDs as HTML comments so future runs can detect drift.
- Always recommend re-running the skill after diagram changes — don't let users hand-edit the generated files unless they accept they've forked.

**Fix:** treat generated docs as compilation output. Edit the source (the .bpmn), rerun.
