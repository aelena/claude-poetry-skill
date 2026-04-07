# bpmnemonic

**bpmnemonic** — BPMN + mnemonic. Turn a BPMN 2.0 process diagram into a markdown document you can actually read, search, version-control, and feed to a language model. Generates either a technical specification (`specs.md`) or a product requirements document (`prd.md`), or both.

A Claude Code skill in the same family as `vibeasfunc` — encoding a specific source-format → target-format playbook so the translation is consistent and the gaps in the source are surfaced rather than silently invented.

## What it produces

Given a `.bpmn` file with two pools, three lanes, an exclusive gateway, and a boundary timer event, it produces something like:

```markdown
# Loan Application Processing

## 4. Main flow (happy path)

1. **Applicant** submits the application via the bank's portal.
2. **Intake Officer** receives the application.
3. **Intake Officer** pulls the credit report (system call).
4. **Underwriter** reviews credit and risk.
...

## 6. Exception flows

### 6.1 Underwriter review timeout (5 business days)

If the **Underwriter** has not completed *Review credit and risk* within 5
business days, a boundary timer event fires...

## 11. Open questions

- **What constitutes "acceptable risk"?** The gateway condition is not formalized in the diagram.
...
```

The output preserves BPMN element IDs as HTML comments so re-running the skill on an updated diagram can detect drift.

## Quick install

```bash
cp -r bpmnemonic ~/.claude/skills/bpmnemonic
```

Then in any Claude Code session, point at a `.bpmn` file:

```
/bpmnemonic spec path/to/process.bpmn
```

Or just describe what you have: *"convert this BPMN to a spec"*.

## Invocation cheatsheet

| You say | What happens |
|---|---|
| `/bpmnemonic` | Default — analyze, ask which format, generate |
| `/bpmnemonic spec path` | Generate `specs.md` |
| `/bpmnemonic prd path` | Generate `prd.md` |
| `/bpmnemonic both path` | Generate both |
| `/bpmnemonic analyze path` | Run `scripts/analyze-bpmn.sh` and report element counts + complexity |

## What's in the box

```
bpmnemonic/
├── SKILL.md
├── playbook/
│   ├── elements.md       ← BPMN element reference (tasks, events, gateways, flows)
│   ├── extraction.md     ← how to read a .bpmn XML file
│   ├── templates.md      ← target structure for specs.md and prd.md
│   └── pitfalls.md       ← top 11 mistakes when narrating a process diagram
├── examples/
│   ├── 01-approval.md    ← simple expense approval → both outputs
│   ├── 02-loan.md        ← loan process with multiple lanes → spec
│   └── 03-errors.md      ← order fulfillment with error/timer events → spec
└── scripts/
    ├── analyze-bpmn.sh   ← element counts, complexity score, recommended output format
    └── parse-bpmn.sh     ← structured extraction (xmlstarlet if available, grep fallback)
```

## Philosophy

The diagram is the source of truth. The generated docs are derivatives. Three rules:

1. **Never invent flows the diagram doesn't show.** If the gateway has no condition expression, the spec says "criteria not specified" and surfaces it as an open question.
2. **Surface gaps, don't paper over them.** Unnamed elements, missing schemas, ambiguous branches all go in the "open questions" section.
3. **Preserve element IDs as comments.** So a future re-run can diff against the previous output and tell you what changed.

The whole skill is a structured way to apply those three rules.

## Read the playbook

The skill works without you reading anything. But if you want to understand *why* it makes the choices it does, the four `playbook/` files are short and worth the time. Start with `elements.md` (the lookup table), then `extraction.md` (how to walk the XML), then `templates.md` (the output shapes), then `pitfalls.md` (what not to do).
