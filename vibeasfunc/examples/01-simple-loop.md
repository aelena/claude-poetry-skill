# Example 1: For loop → LINQ

The hello-world of VBA migration. A loop that filters and sums.

## VBA original

```vb
Public Function SumLargeOrders(ByVal threshold As Currency) As Currency
    Dim total As Currency
    Dim i As Long
    Dim lastRow As Long

    total = 0
    lastRow = Sheets("Orders").Cells(Rows.Count, 1).End(xlUp).Row

    For i = 2 To lastRow
        If Sheets("Orders").Cells(i, 2).Value > threshold Then
            total = total + Sheets("Orders").Cells(i, 2).Value
        End If
    Next i

    SumLargeOrders = total
End Function
```

What it does: walks every order row, sums the amounts above a threshold.

What's wrong with it (besides being VBA):
- Reads cells one at a time (slow over COM)
- Mixes I/O with business logic
- The threshold logic is buried in the loop body
- The sheet name is hardcoded inside the function
- `Currency` → `decimal` is a real concern, not a stylistic one

## Naive C# (don't do this)

```csharp
public static decimal SumLargeOrders(Worksheet sheet, decimal threshold)
{
    decimal total = 0;
    int lastRow = sheet.Cells[sheet.Rows.Count, 1].End(XlDirection.xlUp).Row;
    for (int i = 2; i <= lastRow; i++)
    {
        var amount = (decimal)sheet.Cells[i, 2].Value;
        if (amount > threshold)
            total += amount;
    }
    return total;
}
```

This is the same code wearing a different costume. The COM round-trips are still there. The pure logic is still tangled with I/O. We've gained nothing.

## Functional C# (do this)

Two pieces. The pure transformation, and the boundary glue.

### The data and the pure function

```csharp
public record Order(string Customer, decimal Amount, DateOnly Date);

public static class OrderAnalysis
{
    public static decimal SumLargeOrders(IEnumerable<Order> orders, decimal threshold) =>
        orders.Where(o => o.Amount > threshold)
              .Sum(o => o.Amount);
}
```

That's it. Two lines of logic, no Excel, fully testable.

### The boundary

```csharp
public static class OrdersReader
{
    public static IReadOnlyList<Order> Load(string path, string sheetName = "Orders")
    {
        using var workbook = new XLWorkbook(path);
        var sheet = workbook.Worksheet(sheetName);
        return sheet
            .RowsUsed()
            .Skip(1) // header
            .Select(row => new Order(
                Customer: row.Cell(1).GetString(),
                Amount:   row.Cell(2).GetValue<decimal>(),
                Date:     DateOnly.FromDateTime(row.Cell(3).GetDateTime())))
            .ToList();
    }
}

// composition root
static void Main()
{
    var orders = OrdersReader.Load("input.xlsx");
    var total  = OrderAnalysis.SumLargeOrders(orders, threshold: 1000m);
    Console.WriteLine($"Sum of large orders: {total:C}");
}
```

## What the test looks like (free!)

```csharp
[Fact]
public void SumLargeOrders_filters_below_threshold()
{
    var orders = new[]
    {
        new Order("A",  500m, new DateOnly(2026, 1, 1)),
        new Order("B", 1500m, new DateOnly(2026, 1, 2)),
        new Order("C", 2000m, new DateOnly(2026, 1, 3)),
    };

    var total = OrderAnalysis.SumLargeOrders(orders, threshold: 1000m);

    Assert.Equal(3500m, total);
}
```

No Excel. No mocks. No fixtures. The test runs in milliseconds.

## What changed conceptually

| Concern | VBA | Functional C# |
|---|---|---|
| Type for money | `Currency` (4-decimal fixed) | `decimal` (28-digit decimal) |
| Iteration | `For i = 2 To lastRow` | `.Where(...).Sum(...)` |
| Where the data lives | inside Excel cells | as `Order` records in memory |
| Threshold logic location | inside the loop body | as a `.Where` predicate |
| Testability | needs a real Excel instance | pure, runs in any test runner |
| Sheet name dependency | hardcoded | parameter, defaults documented |
