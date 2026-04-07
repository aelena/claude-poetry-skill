# VBA → functional C# construct mapping

The big table. Each row is a VBA construct, the literal C# you'd reach for, and the **idiomatic functional C#** target.

The third column is the goal. The second column exists only to show the gap.

## Variables and types

| VBA | Naive C# | Functional C# |
|---|---|---|
| `Dim x As Integer` | `int x;` | inline at use site, `var x = ...` — no uninitialized variables |
| `Dim x As Long` | `long x;` | `int x` is fine in modern .NET (Int32 ≥ 2.1B); `long` only if needed |
| `Dim x As Double` | `double x;` | `double` for math, **never for money** |
| `Dim x As Currency` | `decimal x;` | `decimal` always — VBA Currency is 4-decimal fixed-point |
| `Dim x As String` | `string x;` | `string x` (immutable in .NET — no `StringBuilder` unless concatenating in a hot loop) |
| `Dim x As Date` | `DateTime x;` | `DateOnly` for dates without time; `DateTime` only when time matters; **always document timezone assumption** |
| `Dim x As Variant` | `object x;` | a discriminated union (`OneOf<A,B,C>`) or a record with explicit nullable fields. **Never** keep `Variant`. |
| `Dim x As Object` | `dynamic x;` | a typed interface or record. Strong types are the whole point of the migration. |
| `Dim x As Collection` | `List<T> x = new();` | `IReadOnlyList<T>` or `ImmutableList<T>` |
| `Dim x As Scripting.Dictionary` | `Dictionary<K,V> x = new();` | `IReadOnlyDictionary<K,V>` or `ImmutableDictionary<K,V>` |
| `Const PI = 3.14` | `const double PI = 3.14;` | `const` for primitives, `static readonly` for everything else |
| `Public x As Integer` (module-level) | `public static int x;` | **delete it.** Pass it as a parameter. Module-level mutable state is the enemy. |

## Procedures

| VBA | Naive C# | Functional C# |
|---|---|---|
| `Sub Foo()` | `static void Foo()` | a method that **returns** instead of mutating; if it must mutate something external, that's the boundary |
| `Sub Foo(ByVal x As Integer)` | `static void Foo(int x)` | same — `ByVal` is the C# default |
| `Sub Foo(ByRef x As Integer)` | `static void Foo(ref int x)` | **don't.** Return a new value or a tuple instead. |
| `Function Foo() As Integer` | `static int Foo()` | a `static` pure function on a `static` class |
| `Function Foo() As Variant` | `static object Foo()` | return `Result<T, Error>` or a typed record. Variant returns are how VBA hides errors. |
| `Public Sub` (module-level) | `public static void` | `public static` on a `static class` |
| `Private Sub` | `private static void` | `internal static` if used by sibling files, `private static` if not |

## Control flow

| VBA | Naive C# | Functional C# |
|---|---|---|
| `If x Then ... Else ... End If` | `if (x) { ... } else { ... }` | ternary expression `var y = x ? a : b;` when both branches produce a value |
| `Select Case x` | `switch (x) { ... }` | **switch expression** with pattern matching: `var y = x switch { 1 => "one", _ => "other" };` |
| `For i = 1 To 10` | `for (int i = 1; i <= 10; i++)` | `Enumerable.Range(1, 10).Select(i => ...)` if producing values; `foreach` if iterating over a known collection; **avoid bare `for` loops** |
| `For Each item In coll` | `foreach (var item in coll)` | LINQ: `coll.Select(...)`, `coll.Where(...)`, `coll.Aggregate(...)` |
| `Do While ... Loop` | `while (...)` | recursion, `IEnumerable<T>` with `yield`, or LINQ if the termination condition is data-driven |
| `Goto label:` | `goto label;` | **always eliminate.** Use guard clauses, early return, or recursion. |
| `Exit For` / `Exit Sub` | `break;` / `return;` | early return from a method, or `.TakeWhile()` / `.First()` in LINQ |

## Error handling

| VBA | Naive C# | Functional C# |
|---|---|---|
| `On Error Resume Next` | `try { ... } catch { }` | **Result\<T, Error\>**. Failures become values, not control flow. |
| `On Error GoTo Handler` | `try { ... } catch (Exception ex) { ... }` | `Result<T, Error>` for expected failures; `try/catch` only for *truly* exceptional things (OOM, disk full) |
| `Err.Number` / `Err.Description` | `ex.HResult` / `ex.Message` | a typed `Error` record with code + message; matched by pattern, not number |
| Returning -1 to signal error | returning -1 | return `Result<int, Error>`. Never overload return values. |

## Object construction

| VBA | Naive C# | Functional C# |
|---|---|---|
| `Set x = New Foo` | `var x = new Foo();` | a `record` constructor: `var x = new Foo("a", 1);` |
| `With x .a = 1 .b = 2 End With` | object initializer | record `with` expression: `var x2 = x with { A = 1, B = 2 };` (immutable update) |
| `Type Foo ... End Type` (UDT) | a class with public fields | a `record` (or `readonly record struct` for value semantics) |
| `Class_Initialize` | constructor | record primary constructor |

## Strings

| VBA | Naive C# | Functional C# |
|---|---|---|
| `Left(s, n)` | `s.Substring(0, n)` | `s[..n]` (range syntax) — and consider `ReadOnlySpan<char>` for hot paths |
| `Right(s, n)` | `s.Substring(s.Length - n)` | `s[^n..]` |
| `Mid(s, start, len)` | `s.Substring(start - 1, len)` | `s[(start-1)..(start-1+len)]` (mind the 1-based indexing!) |
| `InStr(s, find)` | `s.IndexOf(find) + 1` | `s.IndexOf(find)` (and accept that 0-based is correct) |
| `Replace(s, find, repl)` | `s.Replace(find, repl)` | `s.Replace(find, repl)` |
| `Split(s, ",")` | `s.Split(',')` | `s.Split(',')` (returns `string[]`); often followed by `.Select(...).ToArray()` |
| `s & t` | `s + t` | `$"{s}{t}"` (interpolation) or `string.Concat(...)` for many parts |

## Excel COM specifics

| VBA | Naive C# | Functional C# |
|---|---|---|
| `Range("A1").Value` | `worksheet.Range["A1"].Value` | **read into a record once**, process functionally, write back once |
| `Cells(r, c).Value` | `worksheet.Cells[r, c].Value` | same — bulk-read into a 2D array, then map to records |
| `Range("A1:A100").Value` (returns 2D Variant) | `(object[,])range.Value` | map to `IEnumerable<MyRecord>` immediately, then forget the array exists |
| `Application.ScreenUpdating = False` | `app.ScreenUpdating = false;` | not needed in non-COM I/O (ClosedXML, EPPlus); for COM, wrap in a `using` that restores on dispose |
| `ActiveSheet` | `app.ActiveSheet` | **never use ambient state.** Pass the worksheet explicitly. |
| `Workbooks.Open(path)` | `app.Workbooks.Open(path)` | for read-only data: prefer ClosedXML or EPPlus, no Excel install required |

## What to delete entirely

| VBA pattern | Why it goes |
|---|---|
| `Option Explicit` | C# is always explicit |
| `Option Base 1` | C# arrays are always 0-based; embrace it |
| `DoEvents` | not needed in C#; use `async/await` if you need to yield |
| `Application.Volatile` | this is an Excel UDF concept that doesn't translate |
| Module-level `Public` variables | replace with parameters or constructor injection |
| Hungarian notation (`strName`, `intCount`) | C# convention is `name`, `count` — types are visible from declarations |
