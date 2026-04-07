# Examples

## Good

### Hybrid haiku, grounded — single-file retry fix

```
fix(api): clamp retry backoff to 30s ceiling

---

exponential dusk
the server, patient at last
counts to thirty, sleeps
```

### Pure senryū — embarrassing typo fix

```
the off-by-one bug
hiding for two release cycles
waves as it leaves
```

### Hybrid tanka, grounded — three-file refactor of cache layer

```
refactor(cache): move eviction to LRU, drop TTL coupling

---

the cache, evicted
keys we promised to remember
gone with the morning
we rewrite the contract twice
hoping the readers forgive
```

### Hybrid renga, grounded — multi-subsystem migration

```
chore(db): migrate sessions table to uuid pks

---

migrations advance
the old column waves once more
then disappears

new tests bloom in rows
patient as the morning sun
green from end to end

we close the branch, exhale
the river finds its new bed
```

### Pure haiku, free — docs-only commit, --yolo picked free mode

```
margins widen out
where the cursor used to pause
a reader arrives
```

## Bad (and why)

### Padded for syllables

```
the the cache is gone        ← "the the" is filler, kills the line
we have rewritten it once
and it works fine now        ← "and it works fine now" is prose, not poem
```

Fix: rewrite, don't pad.

### Abstract and lifeless

```
code refactored well
the system is now better
quality improves
```

No image, no turn, no kigo. Could describe any commit. Useless.

### Tonally wrong

A love poem for a CVE patch. A celebration haiku for a rollback. Match the mood to the change.

### Invented technical claims (grounded mode)

If the diff only touches the retry logic, don't write about "the database forgetting" — that's a different file. Stay honest to what changed.
