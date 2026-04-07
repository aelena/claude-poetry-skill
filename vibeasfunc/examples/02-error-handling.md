# Example 2: On Error → Result\<T, Error\>

Error handling is where VBA hides its sins. This is the migration pattern that pays back the most.

## VBA original

```vb
Public Function ParseCustomerCode(ByVal raw As String) As String
    On Error GoTo Handler

    If Len(raw) < 5 Then
        Err.Raise vbObjectError + 1, , "code too short"
    End If

    Dim region As String
    Dim number As Long

    region = UCase(Left(raw, 2))
    number = CLng(Mid(raw, 3))

    If number < 1 Or number > 9999 Then
        Err.Raise vbObjectError + 2, , "number out of range"
    End If

    ParseCustomerCode = region & "-" & Format(number, "0000")
    Exit Function

Handler:
    ParseCustomerCode = "INVALID:" & Err.Description
End Function
```

What it does: takes a raw customer code like `"NA1234"`, validates it, returns a normalized form like `"NA-1234"`. On any error, returns `"INVALID:..."`.

The problems:
- The success and failure types are the same (`String`), so callers can't tell them apart without parsing
- `Err.Raise` with magic numbers
- The `Handler` label is far from the code that triggers it
- A caller who forgets to check for `"INVALID:"` will silently use a bad value

## Functional C# — define an error type

```csharp
public abstract record CodeError
{
    public sealed record TooShort(int Length)            : CodeError;
    public sealed record InvalidNumberFormat(string Raw) : CodeError;
    public sealed record NumberOutOfRange(long Number)   : CodeError;
}
```

Each failure mode is its own type. Pattern matching on the result is exhaustive — the compiler will tell you if you forget a case.

## Functional C# — the parser

```csharp
public static class CustomerCode
{
    public static Result<string, CodeError> Parse(string raw)
    {
        if (raw.Length < 5)
            return new Result<string, CodeError>.Err(new CodeError.TooShort(raw.Length));

        var region = raw[..2].ToUpperInvariant();
        var rest   = raw[2..];

        if (!long.TryParse(rest, out var number))
            return new Result<string, CodeError>.Err(new CodeError.InvalidNumberFormat(rest));

        if (number is < 1 or > 9999)
            return new Result<string, CodeError>.Err(new CodeError.NumberOutOfRange(number));

        return new Result<string, CodeError>.Ok($"{region}-{number:D4}");
    }
}
```

Each early return is a typed failure. There's no `Handler` label. There's no magic error number. The success path is a straight line down the function.

## A minimal `Result<T, E>`

```csharp
public abstract record Result<T, E>
{
    public sealed record Ok(T Value)    : Result<T, E>;
    public sealed record Err(E Error)   : Result<T, E>;
}
```

Two cases. That's all you need. Use `FluentResults` or `LanguageExt` for a richer API, but understand that they're conveniences on top of this 3-line core.

## How a caller uses it

```csharp
var result = CustomerCode.Parse(input);

var message = result switch
{
    Result<string, CodeError>.Ok(var code)                                  => $"Welcome, {code}",
    Result<string, CodeError>.Err(CodeError.TooShort t)                     => $"Code must be at least 5 chars (got {t.Length})",
    Result<string, CodeError>.Err(CodeError.InvalidNumberFormat f)          => $"Invalid number portion: '{f.Raw}'",
    Result<string, CodeError>.Err(CodeError.NumberOutOfRange n)             => $"Number {n.Number} is out of range (1-9999)",
    _                                                                       => "unreachable"
};
```

The compiler won't let you forget a case. The error message is specific. Adding a new failure mode requires updating every caller — by design.

## Tests

```csharp
[Fact]
public void Parse_too_short_returns_TooShort_error()
{
    var result = CustomerCode.Parse("NA1");

    Assert.IsType<Result<string, CodeError>.Err>(result);
    var err = (Result<string, CodeError>.Err)result;
    Assert.IsType<CodeError.TooShort>(err.Error);
}

[Fact]
public void Parse_valid_returns_normalized_code()
{
    var result = CustomerCode.Parse("na42");

    Assert.IsType<Result<string, CodeError>.Ok>(result);
    var ok = (Result<string, CodeError>.Ok)result;
    Assert.Equal("NA-0042", ok.Value);
}
```

## What changed conceptually

| Concern | VBA | Functional C# |
|---|---|---|
| Failure representation | string prefix `"INVALID:..."` | typed `Result<T, Error>` |
| Failure cases | magic numbers in `Err.Raise` | sealed record hierarchy |
| Caller obligation | optional (can be ignored) | enforced by the type system |
| Error context | string description | structured fields per case |
| Refactor safety | rename a case → silent breakage | rename a case → compile error everywhere |
