# Claude Design — Micronutrient Strip + Supplement Integration (v2)

Attached to this brief:

- 4 iOS screenshots in `screenshots/` showing the current Diary,
  Settings, and Onboarding. Read these BEFORE designing so the new
  component fits the existing layout and visual language. Specifically
  note `diary-today.png` — the AppBar already carries a kcal + macros
  toolbar at the top of the screen; the new strip must NOT live in that
  same vertical region.
- This brief, which has grown since v1 because (a) Deep Research came
  back with phase-specific defaults that were vague before, and (b)
  scope now includes supplement integration end-to-end.

If a constraint in v1 still applies, it still applies. New material is
called out as "v2 addition".

---

## 1. Context — the app today

NourishMe is an iOS nutrition coach for pregnant and lactating mothers.
Diary-style home tab: list of logged meals grouped by day, each with
kcal + macros + coach reply. Input bar at the bottom (chat style).

Brand: "Field Manual" palette — warm paper background, ink-dark text,
amber accent for the coach. Material 3 base with hand-tuned brand
tokens (`lib/theme/nourishme_colors.dart`). See screenshots for the
exact treatment.

Target user: woman, late 20s to late 30s, in pregnancy or postpartum.
Operating one-handed, distracted, often at meal moments.

---

## 2. What to design — three connected surfaces

### 2.1 The "daily micronutrient strip" (in Diary, top of today)

A horizontal strip showing **2 or 3 micronutrient donuts/rings** at the
very top of today's diary section. Lives between the existing AppBar
(which carries kcal + macros — DO NOT duplicate this) and today's
first meal entry. See `diary-today.png` for the empty vertical region
between toolbar and first meal where this lands.

Each donut shows the user's intake-so-far against today's target for
one micronutrient (e.g., Folate, Iodine, DHA). Tap → opens a detail
modal (section 2.2).

### 2.2 Detail modal (opens on donut tap)

Shows for the tapped nutrient:

- Headline value: "Folate 320 / 550 µg"
- Source label: "DGE 2025" or "EFSA AI" (see Section 5 below for
  source handling rules)
- Breakdown of which meals today contributed how much
- If the user has a daily supplement configured: the supplement
  contribution line (see Section 6 below)
- 2–3 concrete food suggestions to reach the remaining gap, generated
  by the coach
- For lactation phase: which "side" of milk-dependent vs. buffered
  this nutrient belongs to (see Section 4)
- For twins (numChildrenNursing ≥ 2 or trimester pregnancy with
  twin flag): a one-line disclaimer at the top of the modal — "Twin
  guideline data is limited; targets are extrapolated from singleton
  values. Confirm with your provider."

### 2.3 Settings sub-screen — "Micronutrients"

Reachable from the main Settings list (see `settings-main.png` for the
card pattern to mirror). Two sections:

- **Tracked nutrients**: a list of all available nutrients with toggles.
  Defaults are set per the user's phase (Section 3); user can override.
  User picks 1–3 for the always-visible diary strip; rest are tracked
  silently in the background and visible via the detail modal.
- **Daily supplement** (see Section 6 for full flow): either an empty
  state ("Add a supplement we factor in every day") or a card showing
  the currently configured supplement with edit/delete actions.

### 2.4 Onboarding step — optional Supplement (NEW v2)

Add a 6th step to the onboarding flow, BETWEEN current step 4 (Phase
Details) and current step 5 (Summary). Only shows when the user is
pregnant OR lactating (skip entirely for "neither" phase users). See
`onboarding-phase-details.png` for the visual language to match.

The step:

- Title: "Take a daily supplement?" / "Nimmst du ein tägliches Supplement?"
- Body explains why we ask (so we factor it into your daily nutrient
  totals)
- Primary CTA: "Photograph the label" (opens the photo-of-label flow
  from Section 6)
- Prominent secondary: "Skip for now" (just continues to Summary; user
  can add later from Settings or the detail modal)
- Mark this step explicitly as "optional" in the progress bar — it
  should NOT feel mandatory and should NOT block beta-tester completion

---

## 3. Top-3 default selection per phase (v2 addition, research-backed)

Defaults that the strip shows when the user hasn't customized:

| Phase | Default top-3 |
|---|---|
| Pregnancy T1 | Folate, Iodine, Vitamin D |
| Pregnancy T2 | Iron, Iodine, DHA |
| Pregnancy T3 | Iron, DHA, Iodine |
| Lactation 0–6 months | Iodine, DHA, Vitamin D |
| Lactation 6–12 months | Iodine, DHA, Iron |
| Lactation, vegan/vegetarian | B12 replaces the 3rd slot (Vitamin D in 0–6, Iron in 6–12) |

Implications for the mockup:

- The same component renders with different labels depending on phase
  AND diet profile. Make sure the donut label area handles 3–8
  character names cleanly: "Iron", "Iodine", "DHA", "B12", "Folate",
  "Vit D". German equivalents are similar length: "Eisen", "Jod",
  "DHA", "B12", "Folat", "Vit D".
- A B12-swapped slot for vegan users deserves a small visual hint
  ("diet-adapted") — your call on visual treatment.

---

## 4. Milk-dependent vs. buffered framing (v2 addition, lactation only)

In lactation mode, the detail modal of any nutrient shows which of two
semantic categories it belongs to:

- **"Reaches your baby"** (milk content responds to maternal intake):
  Iodine, DHA, B12, Vitamin D, Choline
- **"Your recovery"** (milk stays adequate at maternal expense — protect
  yourself): Iron, Folate, Calcium, Zinc

In pregnancy mode this split does NOT apply; the detail modal is one
unified section.

The visual treatment for the two categories must NOT use a different
color (keep the single-accent rule). Different micro-icons, italic
labels, or a section header is fine.

---

## 5. Choline as "awareness nutrient" (v2 addition)

Choline has no DGE reference value (EFSA AI only: 480 mg pregnancy,
520 mg lactation). It's intentionally NOT in any default top-3. When
a user manually enables it in Settings, the donut should visually
communicate "tracked but not a hard target" — e.g., dashed donut ring
instead of solid, italic label, or a tiny "i" info-tag. Whatever you
pick, it should NOT look identical to the target-backed nutrients,
because the science basis is different and we don't want to imply a
German authority recommends a specific intake.

The detail modal for choline says: "EFSA reference value — no DGE
recommendation. Frame this as a food-awareness target, not a
supplementation directive."

---

## 6. Supplement integration (v2 addition — the big new piece)

Most pregnant and lactating women in our target market take a daily
prenatal supplement (Femibion, Elevit, Orthomol, etc.). If we only
track dietary intake from logged meals, the donuts will permanently
look low ("30% folate") even when the user is actually at 100%+ —
making the tracker useless for the question "am I covered today?".

We do NOT build a country-specific supplement catalog (doesn't scale
internationally). Instead the user photographs the supplement label,
Claude Vision parses the nutrient table into structured values, and
those values are added to every day's total going forward.

### 6.1 Setup flow — first-time supplement entry

Entry points (any of these starts the same flow):

- Optional onboarding step (Section 2.4)
- "+ Add supplement" in Settings → Micronutrients (Section 2.3)
- A small banner card inside the donut detail modal ("Take a
  supplement? Add it once and we'll factor it in")

Flow:

1. Tap → camera/photo-picker (same picker the app already uses for
   meal photos)
2. User takes/picks photo of the supplement's nutrient table
3. Thinking state: 2–4 seconds while Claude parses; visual language
   matches the existing meal-parse thinking state
4. Result sheet appears with: extracted name (e.g., "Femibion 2") +
   table of parsed nutrients with values and units. User can tap any
   row to edit if Claude misread anything (parse accuracy is good but
   not perfect)
5. Confirm "Doses per day" with a stepper (default 1)
6. Save → returns to wherever the flow was started; the next render
   shows donuts including the new supplement contribution

### 6.2 Settings view — manage current supplement(s)

- Currently-saved supplement(s) as cards: name, "X doses/day", a small
  thumbnail of the photographed label, edit + delete actions
- "+ Add supplement" button to start flow 6.1 again
- For v1 assume only ONE active supplement (most users take one
  prenatal); multi-supplement is v2 post-launch

### 6.3 Donut display — how supplement appears

When a supplement is active, the donut visually communicates "includes
supplement contribution". Options to consider: small "+" badge on the
donut ring, dual-tone fill (food vs. supplement), or just a footnote in
the detail modal — pick what reads cleanest at the 60–80px donut size.

Important: do NOT hide the supplement contribution. The user should be
able to glance at the donut and trust the total.

### 6.4 Detail modal — supplement breakdown

When a supplement is active, the modal adds a row: "Of today's X µg
[nutrient], Y µg came from your [supplement name] and Z µg from food."
If no supplement is active, omit the row entirely.

### 6.5 Edge cases to mock

- User changes supplement (delete old, add new) — should be clearly
  reversible with a confirm dialog showing what gets removed from
  yesterday's totals (it doesn't, only today forward)
- Parse failed / nutrient table unreadable — fallback "Enter values
  manually" form with the standard nutrient fields
- User takes supplement only sometimes (e.g., with breakfast on
  weekdays) — out of scope for v1; default is "every day"

Don't mock: multi-supplement combination math (v2), reminder push
notifications for supplement-taking (existing meal reminders are
enough), time-of-day attribution (the app doesn't care WHEN the user
took it, only THAT they took it daily).

---

## 7. Visual constraints (carried over from v1, refined)

States to design for the strip:

1. Empty (no meal logged yet today) — donut at 0% (plus supplement
   contribution if configured, which is constant), encouraging tone, no
   scolding
2. In progress (e.g., 60% of folate target reached) — donut filled
   accordingly, label like "Folate 320/550 µg"
3. Target met (≥100%) — donut full, subtle "✓" or color shift, NOT a
   celebration animation (users open this app often, hourly
   notifications get old fast)
4. Over recommended UL (rare, only for nutrients with an upper limit
   like Iron) — donut filled but warning color, not red-panic
5. "Tracking disabled" — strip hidden entirely (no placeholder), strip
   only renders when at least one nutrient is enabled

Interactions: Tap a donut → opens the detail modal. No drag, no
long-press in v1.

Constraints:

- Max height 80px including label so it doesn't crowd the diary
- Must work in light AND dark mode (use scheme.surfaceContainer /
  scheme.onSurface tokens, not hardcoded colors except brand accents)
- Per-nutrient color: prefer ONE accent (brand amber) across all
  nutrients for consistency, with the label distinguishing them — NOT
  a different color per nutrient (would look like a fitness-app
  dashboard, wrong tone)
- Mobile touch targets ≥ 44px per Apple HIG
- DE primary, EN secondary — labels translatable
- A tiny phase indicator on the strip (e.g., monospace caption "T2" or
  "Stillzeit 6–12 Mo", ≤11pt) so it's obvious why the nutrient
  selection changes when the user updates their phase in Settings

Don't design: the chart visual for weekly trends (out of scope), a
nutrition-facts-style table of every micronutrient (Settings handles
that), reminder notifications.

---

## 8. Source labels in detail modal (v2 addition)

Each nutrient's detail modal shows the target source (DGE / EFSA / BfR
/ LactMed). For nutrients where DGE and EFSA disagree (notably Iron in
pregnancy: DGE 27 mg vs EFSA 16 mg), show both with a one-line note
that the app uses DGE as primary. Same treatment for Choline (EFSA
only, no DGE).

---

## 9. Deliverable

A single Figma frame (or equivalent) at iPhone 16 width (393pt)
showing:

- The Diary view top-section with the strip rendered, in 2–3 of the
  states from Section 7
- The detail modal for ONE example nutrient (e.g., Iodine in lactation
  mode, showing the milk-dependent framing + supplement breakdown)
- The Settings sub-screen "Micronutrients"
- The optional onboarding Supplement step
- The supplement setup result sheet (after photo parse)

Annotate spacing + token names used. Keep it consistent with the
existing app — read the attached screenshots first.
