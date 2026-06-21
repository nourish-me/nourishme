# Plan: Single scroll coordinator for the diary (home_screen)

**Fortschritt:** `25%` (Phase 1 code-complete, device-verify pending)

Board card: `[[board#^s7c7jg]]` · Explore matrix: `[[docs/explore/scroll-behavior-audit.md]]`

## TLDR

Replace the 8 independent, timer-driven scroll dispatchers on the diary with one
coordinator that owns the `ScrollController` and consumes a single `ScrollIntent`,
resolved **after the focused-day data has emitted and laid out** (not after a fixed
80 ms). Fixes the day-switch-lands-mid-conversation bug at its root, unifies the four
inconsistent day-change entry points, and removes the save-time D3+D4 races.

## Critical Decisions

- **Gewählt: Option B (ScrollCoordinator + intent state machine).** Matches the card's
  goal ("a single coordinating handler that owns scroll-on-day-or-meal-change,
  replacing the parallel observers"). Fixes the timing root cause, the systemic
  4-entry inconsistency, and the save races in one place, without a new dependency.
- **Verworfen: Option A (surgical data-driven D3 fix).** Faster and lower-risk, but
  leaves the 8 dispatchers scattered, the "Heute"/swipe gaps and the save races
  unaddressed. Folded in as B's internal trigger mechanism instead.
- **Verworfen: Option C (ScrollablePositionedList swap).** Robust against layout
  timing but biggest change + new dependency + re-expressing every dispatcher as an
  index + regression risk on chat-bubble rendering and the iOS SlideTransition
  fallback. Kept as a fallback only if pixel-pinning still flakes after B.
- **No data touched.** Pure scroll/UI; no nutrition, calorie or safety values change,
  so no DSGVO / App-Store implications.

## Scroll-target taxonomy (the intent vocabulary)

`ScrollIntent { ScrollTarget target, String? mealId, bool onlyIfNearBottom, int token }`
- `dayTop` — first item of the focused day pinned to top. (all 4 day-change entries)
- `meal` (+ mealId) — meal entry pinned to top, coach reply below. (retro/backdated
  save, cross-day save, multi-photo, single-photo)
- `bottom` — max scroll extent. `onlyIfNearBottom=false` for app-open, save-today-
  newest and chat question (bottom-answer); `onlyIfNearBottom=true` for the passive
  coach-reply follow.

## Rollback

Multi-phase refactor of a working system, not a one-liner. Each phase is its own
commit and leaves the app shippable; rollback = revert the phase commit(s). The old
behaviour stays in git history. Medium risk: verify each phase on device against the
Explore matrix before starting the next. No data migration, so no data rollback.

## Schritte

- [ ] 🟨 **Phase 1: Coordinator skeleton + day-change (the bug)**
  - [x] 🟩 Add `ScrollTarget` enum + `ScrollIntent` model + `scrollIntentProvider` + a
    `requestScroll(ref, ...)` helper (token auto-increments, never reset to null; a
    `_handledIntentToken` guard prevents re-fire — mirrors the existing
    scrollToBottomRequest pattern).
  - [x] 🟩 Coordinator in home_screen build: resolve a pending intent only on the build
    where the focused-day data is present (`hasValue && !isLoading`) and
    `intent.day == focusedDay`, then one post-frame pin. Resolves `dayTop` (jumpTo 0)
    and `bottom` (today lands at the input); `meal` is wired in Phase 2.
  - [x] 🟩 Route the four day-change entries via `requestScroll`: AppBar picker, Verlauf
    tap, "Heute" button, swipe — each picks `bottom` for today, `dayTop` for a past
    day. They no longer use `scrollToDayProvider`.
  - [x] 🟩 Keep D3 (`scrollToDayProvider`) in place for now — the cross-day SAVE path
    still uses it; it is removed in Phase 2 when saves migrate. The day-change entries
    simply bypass it.
  - [ ] 🟥 Device-verify: day-switch via all four entries to a past day (heavy + light)
    lands at day-top; empty day stable; "Heute" / swipe-to-today land at the input
    (bottom).

- [ ] 🟥 **Phase 2: Save flows (kills the D3+D4 races)**
  - [ ] 🟥 Route retro/backdated save and single-photo to `meal(mealId)`; today-newest
    to `bottom`; cross-day save and multi-photo to `meal(lastMealId)` (single intent,
    no parallel D3+D4).
  - [ ] 🟥 Coordinator resolves `meal` via the existing `_scrollKeyToTop` primitive
    (keep its iOS SlideTransition fallback) once the meal's key is attached.
  - [ ] 🟥 Remove D2's autoscroll heuristic and D4; remove `scrollToMealIdProvider`.
  - [ ] 🟥 Device-verify: log on today, retro on today, log on a past day, multi-photo
    bulk, single-photo — each lands per the taxonomy; highlight pulse still fires.

- [ ] 🟥 **Phase 3: Chat / coach / app-open**
  - [ ] 🟥 Route app-open to `bottom`; chat question to `bottom` (onlyIfNearBottom=false);
    passive coach-reply follow to `bottom` (onlyIfNearBottom=true).
  - [ ] 🟥 Remove D1, D5, D6 and `scrollToBottomRequestProvider`; the coordinator now
    owns every scroll except the FAB.
  - [ ] 🟥 Decide FAB (D7/D8): leave as direct user-action calls (synchronous, no data
    wait) or route through intents for uniformity — default: leave direct, note it.
  - [ ] 🟥 Device-verify: send chat question (near bottom + scrolled up in a past day),
    passive coach reply, app cold-open.

- [ ] 🟥 **Phase 4: Cleanup + regression + tests**
  - [ ] 🟥 Remove dead guards superseded by the intent token (`_handledScrollToDay`,
    `_handledScrollToMealId`, `_handledScrollToBottomBump`, redundant `_programmaticScroll`
    paths).
  - [ ] 🟥 Add focused unit/widget tests for the pure intent-resolution logic (which
    target wins, onlyIfNearBottom gating, token bounce-guard).
  - [ ] 🟥 Full device pass against the Explore matrix (every flow, ✓/✗ noted); keyboard-
    open and push-tap sanity checked.
  - [ ] 🟥 `flutter analyze` clean, `flutter test` green.
