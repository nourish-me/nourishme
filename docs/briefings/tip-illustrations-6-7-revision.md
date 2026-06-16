# Re-Brief: tip6 + tip7 illustrations (revision)

The first delivery rendered correctly after we patched in a `<style>`
block, but the user feedback was: **"sieht total anders aus als die
anderen Illustrationen — einfach schwarz-weiß, sehr kontrastreich."**

The visual style doesn't match tip1-tip5. Below is what we need
different in the next iteration.

## What tip1-tip5 do that tip6 + tip7 currently don't

Open `assets/illustrations/tip1_de.svg`, `tip2_de.svg`, `tip5_de.svg`
for reference. The signal they share:

1. **Multiple grouped elements, not one focal subject.** tip1 has
   the bowl PLUS a brand card with portion text PLUS chips PLUS small
   accent circles. tip2 has a barcode card PLUS a hand PLUS notes
   PLUS a bowl. tip6 currently has just stick-figure + speech bubble
   + small bowl + arrow → reads as sparse.
2. **Amber `#C8884A` accents appear in MULTIPLE places**, not only
   one or two. tip1 has the amber portion-dot, the amber chip border,
   the amber circle on the bowl. tip2 has amber on the barcode + on
   a note + on a chip. tip6 only has one amber circle + arrow → not
   enough warmth.
3. **Filled shapes use mostly `#C8884A` (amber), not `currentColor`
   (pine).** A solid pine-filled bowl reads as a dark block on the
   page. tip1's bowl is `fill="currentColor"` too — but the bowl is
   one element among many, balanced by lighter linework elsewhere.
   tip6's bowl dominates because there's nothing balancing it.
4. **The hand-drawn linework breathes.** Curves are sketchy, not
   perfect circles. Tip6's head is a perfect circle — feels icon-y
   rather than illustrated.

## tip6 — concrete changes wanted

**"Just say what you ate" / "Tipp einfach in Alltagssprache"**

Keep the speech bubble → bowl idea, but:

- **Reduce the bubble text size** from `font-size="25"` to about 18.
  The 25 px italic Newsreader is currently the most dominant element
  on the canvas and crowds out the illustration. The text should
  feel like a hand-written aside, not a billboard.
- **Add ornament inside the bubble** alongside the text: a small
  amber dot in the corner, or 1-2 sketch-strokes implying the casual
  voice — this is what makes tip1 feel finished.
- **Replace the solid pine bowl with**:
   - an outlined bowl (`stroke="currentColor"`, `fill="none"`) +
   - a few amber berry-dots inside the bowl + (3-4 small `#C8884A`
     circles)
   - or keep the fill but add a clear amber accent ON the bowl
     (matching the tip1 bowl with its amber circle).
- **Add 1-2 supporting elements scattered around the canvas** —
   examples: a small steaming spoon, a calendar tick, a quick
   side-doodle of a smiley/heart. Tip1 has scattered elements
   exactly to break up empty space.

## tip7 — concrete changes wanted

**"Tweakable in the details" / "Anpassbar bis ins Detail"**

The cog + orbiting glyphs concept works conceptually. What's missing:

- **Cog at center is too geometric/icon-like.** Re-draw with the
  same wobbly hand-sketched line weight as tip1's bowl edge or
  tip2's barcode card. Sketch imperfection, not Material Design
  default.
- **Amber accents on at least TWO of the five glyphs**, not just one.
  tip1/tip2/tip4 always have multiple amber touches scattered.
- **Add a small filled `#C8884A` element somewhere outside the cog**
  — a star, a dot, a tag — so the eye has more than one warm anchor.
- **The dashed orbit ring is too thin/faint** (opacity .42). Bring
  it up to .65 or so and use solid amber for a short section to
  signal "this connects everything."

## Style block

The SVGs were missing the `<style>` block defining `.ln`, `.am`,
`.am-fill`, `.ln-thin`, `.dash`. We patched it in:

```xml
<defs><style>
  .ln{stroke:currentColor;stroke-width:2.6;fill:none;
      stroke-linecap:round;stroke-linejoin:round}
  .ln-thin{stroke:currentColor;stroke-width:1.7;fill:none;
           stroke-linecap:round;stroke-linejoin:round}
  .am{stroke:#C8884A;stroke-width:2.6;fill:none;
      stroke-linecap:round;stroke-linejoin:round}
  .am-fill{fill:#C8884A}
  .dash{stroke-dasharray:6 4}
</style></defs>
```

Please include this in the next delivery so we don't have to patch
again.

## Reference

- `assets/illustrations/tip1_de.svg` — "Foto + Text" — best example
   of multiple elements, multiple amber accents, balanced filled +
   outline shapes
- `assets/illustrations/tip2_de.svg` — "Barcode trains brands" —
   same principle, slightly different motif
- `assets/illustrations/tip5_de.svg` — "Retro-log" — calendar +
   notebook + side elements, good "settings page" energy that tip7
   could borrow from

## Delivery

- DE + EN per tip → 4 files total
- Naming `tip6_de.svg`, `tip6_en.svg`, `tip7_de.svg`, `tip7_en.svg`
- Drop into `assets/illustrations/` (overwrites current files)
- viewBox 0 0 600 400, 600x400 dimensions like the existing set
