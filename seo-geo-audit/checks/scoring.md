# Scoring rubric

Each check has a **severity** that maps to a point value. Findings deduct points from a starting score of 100.

| Severity | Points deducted per finding |
|---|---|
| high     | -8  |
| medium   | -3  |
| low      | -1  |
| info     |  0  (informational only, never affects score) |

## Letter grades

| Score | Grade |
|---|---|
| 95–100 | A+ |
| 90–94  | A  |
| 85–89  | A- |
| 80–84  | B+ |
| 75–79  | B  |
| 70–74  | B- |
| 65–69  | C+ |
| 60–64  | C  |
| 55–59  | C- |
| 50–54  | D  |
| <50    | F  |

## Per-category scoring

SEO and GEO are scored **independently**. A site can have an A+ in SEO and a D in GEO, or vice versa. Don't merge them — they answer different questions.

```
SEO:  A   (92/100)  — 1 high finding, 2 medium findings
GEO:  D   (54/100)  — missing llms.txt, no JSON-LD, weak FAQ markup, walls of text
A11y: not audited (run /a11y-audit for accessibility scoring)
```

## Caps

- **Floor at 0.** Don't go negative even if findings sum past 100.
- **Cap deductions per check ID** at -16 (so a single bad pattern repeated across 50 files doesn't sink the whole score). Show the count, but cap the impact.

## What the score is *not*

The score is **a vibe check, not a contract**. It exists to give the user a quick sense of where they stand. The real value is in the individual findings and their fixes — the letter grade is just the headline. Treat it accordingly in the report: prominent but not the focus.
