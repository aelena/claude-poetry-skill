# vibeasfunc

**ViBeAsFunC** — see your VBA's vibes anew, as functional C#.

A Claude Code skill that translates legacy VBA (Excel macros, Word automation, Access modules) into idiomatic functional C# (.NET 8+). Not a line-by-line transliteration — a structured rewrite that pulls business logic out of imperative loops, replaces error codes with `Result<T>` types, and pushes side effects to the boundary.

## What it produces

Given a VBA macro like this:

```vb
Public Sub BuildSummary()
    Dim i As Long, lastRow As Long
    Dim total As Currency
    lastRow = Sheets("Orders").Cells(Rows.Count, 1).End(xlUp).Row
    total = 0
    For i = 2 To lastRow
        If Sheets("Orders").Cells(i, 2).Value > 1000 Then
            total = total + Sheets("Orders").Cells(i, 2).Value
        End If
    Next i
    MsgBox "Total: " & total
End Sub
```

…it produces:

```csharp
record Order(string Customer, decimal Amount, DateOnly Date);

static class OrderAnalysis
{
    public static decimal SumLargeOrders(IEnumerable<Order> orders, decimal threshold) =>
        orders.Where(o => o.Amount > threshold).Sum(o => o.Amount);
}

// boundary
static void Main()
{
    var orders = OrdersReader.Load("input.xlsx");
    var total = OrderAnalysis.SumLargeOrders(orders, 1000m);
    Console.WriteLine($"Total: {total:C}");
}
```

The pure function (`SumLargeOrders`) is testable in 2ms with no Excel installed.

## Quick install

```bash
cp -r vibeasfunc ~/.claude/skills/vibeasfunc
```

Then in any Claude Code session, paste a VBA module or point at a `.bas` / `.cls` / `.frm` file and say:

```
/vibeasfunc translate path/to/module.bas
```

Or just describe what you have: *"convert this Excel macro to functional C#"*.

## Invocation cheatsheet

| You say | What happens |
|---|---|
| `/vibeasfunc` | Default — ask for source, analyze, propose, translate |
| `/vibeasfunc analyze path` | Run `scripts/analyze-vba.sh` and report constructs + complexity score |
| `/vibeasfunc translate path` | Translate one file following the 5-step playbook |
| `/vibeasfunc map "On Error Resume Next"` | Look up a specific construct in the playbook |
| `/vibeasfunc scaffold MyApp` | Scaffold a .NET 8 console + core + tests project |

## What's in the box

```
vibeasfunc/
├── SKILL.md
├── playbook/
│   ├── constructs.md      ← VBA → C# construct table
│   ├── patterns.md        ← functional C# patterns to introduce
│   ├── excel.md           ← Excel-specific (ClosedXML / EPPlus / COM)
│   └── pitfalls.md        ← top 10 mistakes to avoid
├── examples/
│   ├── 01-simple-loop.md       ← For loop → LINQ
│   ├── 02-error-handling.md    ← On Error → Result<T>
│   ├── 03-excel-pipeline.md    ← Full Excel macro → functional C# (hero)
│   └── 04-string-parsing.md    ← VBA string surgery → pattern matching
└── scripts/
    ├── extract-vba.sh    ← extract modules from .xlsm (best-effort, uses olevba)
    ├── analyze-vba.sh    ← count constructs, score complexity
    └── scaffold-csproj.sh ← scaffold a target .NET 8 project structure
```

## Philosophy

Don't translate code. **Translate intent.** A 200-line `Sub` is rarely 200 lines of intent — usually it's three or four small ideas mashed together. The functional rewrite is the chance to separate them.

Three rules:

1. **The pure core has no I/O.** Read once, transform purely, write once.
2. **Failures are values, not control flow.** `Result<T, Error>`, not `On Error`.
3. **State is passed, not shared.** No module-level variables, no `ActiveSheet`, no globals.

The whole skill is a structured way to apply those three rules.

## Read the playbook

The skill works without you reading anything. But if you want to understand *why* it makes the choices it does, the four `playbook/` files are short and worth the time. Start with `constructs.md` (the lookup table), then `patterns.md` (the idiomatic targets), then `pitfalls.md` (the war stories).
