# Save + Display Flow Audit

Beta-feedback request (#46): Vanessa noticed inconsistencies in how the diary
behaves after a save. This is a systematic walk through every save path,
documenting the actual current behavior across 6 dimensions, plus a list of
inconsistencies the audit found that should be fixed.

Each "use case" below describes one path the code takes from "user taps
save" to "modal pops + diary updates". A consistent app would have similar
behavior across these dimensions for similar use cases; the goal is to spot
where reality diverges from that.

---

## The 9 use cases

1. **Live new today, now-time**: text/photo/barcode standalone save. `createdAt = now`.
2. **Live new today, backdated time within today**: user picks an earlier time today via the time picker. `createdAt = today, earlier`.
3. **Past-day backfill via empty-day-tap**: tap an empty day in the diary → `PastDayInputSheet` → save. `createdAt = picked day @ picked time`.
4. **Past-day backfill via calendar/Verlauf**: pick date via calendar → input → save. Same code path as 3.
5. **Edit existing meal, no time change**: tap meal → edit quantity/macros → save. `existingMealId` set, `createdAt` unchanged.
6. **Edit existing meal, time change same day**: change time within the same day.
7. **Edit existing meal, time change crosses day boundary**: rare, e.g. 23:30 yesterday → 00:30 today.
8. **Bundle intermediate save**: barcode/photo/text in a chained scan-session (`+ Noch einen scannen`), `fireCoach=false`.
9. **Bundle final save**: last step in chain, `fireCoach=true`, drains bundle into one coach call.

## The 6 behavior dimensions

A. **Meal persistence**: where the `MealEntry` lands.
B. **ThreadItem creation**: what gets appended to `thread` box.
C. **Coach call**: which mechanism fires the per-meal reply.
D. **Thinking-bubble visualization**: where the user sees "Coach is thinking".
E. **Post-save auto-scroll**: where the diary scrolls.
F. **Loading-state cleanup**: how the spinner resets to idle.

---

## Behavior matrix

| UC | A. Persist | B. ThreadItem | C. Coach trigger | D. Bubble | E. Auto-scroll | F. State cleanup |
|---|---|---|---|---|---|---|
| **1** Live new today | `mealRepository.save` | `ThreadItem.meal(at=now)` added | `coachSessionProvider.submitMeals([meal])` | In-thread `CoachThinkingBubble` (gated by `inFlightMealIds`) | `scrollToBottom` (#39 fix, today-meal branch) | Manager `finally { state.remove(id) }` |
| **2** Live new today, backdated | same | `ThreadItem.meal(at=backdated)` added | same | same | `scrollToBottom` ❌ wrong, see Inconsistency #1 | same |
| **3** Past-day via empty-day-tap | same | `ThreadItem.meal(at=picked)` added | same | same | `scrollToDayProvider` set → handler scrolls to new meal (#42 fix) | same |
| **4** Past-day via calendar | same as 3 | same | same | same | same | same |
| **5** Edit, no time change | `mealRepository.save` (id stays, overwrites) | **NO new ThreadItem** | If values changed: `removeCoachResponseForMeal` + direct `generatePerMealResponse` call (bypasses manager). If unchanged: no-op. | Banner `CoachLoadingBanner` above input (gated by `insightLoadingProvider`) ❌ inconsistent, see Inconsistency #2 | None triggered (meal already in `_lastThreadMealIds`, no diff) | `.whenComplete { loadingNotifier.state = false }` (#43 fix) |
| **6** Edit, time change same day | same | **ThreadItem.at NOT updated** ❌ see Inconsistency #3 | same as 5 | same as 5 | same | same |
| **7** Edit, time crosses day | same | **ThreadItem.at NOT updated, meal stays in wrong day** ❌ see Inconsistency #3 | same | same | same | same |
| **8** Bundle intermediate | `mealRepository.save` | `ThreadItem.meal(at=now)` added | Skipped: meal added to `pendingScanBundleProvider`, no API call yet | Nothing shown (not in-flight, no banner) | Fires under modal (autoscroll triggers, visually hidden) ❌ see Inconsistency #4 | n/a |
| **9** Bundle final | same | same | `coachSessionProvider.submitMeals([...bundle, meal])` (drain) | In-thread bubble on LAST meal id only | `scrollToBottom` (today) | Manager finally |

---

## Per-case notes

### UC 1, 3, 4 — Live and past-day new saves
After commits 77fc535 (#39) and d77d6ba (#42), these three are now consistent: today goes to bottom-of-today, past-day scrolls to the new entry via the `scrollToDayProvider` handler preferring `scrollTargetMealId`. The thinking-bubble is in-thread (in the day bucket where the meal lives), which is the intuitive position.

### UC 2 — Backdated today (broken, see Inconsistency #1)
The current `isToday` branch in `home_screen.dart` triggers `_scrollToBottom()` for any meal whose `createdAt.day == today`. For a meal backdated to e.g. 7:30 AM with three later meals already in today's list, scrollToBottom lands the user on dinner, not on the new 7:30 entry. The user thinks "where did my entry go?".

### UC 5–7 — Edits (broken in multiple ways, see Inconsistencies #2 and #3)
The edit path bypasses `CoachSessionManager` entirely and calls `generatePerMealResponse` directly. Two consequences:

1. The thinking-bubble is rendered as a **banner above the input bar** (`CoachLoadingBanner` gated by `insightLoadingProvider`), not as an in-thread bubble next to the meal. For new meals you see the bubble next to the entry you just added; for edits you see a banner detached from the entry. Visually inconsistent.

2. For time-change edits, the `MealEntry.createdAt` is updated and persisted, but the corresponding `ThreadItem` keeps its original `at` field. The diary lays out entries by `ThreadItem.at`, so the entry visually stays at the old timeslot even though its display time (from `meal.createdAt`) shows the new value. For UC 7 (crossing day boundary), this is especially bad: the entry appears in yesterday's bucket while claiming to be today.

### UC 8 — Bundle intermediate
Intermediate saves trigger the home-screen autoscroll behind the modal (the home screen rebuilds when a new meal is added, even with a modal in front). The scroll ends in a weird intermediate position by the time the bundle completes. Not user-facing critical because UC 9's final save autoscrolls again, but wasted work and can briefly flash content under the modal.

### UC 9 — Bundle final
Works after #39 fix. The one quirk worth noting: the in-flight set only contains the LAST meal's id (`state = {...state, meals.last.id}` in `CoachSessionManager.submitMeals`). So the in-thread bubble appears next to the last bundle meal, representing the whole batch's reply. Other bundle meals don't show a bubble. This is by design but worth knowing.

---

## Inconsistencies and proposed fixes

These are the things the audit found that don't match user expectations. Each
is independent and can be fixed separately.

### #1 — Backdated-today scroll lands on wrong entry (UC 2)

**What**: today-meal autoscroll always goes to scrollToBottom (commit 77fc535).
For a meal whose `createdAt` is today but earlier than other already-logged
meals, this lands the user on the latest meal, not on the new one.

**Fix proposal**: tighten the today-branch: scrollToBottom only when the new
meal IS the latest in today's bucket (its `createdAt >=` every other meal's
createdAt that day). Otherwise fall back to `_scrollToNewMeal(id)` so the
user lands on the entry they actually just added.

**Impact**: small targeted change in `home_screen.dart` autoscroll
dispatcher. ~20 lines.

### #2 — Edit shows banner above input, new-meal shows in-thread bubble (UC 5–7)

**What**: edits route the coach call through `confirm_screen.dart` direct
`.then/.catchError` (with `insightLoadingProvider`) instead of through
`CoachSessionManager` (with `inFlightMealIds`). Result: edit-thinking-bubble
is a banner above the input bar; new-meal thinking-bubble is in-thread.
Different positions, different colors, different mental model.

**Fix proposal**: route edits through `CoachSessionManager` too. Manager
needs a new method, e.g. `regenerateForMeal(meal)`, that:
- removes existing coach response for the meal first
- adds meal.id to in-flight set
- calls `generatePerMealResponse` for that single meal
- adds the new ThreadItem.coachResponse
- removes id from in-flight set in finally

This collapses the two coach paths into one. As a side effect, the
`insightLoadingProvider` and `CoachLoadingBanner` would become unused for
this path (could remove them entirely once chat-only is the only other
consumer).

**Impact**: medium. ~50 lines new + ~30 lines deletion across two files.
The whenComplete fix from #43 still applies as defense in depth.

### #3 — Editing a meal's time doesn't update its ThreadItem position (UC 6, 7)

**What**: `mealRepository.save(meal)` overwrites the meal with the new
`createdAt`, but the meal's `ThreadItem` keeps its original `at`. The diary
renders position by `ThreadItem.at`, so the entry stays at the OLD time
visually. For UC 7 (cross-day), it stays in the wrong DAY bucket.

**Fix proposal**: when the edit changes `createdAt`, also update the
corresponding `ThreadItem.at`. Either:
- a) Add `threadRepository.updateMealItemTime(mealId, newAt)` and call it
  from the edit path
- b) Make the diary read meal position from `MealEntry.createdAt` instead
  of `ThreadItem.at` (single source of truth). This is cleaner but a
  bigger refactor — every place that builds the threadByDay map would need
  to fetch the meal first to pick the timestamp.

**Impact**: (a) is the minimal fix, ~10 lines new in repo + 3 lines wiring
in `confirm_screen.dart`. (b) is the right long-term answer but should
wait until after beta, since it touches the rendering core.

### #4 — Bundle intermediate saves trigger autoscroll under the modal (UC 8)

**What**: home screen rebuilds and runs the autoscroll dispatcher when a
new meal is added, even with a modal in front. The scroll happens; the user
can't see it. By the time the bundle completes, the scroll position is in a
weird intermediate state.

**Fix proposal**: skip autoscroll while the `pendingScanBundleProvider`
state is non-empty (i.e. mid-bundle-session). The final save's autoscroll
still fires correctly because by then the bundle has been drained.

**Impact**: tiny, ~5 lines in `home_screen.dart`. Mostly cleanup, not
user-blocking.

---

## Priority recommendation

Looking at the 4 inconsistencies, ordered by user-impact:

1. **#3** (edit time change doesn't move entry) — HIGH user impact, breaks
   the mental model of "I changed the time so the entry should be at the
   new time". Should fix before Beta-Week-2.
2. **#1** (backdated today lands wrong) — MEDIUM. Same family as Bug #42
   (past-day scroll), affects the "I logged retroactively, where did it
   go" case for the same-day version. Fix soon.
3. **#2** (edit bubble vs. new bubble inconsistency) — LOW user-impact but
   feels unpolished. Worth doing because it also collapses two code paths
   into one (technical debt reduction). Schedule for the "during Beta"
   block, not blocking.
4. **#4** (bundle intermediate autoscroll waste) — LOW, mostly invisible.
   Schedule after #1–#3.

Total fix work: ~3–4 hours across all four if done together.
