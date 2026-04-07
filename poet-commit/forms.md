# Poetic Forms Reference

All counts are **English syllables**, read naturally. Don't pad with filler words to hit a count — rewrite the line.

## Haiku — 5 / 7 / 5

Three lines, three images that pivot once. Best for **single-file, single-purpose** commits.

```
exponential dusk          (5)
the server, patient at last  (7)
counts to thirty, sleeps  (5)
```

Rules:
- One concrete image (the kigo / seasonal or technical anchor).
- One *kireji* — a turn, often a dash or colon.
- Present tense. No "I", no "we" — observe, don't narrate.

## Senryū — 5 / 7 / 5

Same shape as haiku, but **about people, not nature**. Wry, often funny. Best for **bug fixes**, especially the embarrassing kind.

```
the off-by-one bug
hiding for two release cycles
waves as it leaves
```

## Tanka — 5 / 7 / 5 / 7 / 7

Five lines. Adds an emotional pivot in lines 4–5 — the *upper* (5-7-5) sets the scene, the *lower* (7-7) reflects on it. Best for **2–4 file changes** where there's a refactor or theme.

```
the cache, evicted
keys we promised to remember
gone with the morning
we rewrite the contract twice
hoping the readers forgive
```

## Renga — chained 5-7-5 + 7-7 stanzas

Collaborative chain poem. For solo use here: write **one 5-7-5 stanza per logical concern** in the diff (group related files), then close with a single **7-7** couplet that reflects on the whole.

Best for **5+ files** or commits that touch multiple subsystems.

```
migrations advance        (5-7-5: db change)
the old column waves once
then disappears

new tests bloom in rows   (5-7-5: tests)
patient as the morning sun
green from end to end

we close the branch, exhale  (7-7: closing)
the river finds its new bed
```

Rules:
- Each upper stanza (5-7-5) anchors on one concern. Don't mix.
- The closing 7-7 should be reflective, not informational.
- Maximum 4 stanzas plus closing — longer than that, the reader leaves.

## Counting tips

- "ed" endings: usually 1 syllable (`closed` = 1, not 2). `wanted` = 2.
- Diphthongs count as one (`fire` = 1 in most readings).
- When in doubt, read it aloud and tap. If you have to *force* the rhythm, the line is wrong.
- Off by one? Rewrite. Don't add "the" or "a" as filler — that's the death of a haiku.
