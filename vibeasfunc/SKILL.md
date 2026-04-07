---
name: vibeasfunc
description: Translate legacy VBA (Excel macros, Word automation, Access modules) into idiomatic functional C# (.NET 8+) — replacing imperative loops with LINQ, error codes with Result types, mutable state with immutable records, and side effects pushed to the boundary. Use when the user asks to modernize VBA, convert Excel macros to C#, rewrite a Sub as a pure function, port an .xlsm to a .NET console app, or invokes /vibeasfunc, /vba2csharp.
---

# vibeasfunc

**ViBeAsFunC** — see your VBA anew, as functional C# (.NET 8+).

A modernization skill that ports legacy VBA into idiomatic functional C#. The goal is **not** a line-by-line transliteration. The goal is to extract the *intent* of a macro and re-express it in a form that:

- a future reader can understand at a glance,
- a test harness can pin down,
- and a language model can reason about without hallucinating side effects.

Functional C# (records, LINQ, pattern matching, Result types, immutable data) is the right target because it removes the two things that make VBA hard to maintain: **mutable shared state** and **error codes hidden inside Variant returns**.

## Why this exists

VBA codebases tend to share a few traits:

- One giant `Sub` that does input, transformation, and output in a single 800-line block.
- `On Error Resume Next` swallowing failures.
- `Variant` everywhere because nobody wanted to think about types.
- Module-level `Public` variables holding state across calls.
- Excel COM interop interleaved with business logic.

A direct translation to imperative C# preserves all of these problems. Functional C# is opinionated enough to **force the rewrite to factor cleanly**: pure transformation in the middle, side effects at the boundary, types everywhere.

This skill encodes the playbook.

## Invocation

| Trigger | Behavior |
|---|---|
| `/vibeasfunc` or `/vba2csharp` | Default — ask for a VBA file or pasted code, analyze it, propose a translation strategy, then translate |
| `/vibeasfunc analyze [path]` | Read VBA, report constructs found, complexity score, suggested target architecture |
| `/vibeasfunc translate <path>` | Translate one .bas / .cls / .frm / pasted block to functional C# |
| `/vibeasfunc map <construct>` | Look up a specific VBA construct in `playbook/constructs.md` (e.g. `On Error Resume Next`, `For Each`, `Variant`) |
| `/vibeasfunc scaffold <name>` | Scaffold a target .NET console project structure for the translated code |
| Natural language: "convert this VBA macro to C#", "rewrite this Sub as a pure function", "modernize this Excel automation" | Same |

### Stop / disable
Not session-based. One-shot per file.

## The translation playbook (5 steps)

This is the core method. Every translation follows it.

### Step 1: Identify the boundary

Read the VBA macro and answer:
- **What does it read?** (sheet ranges, cell values, parameters, MsgBox prompts)
- **What does it write?** (cells, files, messages, return values)
- **What pure transformation happens in between?**

The **boundary** is the imperative shell: COM interop, file I/O, user prompts. Everything else is the **functional core**.

### Step 2: Type the inputs and outputs

Define a `record` for the input and a `record` for the output (or a `Result<TOk, TError>` for fallible operations). Strong types upfront prevent the temptation to mutate.

```csharp
record InvoiceRow(string Customer, decimal Amount, DateOnly Date);
record InvoiceSummary(decimal Total, int Count, DateOnly Earliest, DateOnly Latest);
```

### Step 3: Write the pure function

A `static` method on a `static` class. **No COM. No file I/O. No mutation of inputs.** It takes the input record (or `IEnumerable<T>` of them) and returns the output record.

```csharp
public static InvoiceSummary Summarize(IReadOnlyList<InvoiceRow> rows) =>
    new(
        Total:    rows.Sum(r => r.Amount),
        Count:    rows.Count,
        Earliest: rows.Min(r => r.Date),
        Latest:   rows.Max(r => r.Date));
```

This function is testable in isolation. No Excel needed.

### Step 4: Write the boundary glue

Thin wrappers that read the inputs from Excel, call the pure function, and write the outputs back. The glue is allowed to be imperative — that's its job.

### Step 5: Replace error handling with Result types

Wherever the VBA used `On Error Resume Next` or `On Error GoTo`, the C# uses `Result<T, Error>` (from `FluentResults`, `LanguageExt`, or a hand-rolled discriminated union). Failures become first-class values, not control flow.

## Execution flow (what Claude does)

1. **Read** the VBA source. Run `scripts/analyze-vba.sh` if a file is provided to get a construct inventory.
2. **Categorize** constructs against `playbook/constructs.md` and call out anything in `playbook/pitfalls.md`.
3. **Propose architecture** — "this looks like an Excel data-pipeline macro; recommend a console app with ClosedXML for I/O and a pure transformation core". Get user confirmation before translating.
4. **Translate** following the 5-step playbook. Show the translation in chunks: types first, pure function next, boundary glue last.
5. **Annotate** every non-obvious choice with a comment explaining what the original VBA construct was and why the new shape is better.
6. **Suggest tests** for the pure function. Don't write them unless asked.

## Safety guardrails

- **Read-only by default.** Never modify the source `.xlsm` or `.bas` file. Only emit C# code.
- **Don't run extraction tools that touch the original Excel file.** If the user wants VBA extracted, recommend they export modules manually or use `olevba` from oletools (read-only).
- **Don't guess at COM behavior.** If the VBA depends on a specific Excel version's COM quirk, flag it. Don't silently translate to a `ClosedXML` call that behaves differently.
- **Don't translate `Application.OnTime`, event handlers, or UserForms** without flagging them as architecturally distinct — they need their own pattern (event-driven, MVU, Reactive) and shouldn't be jammed into a console app.
- **Preserve numeric semantics.** VBA `Currency` is fixed-point; map to `decimal`, never `double`. VBA `Date` is OLE Automation date; be explicit about timezone assumptions.
- **Flag external dependencies.** References to `Microsoft Outlook 16.0 Object Library`, `ADODB`, `Scripting.FileSystemObject` etc. — call them out and recommend modern replacements.

## Files in this skill

- `SKILL.md` — this file
- `playbook/constructs.md` — VBA → functional C# construct mapping table
- `playbook/patterns.md` — idiomatic functional C# patterns to introduce
- `playbook/excel.md` — Excel-specific guidance (COM interop vs ClosedXML/EPPlus)
- `playbook/pitfalls.md` — common mistakes when translating
- `examples/01-simple-loop.md` — For loop → LINQ
- `examples/02-error-handling.md` — On Error → Result\<T\>
- `examples/03-excel-pipeline.md` — full Excel macro → functional C# (the hero example)
- `examples/04-string-parsing.md` — VBA string surgery → pattern matching + spans
- `scripts/extract-vba.sh` — extract VBA modules from .xlsm (best-effort)
- `scripts/analyze-vba.sh` — count constructs, score complexity
- `scripts/scaffold-csproj.sh` — scaffold a .NET 8 console project for the translated code
- `README.md` — short install + quickstart
