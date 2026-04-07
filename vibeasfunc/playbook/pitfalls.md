# Pitfalls and how to avoid them

The mistakes that turn a clean migration into a worse codebase than the original.

## 1. Translating line-by-line

The biggest one. If your C# has the same shape as the VBA — same loop structure, same `if` nesting, same variable names — you've **transliterated**, not migrated. The point of switching languages is to switch *paradigms*. A 200-line `Sub` should usually become 4–6 small functions.

**Tell:** the C# is just as hard to read as the VBA was.
**Fix:** extract the input/output records first. Then write the pure function from the types alone, without looking at the original code. Then check whether you matched the original behavior.

## 2. Keeping `Variant` as `object`

VBA `Variant` was a type-system surrender. C# `object` is the same surrender. Translating `Variant` to `object` means you've kept the original sin.

**Tell:** `object` parameters and returns in your C# code.
**Fix:** ask "what *can* this actually be?" Usually it's two or three concrete types. Make it a discriminated union (a record hierarchy or `OneOf`) and let pattern matching handle it.

## 3. Preserving error swallowing

`On Error Resume Next` becomes `try { ... } catch { }`. Both hide failures. Both make bugs invisible.

**Tell:** any empty `catch` block in the migrated C#.
**Fix:** for *expected* failures (parse errors, missing files), return `Result<T, Error>` and let the caller decide. For *unexpected* failures (out of memory, disk full), let the exception propagate to the boundary and crash loudly.

## 4. Shoehorning UserForms into a console app

VBA UserForms are event-driven UI. Console apps are stdin/stdout. They have nothing in common. If you translate the UserForm into a series of `Console.ReadLine()` calls, you've made something nobody wants.

**Tell:** the original VBA was a UserForm, the migrated C# is a console app, and the user experience is now strictly worse.
**Fix:** flag UserForms as out of scope for this migration. They need their own architecture (Avalonia, MAUI, Blazor, Electron) and their own design pass. **Don't translate UI by reflex.**

## 5. Using `double` for money

VBA `Currency` is fixed-point and exact. .NET `double` is floating-point and approximate. Translating one to the other introduces subtle off-by-one-cent bugs that take months to surface and weeks to debug.

**Tell:** `double` anywhere near a price, total, tax, or balance.
**Fix:** `decimal` for all monetary values, no exceptions. Reserve `double` for measurements and statistics.

## 6. Losing 1-based indexing context silently

Excel cells are 1-based. .NET arrays are 0-based. The conversion happens at the boundary, and it should be obvious in the code.

**Tell:** `cells[r-1, c-1]` or `array[i+1]` scattered through pure functions.
**Fix:** convert exactly once, at the read boundary. After the read, everything is 0-based and never thinks about the original indexing.

## 7. Translating Application.OnTime to a Timer

`Application.OnTime` is Excel's "schedule a macro to run at a specific time" feature. The naive C# translation is `System.Threading.Timer` or `Task.Delay`. But the *intent* is usually "run this every N minutes when Excel is open". In a console app or service, that intent dissolves entirely — you'd use a cron job, a Windows Service with a `BackgroundService`, or a `Quartz.NET` schedule.

**Tell:** `Task.Delay` in a `while (true)` loop.
**Fix:** ask the user what the schedule was *for*. Then pick the right scheduler for the new architecture, not the closest VBA-shaped construct.

## 8. Keeping `ActiveSheet` and `ActiveCell` references

These are ambient state. They mean "whatever the user clicked last". In a console app or batch script, there is no user clicking, and these become silent bugs.

**Tell:** any reference to `Active*` after the migration.
**Fix:** every function that needs a sheet takes a sheet *parameter*. If the original macro used `ActiveSheet`, ask "which sheet is the user expected to have open?" and make that explicit.

## 9. Trusting the original macro's correctness

VBA codebases accumulate workarounds for bugs that were fixed in Excel years ago. Translate them faithfully, and you bring the workarounds forward. Nobody on the team remembers why they're there.

**Tell:** `If Application.Version >= 12 Then ...` or similar version-dependent quirks.
**Fix:** ask. If the user can't explain why a workaround is there, propose removing it and run the tests. If there are no tests, write a few first.

## 10. Skipping the test pass

The whole point of factoring out the pure core is that it's *testable*. If you finish the migration without writing a single unit test, you've left the most valuable thing on the table.

**Tell:** no test project in the new repo.
**Fix:** before declaring victory, write at least one test per pure function. Use the original VBA's behavior on representative inputs as the oracle. This catches subtle differences that linear reading misses.
