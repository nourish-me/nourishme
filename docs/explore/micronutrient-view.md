# Explore: Broader micronutrient view (beyond the 3-micro header)

Board card: Backlog, #P1, Sarah + Isabella + Celine (3 voices).
Status: **largely already shipped** (see verification). The card as written
overstates the gap. Real open surface is narrower than "build a micro overview".

## What the testers experienced (2 sentences)

Three testers wanted the fuller micronutrient picture beyond the three chips in
the diary header: Sarah and Isabella asked for "more than 3 + a dedicated tab",
Celine for a weekly aggregate (% of daily target, colour-coded) to see "what's
still missing this week". The decisive nuance is timing: Celine and Isabella
reported on builds that did not yet have the weekly overview, while Sarah
reported after it shipped and still asked for it.

## Verification: most of this already exists

The full system tracks **11 micronutrients** end to end (folate, iron, iodine,
vitamin D, DHA, B12, calcium, choline, zinc, fibre, vitamin A;
`meal_entry.dart:86-113`). The data layer already computes all of them:
`todayMicronutrientsProvider` / `focusedDayMicronutrientsProvider`
(`meal_providers.dart:168-199`), `MicronutrientTargets.allFor`
(`micronutrient_targets.dart:49-57`).

**The Trends tab (3rd bottom-nav tab, wired in `main_scaffold.dart:105` + 126-130)
already contains a weekly all-micro overview that matches Celine's request almost
exactly.** `_MicronutrientWeekCard` (`trends_screen.dart:66`, `_computeRows`
1022-1086) renders EVERY tracked micro (target > 0), split into two groups
(user-tracked first, rest below a hairline), each as a bar row showing the
**7-day average, % of target, colour-coded** (`_barColorFor(row.pct)`), tap →
detail sheet with %, avg/target, supplement contribution, and food sources
(`_openDetail` 1088-1162).

Timeline (git):
- Trends tab: shipped 2026-05-21 (commit 182205f).
- `_MicronutrientWeekCard`: shipped **Build +26**, 2026-06-16 (commit 4bdb6f7);
  alphabetical-sort refinement +29.
- Report builds: Celine +24 (before +26), Isabella v18 (long before), Sarah
  +33→35 (**after** +26).

→ **Celine's ask is fully built and she now has it (current beta +36/+37): pure
discovery.** Isabella's micro ask ("history tiles show only kcal") was separately
addressed in +36 (history tiles now show micro chips with status icons).

## The genuinely open surface (Needs / Has / Missing)

| Need | Status | Where |
| --- | --- | --- |
| Weekly all-micro overview, % of target, colour-coded | **HAS** | `_MicronutrientWeekCard`, Trends tab |
| Per-meal "which meal contributed this micro" | HAS (partial) | `micro_detail_modal.dart` per-meal breakdown; Sarah confirmed "Bei Jod sehe ich jetzt aus welcher Mahlzeit es kommt" |
| Per-COMPONENT breakdown ("oats vs walnuts") | MISSING | separate card "Component granularity per meal" — NOT this card |
| **More than 3 micros in the DAILY diary header** | **MISSING (capped)** | header itself has no limit (`nutrition_header.dart:391` loops all keys); cap is the Settings selector: `settings_screen.dart:908` `next.length < 3`, `:2446` `>= 3`, `:2477` "3 / 3" |
| **More than 3 micros in history day tiles** | **MISSING (same cap)** | `history_screen.dart:117-141` renders `selectedMicronutrients` (capped at 3) |
| **A per-DAY full-micro view (today's all 11)** | **MISSING** | Trends card is a 7-day average only; no surface shows today's complete micro set |
| Discoverability of the existing weekly overview | **WEAK** | Sarah on +33-35 had it and still asked → not being found |

Systemic finding: the only hard "3" in the codebase is the **Settings selector
cap** (`settings_screen.dart:908`), which limits how many micros a user can pin.
The diary header and history tiles render whatever is selected with no count
limit of their own (`nutrition_header.dart:391`, the Explore confirmed the
widgets "just adapt to more keys"). So "more than 3 in the daily view" is gated
by one constant, not a layout rewrite. What does NOT exist anywhere is a per-day
*complete* micro view (all 11 for today); Trends answers the weekly question, not
the daily one.

## Pattern rule

3 voices, so this clears the single-voice "collect, don't build" bar. BUT the
verification shows the bulk is already shipped, so the actionable remainder is
small and partly a discovery problem (like multi-photo and favourites turned out
to be). Before any build, confirm whether Sarah's need is the daily header cap /
a daily full view, or simply not having found the Trends weekly card.

## One investigative question (needs Vanessa's approval before sending)

Only Sarah is unresolved (Celine = discovery, Isabella = addressed in +36). One
question, strictly investigative, to tell discovery from a real daily-view gap:

> Hey Sarah, kurze Rückfrage zu deinem Wunsch nach mehr Nährwerten als den drei
> oben: In welchem Moment schaust du auf die Nährwerte, und was genau willst du
> da sehen, wenn du nachsiehst, der heutige komplette Stand, oder eher wie die
> Woche insgesamt lief? Und wo schaust du heute zuerst, wenn du das wissen
> willst?

(No solution, no feature name, no promise. Asks where she looks + what she wants
to see, which separates "didn't find the Trends tab" from "wants today's full
picture in the diary".)

## Process note: Claude Design einbinden?

Not yet, and probably only partially. Reasoning:
- The data layer is fully done; the visual language for micros already exists
  (`MiniPctCell`, `NutrientCell`, `_MicroBarRow`, `micro_detail_modal`). A new
  surface would largely reuse these, not invent a look.
- The cheapest lever (raise/remove the Settings 3-cap so header + history show
  more) is a constraint change, not a design problem, the widgets already scale.
- A design pass only earns its keep IF the plan decides to build a NEW dedicated
  *daily* full-micro surface (how to show 11 nutrients without overwhelming:
  grouping, progressive disclosure). Even then it is one moderate screen, not a
  multi-screen redesign.
→ Recommendation: decide the route in /create-plan first. Pull in Claude Design
only if that route is "new daily full-micro screen", and scope the handoff to
that single surface.

Next step after Sarah's answer: /create-plan (route decision: discovery nudge +
raise the cap vs. new daily full-micro surface).
