# Example 3: Full Excel macro → functional C# (the hero example)

A realistic VBA macro: read a sheet of invoices, compute per-customer totals, write a summary sheet, color the overdue rows. This is the example that shows how the playbook composes end-to-end.

## VBA original

```vb
Public Sub BuildInvoiceSummary()
    Dim wsSrc As Worksheet
    Dim wsOut As Worksheet
    Dim lastRow As Long
    Dim i As Long
    Dim customer As String
    Dim amount As Currency
    Dim invDate As Date
    Dim dict As Object
    Dim key As Variant

    Set dict = CreateObject("Scripting.Dictionary")
    Set wsSrc = ThisWorkbook.Sheets("Invoices")

    Application.ScreenUpdating = False

    lastRow = wsSrc.Cells(wsSrc.Rows.Count, 1).End(xlUp).Row

    For i = 2 To lastRow
        customer = wsSrc.Cells(i, 1).Value
        amount = wsSrc.Cells(i, 2).Value
        invDate = wsSrc.Cells(i, 3).Value

        If dict.Exists(customer) Then
            dict(customer) = dict(customer) + amount
        Else
            dict.Add customer, amount
        End If

        If invDate < DateAdd("d", -30, Now) And wsSrc.Cells(i, 4).Value <> "Paid" Then
            wsSrc.Range(wsSrc.Cells(i, 1), wsSrc.Cells(i, 4)).Interior.Color = RGB(255, 200, 200)
        End If
    Next i

    On Error Resume Next
    Application.DisplayAlerts = False
    ThisWorkbook.Sheets("Summary").Delete
    Application.DisplayAlerts = True
    On Error GoTo 0

    Set wsOut = ThisWorkbook.Sheets.Add(After:=wsSrc)
    wsOut.Name = "Summary"
    wsOut.Cells(1, 1).Value = "Customer"
    wsOut.Cells(1, 2).Value = "Total"

    Dim row As Long
    row = 2
    For Each key In dict.Keys
        wsOut.Cells(row, 1).Value = key
        wsOut.Cells(row, 2).Value = dict(key)
        row = row + 1
    Next key

    Application.ScreenUpdating = True
End Sub
```

What it does:
1. Reads invoices from the `Invoices` sheet
2. Aggregates totals per customer
3. Highlights overdue unpaid invoices in red
4. Writes a `Summary` sheet with customer totals

What's tangled:
- Reading, transforming, and writing all interleaved
- Highlighting (a UI concern) mixed with totaling (a business concern)
- Dictionary used as both accumulator and final result
- Sheet deletion via swallowed errors
- `Variant` keys, untyped throughout

## Functional C# — types

```csharp
public record InvoiceRow(string Customer, decimal Amount, DateOnly Date, bool IsPaid);

public record CustomerSummary(string Customer, decimal Total);

public record InvoiceReport(
    IReadOnlyList<CustomerSummary> Summaries,
    IReadOnlyList<int> OverdueRowIndices);
```

Three records. Each has one job. The boundaries between concerns are visible in the type signatures.

## Functional C# — the pure core

```csharp
public static class InvoiceReporting
{
    public static InvoiceReport Build(IReadOnlyList<InvoiceRow> rows, DateOnly today)
    {
        var summaries = rows
            .GroupBy(r => r.Customer)
            .Select(g => new CustomerSummary(g.Key, g.Sum(r => r.Amount)))
            .OrderBy(s => s.Customer)
            .ToList();

        var overdueCutoff = today.AddDays(-30);
        var overdueIndices = rows
            .Select((row, i) => (row, i))
            .Where(t => !t.row.IsPaid && t.row.Date < overdueCutoff)
            .Select(t => t.i)
            .ToList();

        return new InvoiceReport(summaries, overdueIndices);
    }
}
```

That's the entire business logic. **No Excel. No COM. No mutation.** It takes a list of rows and a "today" date and returns the report. You can run it in a unit test in 2ms.

Note that "today" is passed in, not read from `DateTime.Now`. Pure functions don't read the clock.

## Functional C# — the boundary

```csharp
public static class InvoiceWorkbook
{
    public static IReadOnlyList<InvoiceRow> ReadInvoices(string path)
    {
        using var wb = new XLWorkbook(path);
        var sheet = wb.Worksheet("Invoices");
        return sheet
            .RowsUsed()
            .Skip(1)
            .Select(r => new InvoiceRow(
                Customer: r.Cell(1).GetString(),
                Amount:   r.Cell(2).GetValue<decimal>(),
                Date:     DateOnly.FromDateTime(r.Cell(3).GetDateTime()),
                IsPaid:   r.Cell(4).GetString().Equals("Paid", StringComparison.OrdinalIgnoreCase)))
            .ToList();
    }

    public static void WriteReport(string path, InvoiceReport report)
    {
        using var wb = new XLWorkbook(path);
        var src = wb.Worksheet("Invoices");

        // Highlight overdue rows. Indices are 0-based from ReadInvoices,
        // so add 2 (header + 1-based ClosedXML rows).
        foreach (var i in report.OverdueRowIndices)
        {
            src.Range(src.Cell(i + 2, 1), src.Cell(i + 2, 4))
               .Style.Fill.BackgroundColor = XLColor.LightPink;
        }

        // Replace the existing summary sheet if any
        if (wb.Worksheets.TryGetWorksheet("Summary", out var existing))
            existing.Delete();
        var summarySheet = wb.Worksheets.Add("Summary");

        summarySheet.Cell(1, 1).Value = "Customer";
        summarySheet.Cell(1, 2).Value = "Total";
        foreach (var (s, i) in report.Summaries.Select((s, i) => (s, i + 2)))
        {
            summarySheet.Cell(i, 1).Value = s.Customer;
            summarySheet.Cell(i, 2).Value = s.Total;
        }

        wb.Save();
    }
}
```

Note what's *not* here: any business logic. The boundary reads, hands off, writes back. No `if amount > threshold`. No date arithmetic except for sorting cells.

## Composition root

```csharp
static void Main(string[] args)
{
    var path = args.FirstOrDefault() ?? "invoices.xlsx";

    var rows   = InvoiceWorkbook.ReadInvoices(path);
    var report = InvoiceReporting.Build(rows, today: DateOnly.FromDateTime(DateTime.Today));
    InvoiceWorkbook.WriteReport(path, report);

    Console.WriteLine($"Wrote summary for {report.Summaries.Count} customers, " +
                      $"highlighted {report.OverdueRowIndices.Count} overdue rows.");
}
```

Five lines. The whole macro, expressed as a pipeline.

## Tests on the pure core

```csharp
[Fact]
public void Build_aggregates_per_customer()
{
    var rows = new[]
    {
        new InvoiceRow("Acme",  100m, new DateOnly(2026, 1, 1), IsPaid: true),
        new InvoiceRow("Acme",  200m, new DateOnly(2026, 1, 2), IsPaid: false),
        new InvoiceRow("Globex", 50m, new DateOnly(2026, 1, 3), IsPaid: true),
    };

    var report = InvoiceReporting.Build(rows, today: new DateOnly(2026, 4, 1));

    Assert.Equal(2, report.Summaries.Count);
    Assert.Equal(300m, report.Summaries.First(s => s.Customer == "Acme").Total);
    Assert.Equal(50m,  report.Summaries.First(s => s.Customer == "Globex").Total);
}

[Fact]
public void Build_flags_unpaid_invoices_older_than_30_days()
{
    var today = new DateOnly(2026, 4, 1);
    var rows = new[]
    {
        new InvoiceRow("A",  100m, today.AddDays(-45), IsPaid: false), // overdue
        new InvoiceRow("B",  100m, today.AddDays(-45), IsPaid: true),  // paid, not overdue
        new InvoiceRow("C",  100m, today.AddDays(-15), IsPaid: false), // recent, not overdue
    };

    var report = InvoiceReporting.Build(rows, today);

    Assert.Single(report.OverdueRowIndices);
    Assert.Equal(0, report.OverdueRowIndices[0]);
}
```

Two tests cover both responsibilities in isolation. No mocks, no fixtures, no Excel.

## What changed conceptually

| Concern | VBA | Functional C# |
|---|---|---|
| Lines of business logic | mixed across ~40 lines | 12 lines, in one place |
| Mutation of accumulators | `dict(customer) = dict(customer) + amount` | `GroupBy(...).Sum(...)` |
| Time source | `Now` (hidden) | `today` parameter (explicit) |
| Sheet I/O | per-cell, in the loop | bulk read once, bulk write once |
| Highlighting | per-row, during read | post-hoc, from indices |
| Testability | needs Excel + a workbook | pure, ms-fast, no fixtures |
| Adding a new aggregation | edit the loop, hope nothing breaks | add a `.Select` to the pipeline |
