# Scroll-behaviour audit (Home / Diary)

Explore artefact for board card `^s7c7jg` "Holistic scroll-behavior audit (all flows)".
Problem understanding only, **no solution** (that belongs in `/create-plan`). Verified
against `lib/screens/home_screen.dart` on 2026-06-21.

## What the tester experienced

Isabella (T8, 2026-06-11, TestFlight v18):

> „Day switch lands at end of TODAY's chat. Expected: start of selected day's chat."

Switching to a past day lands the diary mid-conversation instead of at the top of the
chosen day. Two patches (`jumpTo(0)` at 80 ms, then a 6-frame retry loop) did not
converge.

## Scroll-target taxonomy

Every flow that changes the viewport wants exactly one of these targets. The plan's
coordinator needs one unambiguous target per flow:

- **day-top** — first item of the focused day pinned to the top of the viewport.
- **meal-anchor** — a specific meal entry pinned to the top, its coach reply rendered
  below it. We anchor on the **meal the user logged, not the coach answer**.
- **bottom-input** — max scroll extent, keeps the input bar / newest entry in view
  (chat-style mental model).
- **bottom-answer** — max scroll extent after a chat question, i.e. the coach's answer
  to what was just asked (this is the one deliberate "go to the coach reply" case).

## Dispatchers in code today

Single `ScrollController` (`_scroll`, `home_screen.dart:37`), GlobalKey per meal
(`_mealKeys`, `:44`). Eight independent dispatchers, all via `addPostFrameCallback`,
**no central coordinator**:

| # | Dispatcher | Trigger | Target | Timing | Line |
|---|---|---|---|---|---|
| D1 | Initial bottom | `initState` (once) | bottom-input | jumpTo, no anim | 89 |
| D2 | Auto-scroll new meal | new meal-ids **< 60 s old** | bottom-input / meal-anchor | postFrame | 404 |
| D3 | Day switch | `scrollToDayProvider` | day-top | 80 ms + 6× jumpTo(0) @50 ms | 470 |
| D4 | Scroll to meal | `scrollToMealIdProvider` | meal-anchor | 10× retry @200 ms | 527 |
| D5 | Follow coach reply | totalItems delta, near-bottom | bottom-input | postFrame | 445 |
| D6 | Chat question | `scrollToBottomRequestProvider` | bottom-answer | postFrame | 600 |
| D7/D8 | FAB up / down | user tap | day-top / bottom-input | direct | 866/878 |

Guards: `_programmaticScroll`, one `_handled…` flag per provider, 300 ms cooldown in
`_scrollToBottom`.

## Flow × current vs expected

### Day change (the core problem)

| Flow | Trigger today | Current (IST) | Expected | Status |
|---|---|---|---|---|
| AppBar picker → past day with meals | `scrollToDay` → D3 | lands mid-conversation (timing race) | day-top | ✗ Isabella |
| History (Verlauf) tap → day | `scrollToDay` → D3 | same race | day-top | ✗ same root |
| "Heute" button | **only `focusedDay`**, no dispatcher | no scroll pin, keeps old offset | bottom-input (today) | ⚠ gap |
| Swipe left / right → day | **only `focusedDay`**, no dispatcher | no scroll pin | day-top (past) / bottom-input (today) | ⚠ gap |
| AppBar picker → empty day | D3 jumpTo(0) | probably fine | day-top / stable | ~✓ |

### Save / log

| Flow | Current | Expected | Status |
|---|---|---|---|
| Meal on today (newest) | D2 → bottom | bottom-input | ✓ |
| Retro meal on today (backdated) | D2 → meal | meal-anchor | ✓ |
| Meal on a past day (from today) | D3 + D4 in parallel | day change + meal-anchor | ⚠ race |
| Multi-photo bulk (single day) | D3 + D4 in parallel | meal-anchor (last) | ⚠ race |
| Single-photo save | D2 path | meal-anchor | ✓ |

### Chat / initial / manual

| Flow | Current | Expected | Status |
|---|---|---|---|
| Send chat question | D6 → bottom | bottom-answer | ✓ |
| Coach reply arrives (passive) | D5 → bottom if near | follow only if near-bottom | ✓ |
| App start (today) | D1 → bottom | bottom-input | ✓ |
| FAB up / down | D7 / D8 | day-top / bottom-input | ✓ |
| Keyboard opens (input focus) | no re-anchor (Flutter default) | input stays visible | ~✓ verify on device |
| Push notification tap | no deep-link scroll exists | (open) | n/a today |

## Systemic finding

The day-change family has **four entry points with three different behaviours**: AppBar
picker and History both attempt a top-reset via D3 (timing-buggy), while "Heute" and
swipe set only `focusedDay` and fire **no dispatcher at all**. Isabella's report is the
visible tip; the underlying problem is that "switch to a day" has no single defined
scroll target. On top of that there are two genuine multi-dispatcher races on save
(D3 + D4).

## Verified (corrects an earlier mis-read)

- D2 has a 60 s gate (`home_screen.dart:389-397`) with the explicit comment *"Older
  meals appearing because the user loaded a past day shouldn't hijack the scroll
  position."* So on a pure day switch D2 does **not** fire — Isabella's flow is **D3
  alone**, not a D2/D3 race.
- D5 requires `newlyRenderedMealIds.isEmpty` (`:445-448`); on a day switch that set is
  non-empty, so D5 does not fire either.
- AppBar picker (`:353-354`) and History (`history_screen.dart:38`) set
  `scrollToDayProvider` → D3. "Heute" (`:696`) and swipe (`:806/:813`) set only
  `focusedDayProvider` → no dispatcher.

Root cause of Isabella's bug: D3 is time-heuristic (fixed 80 ms then 6× `jumpTo(0)`),
but `focusedDayThreadProvider` (`repo.watchForDate`) emits the new day's items
asynchronously. On a heavier day the jumpTo loop runs before layout settles and nothing
re-pins afterwards. The patches tuned delay/retry count, not the trigger; there is no
deterministic "new day is laid out" signal.
