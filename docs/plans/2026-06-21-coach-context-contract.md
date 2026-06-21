# Plan: Unified coach context contract

**Fortschritt:** `25%` (Phase 1 fertig: Builder + Unit-Tests grün)

> **Scope-Korrektur beim Bauen (2026-06-21):** Hydration fällt raus — Wasser/Hydration
> wird in der App nirgends getrackt (kein Modell, kein Provider), es gibt also keine
> Daten-Quelle zum Durchreichen. Das ist ein fehlendes Feature (Idea-Backlog), kein
> Kontext-Gap. Name-only-Supplements liegen bereits als `ActiveSupplement` mit leerer
> `values`-Map in `profile.activeSupplements` (supplement_setup.dart:264) — der Builder
> rendert sie explizit als „konfiguriert, keine Nährwerte hinterlegt", womit Julias
> Lücke unabhängig von ihrer offenen Rückfrage (gescannt vs. getippt) geschlossen ist.

Board card: Coach context audit (Explore) · Audit: `[[docs/explore/coach-context-audit.md]]`

## TLDR

One shared context builder feeds BOTH coach call paths (per-meal and chat) the same
structured day-state — the day's logged meals (times + summary), the full micronutrient
standing, the configured supplements (incl. name-only / onboarding), and hydration —
placed after the prompt's cache breakpoint. Fixes the per-meal coach guessing "next meal"
from the clock alone, the per-meal-vs-chat blindness asymmetry, the invisible name-only
supplements, and the absent hydration, all from one source of truth.

## Critical Decisions

- **Gewählt: Option 2 (unified CoachContext builder).** Matches the audit's goal (one
  contract, both paths), fixes every gap at once, and lets the LLM weigh the fuzzy
  slot-attribution ("was the salad the snack or lunch?") from raw day-state rather than
  hard-coding a guess.
- **Verworfen: Option 1 (minimal — only pass the meal list to per-meal).** Fixes only
  Vanessa's symptom; leaves the chat/per-meal asymmetry, name-only supplements and
  hydration, and keeps two divergent context builders.
- **Verworfen: Option 3 (precompute slot occupancy).** Pushes the slot-attribution guess
  into our code — the exact ambiguity the tester flagged; the LLM does it better from raw
  data.
- **Caching:** the day-state is volatile and goes in the USER message (already uncached),
  so the cached system/profile prefix is untouched. A step confirms the cache boundary so
  cost stays bounded (LLM-cost-audit had healthy margin).
- This touches what the coach RECOMMENDS (nutrition/safety-adjacent), so the wiring steps
  are **CRITICAL** and gated on device/TestFlight verification.

## Rollback

Additive context plumbing behind one builder. Each phase is a commit; rollback = revert.
The builder is a pure function (unit-tested); the wiring is the only behaviour change. No
data migration. Medium risk because it changes coach output — verify on device/TestFlight
before ship.

## Schritte

- [x] 🟩 **Phase 1: Shared context model + builder (pure, unit-tested)**
  - [x] 🟩 CRITICAL: `CoachDayContext.build(mealsToday, micros, microTargets, supplements,
    isDe)` pure function in `lib/services/coach_day_context.dart` emits the structured
    day-state block (chronological meals with times + summary + macros; full micro
    standing; configured supplements incl. name-only). One source of truth. (Hydration
    dropped: no data source — see scope note above.)
  - [x] 🟩 Unit tests `test/coach_day_context_test.dart` (7/7 green): chronological
    ordering, empty-day line, rawText fallback, non-zero micros only, label-scanned vs
    name-only supplement, no-data sections absent. analyze clean.

- [ ] 🟥 **Phase 2: Wire the per-meal call (CRITICAL)**
  - [ ] 🟥 🟥 CRITICAL: pass the day's meals + full micros + supplements (incl. name-only)
    + hydration into `generatePerMealResponse`; insert the builder's block in the user
    message, AFTER the cache breakpoint. Retire the per-meal "micro nudge only when in
    alarm" path in favour of the full standing.
  - [ ] 🟥 Confirm the cache boundary (system/profile prefix stays the cached prefix; the
    volatile day-state sits in the user message). Note the per-call uncached delta.
  - [ ] 🟥 Verify (device/TestFlight): the per-meal coach no longer announces an
    already-eaten meal; references configured supplements; safety/nutrition lines unchanged
    where they should be.

- [ ] 🟥 **Phase 3: Wire the chat call onto the same builder (CRITICAL)**
  - [ ] 🟥 🟥 CRITICAL: replace `home_input._buildContext()`'s ad-hoc block with the shared
    builder so both paths emit identical day-state. Keep the existing chat micros/supplements
    block behaviour as the baseline to diff against.
  - [ ] 🟥 Verify (device/TestFlight): chat answers unchanged or improved; no regression in
    the existing full-micros / active-supplements output.

- [ ] 🟥 **Phase 4: Name-only supplements + hydration sources**
  - [ ] 🟥 Ensure onboarding/name-only supplements (no parsed values) reach the builder
    (closes Julia's gap); ensure water/hydration logs feed it.
  - [ ] 🟥 Unit tests for these sources; device/TestFlight spot-check.

- [ ] 🟥 **Phase 5: Cleanup + full verify**
  - [ ] 🟥 Remove now-dead context-building code; `flutter analyze` clean, `flutter test`
    green.
  - [ ] 🟥 🟥 CRITICAL final pass: a few representative days verified on device/TestFlight
    that coach recommendations are coherent across both paths (next-meal, micros,
    supplements) with no safety/nutrition regression.
