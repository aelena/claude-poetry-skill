# Excel-specific guidance

Most VBA in the wild lives inside Excel. The migration question is: **do you still need Excel installed at runtime?**

## Decide first: COM or no COM?

| You need... | Use |
|---|---|
| To read or write `.xlsx` files, no UI, no formulas evaluated at runtime | **ClosedXML** (MIT) or **EPPlus** (PolyForm Noncommercial / commercial) — pure .NET, no Excel install |
| To read or write `.xlsb` (binary) files | **ClosedXML.Excel.Binary** (limited) or fall back to COM |
| To trigger Excel's calculation engine (volatile formulas, custom functions) | **Microsoft.Office.Interop.Excel** — requires Excel installed |
| To drive Excel's UI (ribbon, dialogs) | **Microsoft.Office.Interop.Excel** — requires Excel installed |
| To run inside Excel as an add-in | **Excel-DNA** (free, modern) or **VSTO** (legacy, MS-supported) |

**Default to ClosedXML or EPPlus** unless you have a specific reason to need COM. The migration becomes dramatically simpler when Excel is just a file format, not a running process.

## The "read once, process functionally, write once" pattern

This is the core of every Excel-related migration. Stop interleaving COM calls with business logic.

### Bad (the VBA shape, kept in C#)

```csharp
// don't do this
for (int row = 2; row <= lastRow; row++)
{
    var customer = (string)sheet.Cells[row, 1].Value;
    var amount = (double)sheet.Cells[row, 2].Value;
    if (amount > 1000)
    {
        sheet.Cells[row, 3].Value = "VIP";
        total += amount;
    }
}
sheet.Cells[1, 5].Value = total;
```

Every cell access is a COM round-trip. The business rule (VIP threshold) is buried in I/O. Untestable.

### Good (functional shape)

```csharp
// 1. read everything once into typed records (boundary)
var rows = ExcelReader.LoadRows("input.xlsx");

// 2. transform purely (core)
var enriched = rows
    .Select(r => r with { Tier = r.Amount > 1000 ? "VIP" : "Standard" })
    .ToList();
var total = enriched.Sum(r => r.Amount);

// 3. write everything once (boundary)
ExcelWriter.SaveRows("output.xlsx", enriched, total);
```

Three stages, three responsibilities, three places to test. The pure transformation has no idea Excel exists.

## ClosedXML quickstart

```csharp
using ClosedXML.Excel;

// reading
using var workbook = new XLWorkbook("input.xlsx");
var sheet = workbook.Worksheet("Invoices");
var rows = sheet
    .RowsUsed()
    .Skip(1)  // header
    .Select(r => new InvoiceRow(
        Customer: r.Cell(1).GetString(),
        Amount:   r.Cell(2).GetValue<decimal>(),
        Date:     DateOnly.FromDateTime(r.Cell(3).GetDateTime())))
    .ToList();

// writing
using var output = new XLWorkbook();
var outSheet = output.Worksheets.Add("Summary");
outSheet.Cell(1, 1).Value = "Customer";
outSheet.Cell(1, 2).Value = "Total";
foreach (var (row, i) in summary.Lines.Select((l, i) => (l, i + 2)))
{
    outSheet.Cell(i, 1).Value = row.Customer;
    outSheet.Cell(i, 2).Value = row.Total;
}
output.SaveAs("output.xlsx");
```

ClosedXML handles cell types, formulas (it can write them, can't evaluate them), styles, and named ranges. It does **not** evaluate volatile or user-defined formulas — for that, you need a real Excel.

## EPPlus quickstart

EPPlus is similar to ClosedXML but a bit faster on large files and has more advanced features (pivot tables, conditional formatting). Note the license: free for non-commercial use; commercial use requires a license fee.

```csharp
using OfficeOpenXml;

ExcelPackage.LicenseContext = LicenseContext.NonCommercial; // required since v5

using var package = new ExcelPackage(new FileInfo("input.xlsx"));
var sheet = package.Workbook.Worksheets["Invoices"];
var rows = Enumerable.Range(2, sheet.Dimension.End.Row - 1)
    .Select(r => new InvoiceRow(
        Customer: sheet.Cells[r, 1].GetValue<string>(),
        Amount:   sheet.Cells[r, 2].GetValue<decimal>(),
        Date:     DateOnly.FromDateTime(sheet.Cells[r, 3].GetValue<DateTime>())))
    .ToList();
```

## COM interop (when you must)

If you genuinely need Excel running — say, to trigger an add-in's UDF that fetches market data — use `Microsoft.Office.Interop.Excel`. Two rules:

1. **Read everything in bulk.** Reading a `Range.Value` returns a `object[,]` for the whole region in one COM call. Use it. Never loop one cell at a time.
2. **Release COM objects deterministically.** Use `Marshal.ReleaseComObject` in a `finally` block, or wrap in a `using` adapter. COM leaks accumulate fast.

```csharp
// bulk read
var range = (Range)sheet.Range["A2:C1000"];
var values = (object[,])range.Value;  // ONE COM call

var rows = new List<InvoiceRow>();
for (int r = 1; r <= values.GetLength(0); r++)
{
    rows.Add(new InvoiceRow(
        Customer: (string)values[r, 1],
        Amount:   (decimal)values[r, 2],
        Date:     DateOnly.FromDateTime((DateTime)values[r, 3])
    ));
}
// values is now a plain .NET 2D array — process it functionally, no more COM.
```

## Performance gotcha: 1-based vs 0-based indexing

VBA arrays and Excel ranges are 1-based. Bulk-read COM arrays are *also* 1-based (this is unusual for .NET). Pure .NET arrays and lists are 0-based. Be deliberate at the boundary, and after that always be 0-based.

Convention: **convert at the boundary, never inside the pure core.** A 1-based offset inside `OrderTotal()` is a code smell.
