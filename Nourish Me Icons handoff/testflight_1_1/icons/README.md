# NourishMe — Custom Icons (TestFlight 1.1)

8 icons in the Bowl-Mark language: flat-color, no stroke, max 2 colors per icon.
Base viewBox: 24×24. Scales cleanly to 48 / 72.

## Palette (Field Manual tokens, NOT hex in code)

- `pine`  #1E4A45 — primary shape
- `amber` #C8884A — accent / emphasis dot
- `plum`  #6B4554 — Food Safety only (overrides pine)

## Files

| Asset                | Use                                      |
|----------------------|------------------------------------------|
| ic_nm_pregnancy.svg  | Lebensphase = schwanger                  |
| ic_nm_nursing.svg    | Lebensphase = stillend                   |
| ic_nm_pumping.svg    | Lebensphase = pumpend                    |
| ic_nm_multiples.svg  | Mehrlinge (children_count ≥ 2)           |
| ic_nm_meal.svg       | Mahlzeit log entry, tab icon             |
| ic_nm_food_safety.svg| BfR safety surface — plum + amber        |
| ic_nm_coach.svg      | Coach hint badge — Bowl-Mark at 24px     |
| ic_nm_journal.svg    | Tagebuch / Verlauf tab                   |

## Render in Flutter

```dart
SvgPicture.asset(
  'assets/icons/ic_nm_pregnancy.svg',
  width: 24,
  // SVGs ship with concrete pine/amber fills.
  // If you want runtime token-driven recolor, switch the SVG fills to currentColor
  // and pass colorFilter: ColorFilter.mode(NMColors.pine, BlendMode.srcIn).
);
```

## PNG export

Not included in v1 — render after design approval. Suggested:
`handoff/icons/png/{name}@1x.png` (24), `@2x.png` (48), `@3x.png` (72).
