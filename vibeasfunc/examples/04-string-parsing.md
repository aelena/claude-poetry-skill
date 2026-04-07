# Example 4: VBA string surgery → pattern matching

VBA's string handling is famously verbose. Functional C# with pattern matching makes it terse and exhaustive.

## VBA original

```vb
Public Function ClassifyOrderId(ByVal id As String) As String
    Dim prefix As String
    Dim numPart As String
    Dim suffix As String

    If Len(id) < 6 Then
        ClassifyOrderId = "INVALID"
        Exit Function
    End If

    prefix = UCase(Left(id, 2))
    suffix = UCase(Right(id, 1))
    numPart = Mid(id, 3, Len(id) - 3)

    If Not IsNumeric(numPart) Then
        ClassifyOrderId = "INVALID"
        Exit Function
    End If

    If prefix = "EU" And suffix = "P" Then
        ClassifyOrderId = "Europe-Priority"
    ElseIf prefix = "EU" And suffix = "S" Then
        ClassifyOrderId = "Europe-Standard"
    ElseIf prefix = "NA" And suffix = "P" Then
        ClassifyOrderId = "NorthAm-Priority"
    ElseIf prefix = "NA" And suffix = "S" Then
        ClassifyOrderId = "NorthAm-Standard"
    ElseIf prefix = "AP" Then
        ClassifyOrderId = "AsiaPac-Any"
    Else
        ClassifyOrderId = "Other"
    End If
End Function
```

What it does: parses an order ID like `"EU1234P"` into a region+priority classification.

What's wrong:
- Slicing with `Left`/`Right`/`Mid` and 1-based indexing
- `If/ElseIf` chain that's hard to read and easy to forget a case
- Magic strings everywhere
- Returning `"INVALID"` instead of a typed failure

## Functional C# — types

```csharp
public enum Region   { Europe, NorthAmerica, AsiaPacific }
public enum Priority { Standard, Priority, Any }

public record OrderClass(Region Region, Priority Priority);
```

## Functional C# — the parser

```csharp
public static class OrderId
{
    public static Result<OrderClass, string> Classify(string id)
    {
        if (id.Length < 6)
            return new Result<OrderClass, string>.Err($"too short: {id.Length} chars");

        var prefix = id[..2].ToUpperInvariant();
        var suffix = id[^1..].ToUpperInvariant();
        var middle = id[2..^1];

        if (!middle.All(char.IsDigit))
            return new Result<OrderClass, string>.Err($"non-numeric body: '{middle}'");

        return (prefix, suffix) switch
        {
            ("EU", "P")      => Ok(Region.Europe,       Priority.Priority),
            ("EU", "S")      => Ok(Region.Europe,       Priority.Standard),
            ("NA", "P")      => Ok(Region.NorthAmerica, Priority.Priority),
            ("NA", "S")      => Ok(Region.NorthAmerica, Priority.Standard),
            ("AP", _)        => Ok(Region.AsiaPacific,  Priority.Any),
            _                => new Result<OrderClass, string>.Err($"unknown prefix/suffix: {prefix}/{suffix}")
        };

        static Result<OrderClass, string> Ok(Region r, Priority p) =>
            new Result<OrderClass, string>.Ok(new OrderClass(r, p));
    }
}
```

The tuple-pattern `switch` is the hero. Every combination is one line. Adding a new region is one new case. The compiler doesn't enforce exhaustiveness on tuple patterns of strings (they're open), but the wildcard catches everything else.

## A richer version: open generics + spans

If you want to be fancier (and your hot path needs it), you can do this with `ReadOnlySpan<char>` and avoid the substring allocations entirely:

```csharp
public static Result<OrderClass, string> Classify(ReadOnlySpan<char> id)
{
    if (id.Length < 6) return new Result<OrderClass, string>.Err($"too short: {id.Length} chars");

    Span<char> prefix = stackalloc char[2];
    id[..2].ToUpperInvariant(prefix);

    var suffixChar = char.ToUpperInvariant(id[^1]);

    var middle = id[2..^1];
    foreach (var c in middle)
        if (!char.IsDigit(c))
            return new Result<OrderClass, string>.Err("non-numeric body");

    return (prefix[0], prefix[1], suffixChar) switch
    {
        ('E', 'U', 'P') => Ok(Region.Europe,       Priority.Priority),
        ('E', 'U', 'S') => Ok(Region.Europe,       Priority.Standard),
        ('N', 'A', 'P') => Ok(Region.NorthAmerica, Priority.Priority),
        ('N', 'A', 'S') => Ok(Region.NorthAmerica, Priority.Standard),
        ('A', 'P', _)   => Ok(Region.AsiaPacific,  Priority.Any),
        _               => new Result<OrderClass, string>.Err("unknown")
    };
    // (helper Ok elided)
}
```

Zero allocations. For a former-VBA codebase, you almost never need this — the readable version is faster than the original anyway because it doesn't go through COM. Reach for spans only when profiling tells you to.

## What changed conceptually

| Concern | VBA | Functional C# |
|---|---|---|
| Slice syntax | `Left/Mid/Right` with 1-based indexing | range syntax `id[..2]`, `id[2..^1]`, `id[^1..]` |
| Case analysis | nested `If/ElseIf` | tuple-pattern `switch` expression |
| Failure | string `"INVALID"` | `Result<OrderClass, string>` (or a typed error) |
| Result type | `String` (carries success and failure) | `OrderClass` (success only) |
| Adding a new case | edit a chain, hope you cover everything | one new line in the switch |
