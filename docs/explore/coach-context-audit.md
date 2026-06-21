# Coach context audit (what the coach sees vs needs)

Explore artefact for the board card "Coach context audit (what the coach sees vs needs)"
(#P1, Vanessa + Julia). Problem understanding only, **no solution** (the unified context
contract is the `/create-plan` deliverable). Verified against the code on 2026-06-21.
Scope: the INPUT context passed to the coach calls only, not prompt wording, not parse
output.

## What was reported

Vanessa: the per-meal coach announced "lunch is next" at 13:19 although a salad +
Knäckebrot were already logged. Julia: the coach didn't reference her configured daily
supplement when she asked whether it was enough. Both are symptoms of the coach not
receiving the day's actual entries / supplements in its call context.

## Two call paths

- **Per-meal coach** — `generatePerMealResponse()` (`lib/services/claude_client.dart`),
  context built in `_buildPerMealUserMessageDe/En` (~:992-1105), orchestrated by
  `coach_session_manager.dart` (~:254-347).
- **Chat coach** — `chat()` (`claude_client.dart` ~:1108-1163), context built in
  `home_input.dart` `_buildContext()` (~:333-500).

## Needs / Has / Missing

**Solidly present (both paths):** current time · daily kcal target + standing · protein
target + today · diet style + restrictions · phase / profile · meal-pattern preference ·
safety warnings for the current meal.

**The gaps (where the contract leaks):**

| Data point | Per-meal coach | Chat coach | Evidence |
|---|---|---|---|
| Day's logged-meal sequence (times + what) | ✗ aggregates only | ✗ only "Anzahl Einträge", not the list | `coach_session_manager.dart:264` collects `mealsForTotal`; only aggregates (`totals.kcal/proteinG`) are passed on |
| Slot occupancy (which meal slots are filled) | ✗ inferred from the clock | ✗ inferred | prompt asks for "kcal-Split auf noch nicht geloggte Slots" (`per_meal_de.dart:24`) with no slot data |
| Micronutrient standing (full) | ⚠ only as an alarm nudge (after 14h, <70%) | ✓ full block | per-meal: `coach_session_manager.dart:151-155, 280-283`; chat: `home_input.dart:454-480` |
| Active / configured supplements | ⚠ only indirect via the micro nudge | ✓ explicit block — but name-only (unscanned) supplements are invisible to both | chat block: `home_input.dart:482-496` (emits only supplements with parsed nutrient values) |
| Hydration / water logs | ✗ missing | ✗ missing | prompt references thresholds (`per_meal_de.dart:12`) but no actual water entries reach the context |

## Systemic finding (the root)

1. **The call contract passes profile + day aggregates, not the day's meal
   sequence / occupancy.** `mealsForTotal` (`coach_session_manager.dart:264`) holds the
   list with times but is used only for the micro nudge, never passed to
   `generatePerMealResponse`. So the coach derives "next meal / what's still open" from
   the clock + remaining kcal, not from what was eaten when → **Vanessa's symptom**.
2. **The per-meal path is systematically blinder than the chat path** (micros +
   supplements only indirect vs. an explicit block). A coherence gap in its own right.
3. **Name-only / onboarding supplements** (no parsed values) never enter the
   active-supplements block → **Julia's symptom**, confirmed at the data level
   regardless of her open question.
4. **Hydration is entirely absent**, although the prompt names thresholds.

One leaky context contract, two call paths with different fill levels. The fix (a single
coach-context contract that feeds both paths the day's sequence/occupancy + full micros +
supplements + hydration) is the `/create-plan` step.

## Pattern rule / tester questions

Audit item, no single-voice rule. No new tester question needed: Julia's open question is
already out and is non-blocking for this finding (the data-level gap is confirmed either
way).
