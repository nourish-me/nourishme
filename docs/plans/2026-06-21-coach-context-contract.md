# Plan: Unified coach context contract

**Fortschritt:** `90%` (Phase 1–4 fertig; Daten-Pfad am Gerät verifiziert; nur die
nachmittägliche Verhaltens-Prüfung offen)

> **Device-Verify 2026-06-22:** Per-Meal-Daten-Pfad am physischen iPhone bestätigt. Via
> temporärem Diagnose-Build (dayContext unter die Coach-Antwort gespiegelt) gesehen, dass
> der Coach die chronologische Mahlzeiten-Liste mit Uhrzeiten korrekt erhält. Diagnose-Code
> wieder entfernt, sauberer Build neu installiert. Offen bleibt nur die Verhaltens-Prüfung
> NACH 14 Uhr (sagt der Coach dann nicht mehr „Mittag steht an", wenn Mittag geloggt ist),
> da sich der 13:19-Originalzustand morgens nicht nachstellen lässt.

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

- [x] 🟩 **Phase 2: Wire the per-meal call (CRITICAL)**
  - [x] 🟩 CRITICAL: `generatePerMealResponse` gained an optional `dayContext` param;
    `coach_session_manager._runCallFor` builds it (meals + micros via the same
    `dailyIntakeFor` source as the nutrition header + supplements) and passes it. Block is
    appended to the USER message, after the cache breakpoint. analyze clean, 330 tests
    green (no regression). **Decision change vs plan:** the alarm-only micro nudge is
    KEPT, not retired — it carries the proactive "name a food for the next meal" behaviour
    + 7-day cooldown that the passive full-standing does not. Retiring it is a separate
    behaviour change; flagged, not silently bundled.
  - [x] 🟩 Cache boundary confirmed by code read: per-meal system prompt is cached
    (`cacheSystem: true`), the user message is never cached → the day-state adds only an
    uncached user-message delta, the cached prefix is untouched.
  - [x] 🟩 Verify part 1 (device 2026-06-22): the day-state block REACHES the per-meal
    coach correctly (chronological meal list + times confirmed via diagnostic mirror).
  - [ ] 🟨 Verify part 2 (afternoon): after 14:00, log a meal and confirm the coach no
    longer announces an already-eaten lunch and references configured supplements. The
    morning 13:19 state can't be reproduced before noon.

- [x] 🟩 **Phase 3: Wire the chat call onto the same builder (CRITICAL)**
  - [x] 🟩 CRITICAL: replaced `home_input._buildContext()`'s Build +35 ad-hoc micro +
    supplement blocks with the shared `CoachDayContext.build`. The micro/supplement
    rendering is byte-identical to the old code (same format + rounding), so existing chat
    output is preserved; the chat coach additionally gains the meal sequence. analyze
    clean, 330 tests green.
  - [ ] 🟥 OPEN — Verify (device/TestFlight): chat answers unchanged or improved; no
    regression in the full-micros / active-supplements output. (Same device-build block.)

- [x] 🟩 **Phase 4: Name-only supplements + hydration sources**
  - [x] 🟩 Name-only supplements: handled in the builder (Phase 1) — they already live in
    `profile.activeSupplements` with an empty values map, now rendered explicitly in BOTH
    paths. Julia's gap closed.
  - [x] 🟩 Hydration: dropped — no water tracking exists in the app (no model/provider), so
    there is no source to feed. Logged as a missing feature, not a context gap.

- [ ] 🟨 **Phase 5: Cleanup + full verify**
  - [x] 🟩 Removed the dead ad-hoc chat context-building code (the Build +35 blocks);
    `flutter analyze` clean, `flutter test` green (330).
  - [ ] 🟥 🟥 OPEN — CRITICAL final pass on device/TestFlight: representative days, coach
    recommendations coherent across both paths (next-meal, micros, supplements), no
    safety/nutrition regression. This is the one remaining gate before ship.
