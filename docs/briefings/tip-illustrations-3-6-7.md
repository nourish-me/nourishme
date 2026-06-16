# Briefing: tip3 / tip6 / tip7 Illustrations

Three onboarding-tip cards in `TipsScreen` are currently using placeholder
illustrations recycled from other tips. We need dedicated SVGs that match
the existing tip1 / tip2 / tip4 / tip5 visual language.

## Style anchor (existing illustrations)

The existing `tip1_de.svg`, `tip2_de.svg`, `tip4_de.svg`, `tip5_de.svg` set
the brand pattern. Match it:

- Single-color line work that reads against both paper (light) and ink
  (dark) backgrounds — the SVGs drive their stroke from `currentColor`
  (Field-Manual pine in light mode, paper in dark)
- One soft amber accent (`#C8884A`) on at most one or two shapes for warmth
- Outlined / sketched feel, not solid fills; 1.5-2px stroke width
- Hand-feeling slightly imperfect lines — not Material default-icon style
- A clear focal subject in the middle, supporting elements scattered
  around (a phone, a plate, chips, a calendar, etc.)
- Aspect ratio close to 4:3 (so the card body has room for headline +
  body text below)
- Look at `assets/illustrations/tip1_de.svg` as the canonical reference
  for stroke weight + spacing

## File format + naming

- One SVG per locale (DE + EN) per tip — the illustration may bake in a
  short label, so the strings need to flip with the app language
- Naming pattern: `tipN_{de|en}.svg`, stored under
  `assets/illustrations/`
- `currentColor` for line work; the amber accent should be the literal
  hex `#C8884A` so the existing theme-recoloring logic leaves it alone

## tip3 — "Brand autocomplete from history"

**Title (DE):** Marken-Autovervollständigung
**Title (EN):** Brand autocomplete from history

**Body (current copy, paraphrased):** when the user starts typing a brand
they've logged before, the app surfaces chips with the exact summary +
portion + macros they used last time. One tap re-logs the same meal,
skipping a parseMeal API call and reusing the value the user already
trusted.

**Visual idea:** a text input field with the cursor mid-typing a word like
"Sky..." (or a more universal placeholder), and 2-3 chip-pills below
suggesting "Skyr Vanille 150 g · 120 kcal", "Skyr natur 200 g · 130 kcal".
The chips have the star/sparkle accent in amber. The text field has the
search/typing motif.

Tip2 is also a brand-card motif; tip3 should feel related but distinct:
tip2 is about NEW brands being added (the barcode scan path), tip3 is
about RE-USING brands already in history. Maybe a small clock/history
glyph next to one of the chips to convey "from your history".

## tip6 — "Just say what you ate"

**Title (DE):** Tipp einfach in Alltagssprache
**Title (EN):** Just say what you ate

**Body (paraphrased):** the user doesn't have to write "Cappuccino 200 ml".
"Einen Cappuccino bitte" or "eine Schüssel Müsli mit Beeren" is enough.
The app figures out it's a meal, estimates a typical portion, logs it.

**Visual idea:** a speech bubble or chat-bubble shape coming out of a
person's silhouette (or just the bubble alone), containing the casual
phrase. An arrow / right-chevron leads from the bubble to a small
"plate-with-spoon" sketch on the right, conveying "this becomes a meal
entry". The arrow is the amber accent.

Don't show the structured output (no kcal/macros numbers). The point of
the tip is "you can be casual", not "the result is detailed".

## tip7 — "Tweakable in the details"

**Title (DE):** Anpassbar bis ins Detail
**Title (EN):** Tweakable in the details

**Body (paraphrased):** plenty of preferences live in Settings rather than
in the onboarding — meal rhythm, body goal with micro-protection, diet
style + avoid list, multi-supplements, favorite management. Worth a look
after the first few days.

**Visual idea:** a cog/gear in the center (NOT the default Material
settings icon — re-drawn in the same sketched style), with small icons
orbiting it that hint at the categories: a plate (meal rhythm), a target
(goal), a leaf (diet), a pill (supplement), a star (favorites). One of
the orbiting glyphs gets the amber accent.

Avoid making it look like a tech / machinery diagram — should feel like
a friendly "lots of knobs available if you want them" rather than
"complex configuration ahead".

## Delivery

- DE + EN .svg files per tip → 6 files total
- Reference the existing tip2 / tip4 SVGs to match the stroke weight,
  paper feel, and amber accent placement
- After delivery: drop the files into `assets/illustrations/` and update
  the `tips_screen.dart` _Tip entries to use the new `tipN_$assetSuffix`
  paths instead of the current placeholder reuse

## Open questions to confirm before drawing

1. The current set goes tip1 → tip5 (no tip6/tip7 SVGs yet) plus a
   recycled placeholder for the new ones. Should the file naming continue
   the integer sequence (`tip6_de.svg`, `tip7_de.svg`) or do you prefer
   semantic names? Recommendation: keep integer sequence so the screen
   code stays mechanical.
2. For tip3 the placeholder is currently tip3 itself (the brand-autocomplete
   motif) — the existing tip3 SVG is essentially correct for this tip. Do
   you want a refresh of it or is the existing fine and we only need
   tip6 + tip7? Recommendation: keep the existing tip3 SVG; only commission
   tip6 + tip7 as net-new.
