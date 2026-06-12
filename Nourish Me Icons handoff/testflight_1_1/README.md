# Handoff · NourishMe TestFlight 1.1

**For:** the engineer implementing this in the NourishMe Flutter codebase.
**From:** design pass, 20.05.2026.
**Scope:** Onboarding (5 Screens) · Empty States (4) · Custom Icons (8).

---

## About this bundle

The HTML in `mockup/` is a **design reference**, not production code. The task is to **recreate these screens in the existing Flutter codebase** using `flutter_svg`, your existing `NMColors` token class, and the established Material 3 widgets — replacing the M3-auto-generated visuals with the Field Manual palette already in `theme/colors.ts` / `nourishme_colors.dart`.

The HTML uses React because that's the mockup tool. **Do not port the React. Port the design.**

## Fidelity

**High-fidelity.** Colors, spacing, typography, and copy are final. Match them precisely. Where you see "22 pt gutter," that's a literal 22 logical pixels in Flutter at the iPhone 16e logical viewport (390×844 pt).

---

## What's in this bundle

```
testflight_1_1/
├── README.md                       — this file
├── PROMPT.md                       — copy-paste prompt for Claude Code
├── brand-tokens.css                — Field Manual palette (CSS vars)
├── brand-tokens.dart               — Field Manual palette (Flutter)
├── icons/
│   ├── README.md                   — icon usage notes
│   └── svg/                        — 8 SVG sources, 24px base
│       ├── ic_nm_pregnancy.svg
│       ├── ic_nm_nursing.svg
│       ├── ic_nm_pumping.svg
│       ├── ic_nm_multiples.svg
│       ├── ic_nm_meal.svg
│       ├── ic_nm_food_safety.svg
│       ├── ic_nm_coach.svg
│       └── ic_nm_journal.svg
└── mockup/
    ├── NourishMe TestFlight 1.1.html   — open in a browser to see all 9 screens
    └── *.jsx                            — source JSX (read for spacing/sizes)
```

---

## Design tokens (Field Manual palette)

Use the token IDs in code (`NMColors.pine`), never the hex values directly. The hex column is here for reference and for matching to mockups.

| Token        | Hex        | Use                                          |
|--------------|------------|----------------------------------------------|
| `paper`      | `#F4EFE6`  | Default background                           |
| `paperHi`    | `#FBF7EF`  | Elevated cards, fields                       |
| `surfLow`    | `#F2ECDE`  | Segmented track, ghost-chart bars            |
| `surf`       | `#EDE6D7`  | Surface fill                                 |
| `pine`       | `#1E4A45`  | Primary brand, primary CTA, headings accent  |
| `pineDeep`   | `#0F2D2A`  | Pressed pine                                 |
| `pineSoft`   | `#C6E2DC`  | Selected-tile background                     |
| `amber`      | `#C8884A`  | Accent (wordmark dot, eyebrow color, sun)    |
| `amberLight` | `#FFE0B8`  | Coach card background, multiples chip        |
| `plum`       | `#6B4554`  | Food-safety surface (only)                   |
| `moss`       | `#4B5A47`  | "Sweet spot" status, OK indicators           |
| `ink`        | `#1F1B16`  | Primary text                                 |
| `inkSoft`    | `#4F4A41`  | Secondary text                               |
| `inkMute`    | `#847E72`  | Mono labels, captions                        |
| `rule`       | `#D5CEC0`  | All borders, hairlines                       |

## Typography

| Role            | Family             | Weight / style    | Size (pt) | Notes                                            |
|-----------------|--------------------|-------------------|-----------|--------------------------------------------------|
| Display         | Newsreader         | 700 italic        | 30–64     | Letter-spacing −0.02em                           |
| Pull quote      | Newsreader         | 400 italic        | 17–21     | `text-wrap: pretty`                              |
| Body            | Inter (or SF Pro)  | 400 / 500         | 14–16     | Line-height 1.45–1.55                            |
| Eyebrow / label | JetBrains Mono     | 500               | 10.5–11   | UPPERCASE, letter-spacing 0.08em                 |
| Caption / unit  | JetBrains Mono     | 500               | 10.5–13   | Used for kcal/g/µg, BLS codes, source citations  |

---

## Screens

### Onboarding (5 screens)

All screens: iPhone 16e logical viewport **390 × 844 pt**, status bar reserved by the system, **22 pt lateral gutter** on header copy, **16 pt gutter** on inset cards.

#### 01 — Welcome
- **Purpose:** Brand entrance, single primary CTA.
- **Layout:**
  - Bowl-Mark **148 × 148 pt**, centered vertically in upper half.
  - Wordmark "NourishMe." Newsreader italic 700 · 40 pt · amber dot.
  - Tagline "Ernährung, die mitdenkt." Newsreader italic 400 · 21 pt · centered · max 280 pt wide.
  - Sub-body Inter 400 · 14.5 pt · ink-soft · centered · max 320 pt.
- **CTA:** "Los geht's" — pine fill, 14 pt radius, full width minus 22 pt gutter, 16 pt vertical padding, Inter 600 · 16 pt · white.
- **Footnote:** Mono · "Single user · läuft lokal auf deinem Gerät".

#### 02 — Lebensphase
- **Purpose:** Multi-select life phase. Multi-state (e.g. pregnant **and** nursing) is the default-supported case, not edge.
- **Layout:**
  - Eyebrow "Schritt 1 von 4" (mono, ink-mute).
  - Headline "In welcher Phase bist du gerade?" — Newsreader italic 700 · 34 pt.
  - Subhead Inter · 15 pt · ink-soft.
  - 3 horizontal cards, 12 pt gap, 16 pt radius, 1.5 pt border.
    - Card icon box: **48 × 48 pt**, 12 pt radius, surfLow bg, 28 pt icon.
    - Selected: border `pine` 1.5 pt, bg `pineSoft`, 24 pt square checkbox filled pine with white check.
  - Step dots: 5 dots, current = 18 × 6 pt pill pine, rest = 6 × 6 pt rule.
- **Icons used:** `ic_nm_pregnancy`, `ic_nm_nursing`, `ic_nm_pumping`.

#### 03 — Eckdaten
- **Purpose:** Collect height, weight, activity level for Mifflin-St-Jeor calc.
- **Layout:**
  - 2 stepper field cards (Größe, Gewicht) — paper-hi bg, 16 pt radius.
    - Value: Newsreader italic 700 · 36 pt · ink.
    - Stepper: 22 pt pill, 44 × 40 pt buttons, pine glyph, rule border.
  - 1 segmented activity selector — 4 segments, surfLow track, 4 pt padding, 9 pt segment radius.
    - Selected segment: paper-hi bg, soft shadow `0 1px 3px rgba(31,27,22,0.08)`.
    - Each segment shows label (Inter 600 13 pt) + multiplier in mono 10 pt below.
  - Privacy footnote: "Daraus berechnen wir … bleibt lokal auf deinem Gerät."

#### 04 — Kinder-Setup (conditional)
- **Purpose:** Children count + per-phase detail. **Trimester block only shown if pregnant, milk-volume slider only shown if nursing/pumping.** In multi-state, both render stacked.
- **Layout:**
  - Children counter card with pill counter; if `count >= 2`, show amber "Mehrlinge" chip beside counter (uses `ic_nm_multiples`).
  - Trimester block: 3 large radio buttons with Roman numerals I/II/III (Newsreader italic 700 · 26 pt) and SSW range hint in mono.
  - Milk-volume block: big value Newsreader italic 700 · 36 pt + "ml / Tag" mono unit + horizontal slider (0–1200 ml), pine track + 22 × 22 pt paper-hi ring thumb with 2 pt pine border.

#### 05 — Berechnung (Confirmation)
- **Purpose:** Show computed target. Anchor the tone: "Du versorgst in dieser Phase mehr als dich allein."
- **Layout:**
  - Single result card, paper-hi, 18 pt radius, 24 × 22 pt padding.
  - Big number: **Newsreader italic 700 · 64 pt · pine** · "kcal" unit in mono 14 pt beside.
  - Pull quote: Newsreader italic 400 · 17 pt · ink-soft · with bolded extras "+ 540 kcal für Stillen, + 250 kcal fürs zweite Trimester".
  - Hairline rule, then "Kritische Nährstoffe · Tagesbedarf" eyebrow.
  - 6 nutrient rows, 11 pt vertical padding, 1 pt rule between. Critical nutrients (Folsäure, Eisen, DHA) rendered in pine + bold.
- **CTAs:** "Tagebuch öffnen" (primary pine) + "Werte später anpassen" (text-only secondary).

---

### Empty States (4 screens)

Each empty state lives inside the live iOS chrome — top bar + bottom tab bar — not as a poster.

#### Heute (leer)
- Eyebrow "Donnerstag · 20. Mai" + headline "Heute".
- Dashed-border card (1 pt dashed rule) signaling "leer aber bereit".
- 88 × 88 pt rounded-square hero with `ic_nm_meal` (48 pt) centered.
- Headline "Was hast du heute gegessen?" Newsreader italic 700 · 24 pt centered.
- Body "Tipp einfach drauf los …" Newsreader 15.5 pt ink-soft.
- Notebook-style input with placeholder "Müsli mit Beeren …" + blinking 2 pt pine cursor (1.1s step-end blink).
- **No `+` button.** Input *is* the affordance.

#### Verlauf (leer)
- Headline "Der Verlauf beginnt heute."
- 88 × 88 pt hero with `ic_nm_journal`.
- Ghost chart: 7 surfLow bars (random-ish heights) + Mo–So mono labels. No values, just rhythm.

#### Favoriten (leer)
- 88 × 88 pt hero with **amber outline star** (1.7 pt stroke). Favorites are always outline-amber app-wide.
- Headline "Noch keine Favoriten."
- Body "Tippe in einer Mahlzeit auf den Stern …"
- Inline example row showing the gesture: avatar + name + small star icon trailing.

#### Food Safety (alles ok)
- Eyebrow "Food Safety · BfR".
- Headline "Sicher." (top bar) + "Alles unauffällig." (in-card).
- 88 × 88 pt hero with `ic_nm_food_safety` (plum + amber).
- 3 status rows below: moss-dot · name · timestamp · mono check label ("Quecksilber ok", "pasteurisiert ok", "< 200 mg Koffein").

---

## Icons

**8 custom icons, 24 pt base viewBox, flat-color, no stroke, max 2 colors.** SVG sources under `icons/svg/`.

| File                       | Use                                       | Colors           |
|----------------------------|-------------------------------------------|------------------|
| `ic_nm_pregnancy.svg`      | Lebensphase = schwanger                   | pine + amber     |
| `ic_nm_nursing.svg`        | Lebensphase = stillend                    | pine + amber     |
| `ic_nm_pumping.svg`        | Lebensphase = pumpend                     | pine + amber     |
| `ic_nm_multiples.svg`      | Mehrlinge (children_count ≥ 2)            | pine + amber     |
| `ic_nm_meal.svg`           | Mahlzeit log entry, "Heute" tab           | pine + amber     |
| `ic_nm_food_safety.svg`    | BfR safety surface                        | **plum** + amber |
| `ic_nm_coach.svg`          | Coach hint badge — Bowl-Mark @ 24 pt      | pine + amber     |
| `ic_nm_journal.svg`        | Tagebuch / Verlauf tab                    | pine + amber     |

### Render in Flutter

The SVGs ship with concrete pine/amber fills. For tab-bar tinting (selected/unselected states), the cleanest route is:

```dart
SvgPicture.asset(
  'assets/icons/ic_nm_pregnancy.svg',
  width: 24,
  height: 24,
)
```

If you want runtime token-driven recolor, swap the fills in the SVG sources to `currentColor` and pass `colorFilter: ColorFilter.mode(NMColors.pine, BlendMode.srcIn)`. Note that `srcIn` collapses the icon to **one** color, so two-tone tinting (pine + amber both keyed off the state) requires either keeping the SVG static or shipping a second `_selected` variant.

### Asset registration

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/icons/ic_nm_pregnancy.svg
    - assets/icons/ic_nm_nursing.svg
    - assets/icons/ic_nm_pumping.svg
    - assets/icons/ic_nm_multiples.svg
    - assets/icons/ic_nm_meal.svg
    - assets/icons/ic_nm_food_safety.svg
    - assets/icons/ic_nm_coach.svg
    - assets/icons/ic_nm_journal.svg
```

PNG 1× / 2× / 3× exports are **not included** in this v1 — Flutter renders SVGs directly via `flutter_svg`, so PNG is only needed if you want to skip the SVG dependency. If you do, ask design for the PNG render pass.

---

## Out of scope (do not implement)

Per Vanessa's brief, the following stay on Material 3 defaults for the MVP:
- Settings screens
- Detail views (meal detail, coach article — only sketched in prior pass)
- Chat UI
- Search
- Splash screens, animations, Lottie
- Marketing material, social templates

---

## Open questions before you start coding

1. **Aktivitätslevel multipliers.** Mockup uses ×1.2 / ×1.4 / ×1.6 / ×1.8 (DGE standard). Confirm these match your existing `BMRCalculator`.
2. **Number formatting.** Mockup renders kcal with German thousands-period ("2.880"). Confirm your `NumberFormat` matches.
3. **Multi-state defaults.** Phase screen shows pregnant + nursing pre-selected as a demo. In the real flow, all start unselected.
4. **Food Safety variant.** Current icon is a plum diamond with amber dot. If you'd prefer a Bowl-Mark variant (pine half-disc + plum sun) for visual consistency, design has it ready.

Ping Vanessa (or design) when you hit any of these.
