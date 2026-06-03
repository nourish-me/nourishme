# NourishMe — Code Audit

A critical snapshot of the codebase's structural health as of 2026-06-02
(after build 1.0.0+18 went to Apple Beta Review). Three things in one
document:

1. **Snapshot** of what currently smells, file by file.
2. **Refactor backlog** with priority (P0 / P1 / P2) and timing tag
   (`safe-now` = mechanical, no behaviour change, OK during beta;
   `post-beta` = invasive, risk of regressions, wait until tester
   feedback loop pauses).
3. **Principles** at the end, to prevent the same smells from
   re-accreting in future work.

Read this together with `ARCHITECTURE.md` (system overview) and
`CLAUDE.md` (project context).

---

## 1. Severity legend

| Marker | Meaning |
|---|---|
| **P0** | Will hurt productivity / cause bugs within weeks. Fix soon. |
| **P1** | Real friction but not immediately dangerous. Schedule. |
| **P2** | Nice-to-have polish. Defer. |
| `safe-now` | Mechanical refactor, no behaviour change. OK to ship during beta. |
| `post-beta` | Touches behaviour or large surface. Wait until beta tester loop pauses (~ 4 weeks). |

---

## 2. What's working well

Honest context before the criticism. These are decisions that don't need
revisiting:

- **Directory layout is clean** — `services/` `models/` `screens/`
  `widgets/` `utils/` `providers/` `theme/` `l10n/`. Newcomers find
  what they expect where they expect it.
- **Repository pattern is consistent** — every Hive box is wrapped in a
  `*Repository` class exposing typed methods + a `Stream` via `watch()`.
  Screens never touch Hive directly.
- **Models are stable** — `toJson` / `fromJson` with defaults in the
  factory so old records survive new fields without explicit migrations.
- **Comments are signal, not noise** — `git grep "//"` returns mostly
  *why*-comments on subtle decisions, not narration of what the next line
  obviously does.
- **No TODOs, FIXMEs, or HACK markers anywhere.** Either everything is
  fixed (unlikely) or, more honestly, decisions get followed through
  rather than parked. Either way, no rotting markers.
- **Worker (`api/worker.js`) is production-quality** for its size:
  per-call telemetry, daily call-cap circuit breaker, graceful
  degradation when KV isn't bound, proper error responses. A real
  reference for "small but correct".
- **Privacy is genuinely anonymous.** PostHog events carry only
  metadata; Sentry has `sendDefaultPii: false` + `attachScreenshot:
  false`. Two systems but consistent posture.
- **l10n discipline** — every user-facing string seen in newer code
  goes through ARB. No drift to hard-coded German.

Now the issues.

---

## 3. Hot-spot deep dives

### 3.1 `lib/screens/home_screen.dart` — 2 595 lines, 17 classes

The single worst file in the codebase. Acts as Diary screen, meal-input
widget, scanner-loop driver, history-suggestion logic, past-day-input
sheet, empty-day pickers, plus all the rendering primitives for the
diary thread. The accretion happened gradually — each feature added
"just one more class" at the bottom of the file.

**Concrete numbers:**
- 17 top-level classes in one file
- `_HomeScreenState.build` = 447 lines (Flutter convention: keep
  under ~100, ideally under 60)
- `_HomeInputState.build` = 334 lines
- `_buildContext` (the Coach context-block builder) = 109 lines
- 5 different `_State` classes with their own controllers + lifecycles

**Smells, ordered by severity:**

| # | Smell | Priority | Timing |
|---|---|---|---|
| 1 | 17 classes in one file. New contributors (or future-AI) can't navigate. | **P0** | `safe-now` |
| 2 | `_HomeScreenState.build` is 447 lines with deeply nested Stacks / Columns / Conditionals. Hard to follow control-flow. | **P0** | `safe-now` |
| 3 | `_HomeInputState` mixes 5 concerns: text input + image picker + barcode scanner trigger + history-match chip row + favourites row. Each is a candidate for extraction. | **P0** | `post-beta` (touches the input UI, where regressions would be most visible) |
| 4 | Scan-session loop (`_runScanSession` + 3 step methods) lives in `_HomeScreenState` but is functionally a separate orchestrator. ~200 lines that don't belong to "the diary screen". | **P1** | `post-beta` |
| 5 | Many small render helpers (`_DaySeparator`, `_EmptyDay`, `_EmptyDayRange`, `_EmptyRangePickerSheet`, `_WarningIconButton`) — each fine on its own, but they bloat the file. | **P1** | `safe-now` |
| 6 | Scroll-state is sprinkled: `_scroll`, `_programmaticScroll`, `_loadingPreviousDay`, `_handledScrollToDay`, `_scrollDir`, `_dayHeaderKeys`, `_mealKeys`, `_lastTotalItemCount`, `_lastThreadMealIds`. 9 fields for one feature (scroll behaviour). Candidate for a `_ScrollController`-style helper class. | **P1** | `post-beta` |

**Recommended split** (target structure post-refactor):

```
lib/screens/diary/
├─ home_screen.dart           ← _HomeScreenState + build only
├─ diary_thread.dart          ← _buildSlivers + per-day rendering
├─ home_input.dart            ← _HomeInput + _HomeInputState
├─ scan_session.dart          ← _runScanSession + step helpers
├─ history_suggestions.dart   ← chip widget + relative-time helper
└─ widgets/
   ├─ thread_meal_card.dart
   ├─ coach_bubble.dart       ← + _UserBubble + _CoachThinkingBubble +
   │                            _CoachLoadingBanner (all coach-adjacent)
   ├─ day_separator.dart      ← + _EmptyDay + _EmptyDayRange
   └─ past_day_input_sheet.dart
```

Estimated effort: ~3-4 h focused. Mechanical move-paste-import-fix.

---

### 3.2 `lib/screens/settings_screen.dart` — 1 742 lines

Less critical than home_screen.dart because it's already broken into
`_Section`-style sub-widgets (`_PhaseSection`, `_ProfileFields`,
`_ActivitySection`, `_RemindersSection`, `_ThemeSection`,
`_PrivacySection`, `_MilkSection`, `_OutcomeCard`, `_MacroSplitSection`,
`_DietSection`, `_FavoritesSection`, `_NumberStepper`). The structure is
right, the file is just long.

**Smells:**

| # | Smell | Priority | Timing |
|---|---|---|---|
| 1 | 1 742 lines in one file even with good decomposition. Sections that share no state could each be their own file. | **P1** | `safe-now` |
| 2 | `_OutcomeCard` + `_OutcomeRow` + `_MacroSlider` + `_NumberStepper` are widgets reusable beyond Settings, but live here. Move to `lib/widgets/`. | **P2** | `safe-now` |
| 3 | `_SettingsScreenState.build` is healthy-sized (~150 lines) because the assembly is just listing sections. Good. | — | — |

**Recommended split:**
```
lib/screens/settings/
├─ settings_screen.dart       ← _SettingsScreenState scaffold
└─ sections/                  ← one file per _XxxSection
```

Estimated effort: ~1-2 h. Lower urgency than home_screen.

---

### 3.3 `lib/screens/confirm_screen.dart` — 1 143 lines

Heavy because of the form layout. Mostly justified: every meal field
needs its own labelled input, plus the macro re-parse flow + the
keyboard accessory bar + the bottom action row + bundle-mode chooser.

**Smells:**

| # | Smell | Priority | Timing |
|---|---|---|---|
| 1 | `_appendToThread` (~90 lines) does too much: persists the meal item, decides between fire-coach / append-to-bundle, runs scroll-target logic, runs the edit-path direct call. Three responsibilities, three reasons to change. **Confirmed during architecture review (2026-06-03):** the right fix is to extract a `MealSaveOrchestrator` service that owns the save-flow logic; ConfirmScreen ends up knowing only the orchestrator, not 6 separate providers. | **P1** | `post-beta` |
| 2 | `source` is a stringly-typed enum: 'text', 'photo', 'barcode', 'favorite', 'quick_add', 'edit', 'history'. Typos here = silent analytics drift. Replace with `enum MealEntrySource` in `models/` + use throughout. | **P1** | `safe-now` |
| 3 | `popValue` on `_save({fireCoach, popValue})` is `Object?` and callers know it can be `MealEntry`, `'barcode'`, `'photo'`, `'text'`, or null. Same problem as #2 — string-typed flow control. Wrap in a sealed/result type. | **P2** | `post-beta` |

---

### 3.4 `lib/providers/meal_providers.dart` — 29 providers, 219 lines

Single-file provider hub. Works fine today, but provider count is the
canary: at ~50 providers the file becomes navigationally annoying.

**Smells:**

| # | Smell | Priority | Timing |
|---|---|---|---|
| 1 | All providers in one file. Grouping is good (comments separate sections) but file-level boundaries would help discoverability. | **P2** | `safe-now` |
| 2 | UI-orchestration providers (`mealInputFocusRequestProvider`, `scrollToDayProvider`, `mealInputPrefillProvider`, `selectedTabProvider`, `themeModeProvider`) sit next to data providers. They serve different layers and shouldn't share a file. | **P1** | `safe-now` |

**Recommended split:**
```
lib/providers/
├─ repository_providers.dart       (overridden in main)
├─ data_providers.dart              (mealsProvider, profile, weights, …)
├─ derived_providers.dart           (calorieTarget, macroTargets, weightTrend)
├─ coach_providers.dart             (coachSession, pendingScanBundle, insightLoading)
└─ ui_orchestration_providers.dart  (focus, scroll, prefill, tab, theme)
```

Estimated effort: ~30 min. Find/replace import paths.

---

### 3.5 `lib/services/coach_session_manager.dart` — 213 lines, recently refactored

Clean. Single responsibility: take meals, hand to Claude, route results
back to the thread. The Set<String> in-flight model is correct after
the bundling-timer removal.

| # | Smell | Priority | Timing |
|---|---|---|---|
| 1 | The bundled-meal user-message assembly (`combinedRawText`, `combinedSummary`, `sumKcal`…) lives inside `_runCallFor`. If we ever add another bundling entry-point, this needs extracting to a free function `MealBundleInput.fromMeals(meals)`. Not urgent. | **P2** | `post-beta` |

---

### 3.6 `lib/services/claude_client.dart` — 855 lines

Most of the length is prompt strings (DE + EN versions of parse + per-
meal + chat prompts, plus context-block builders). Necessary surface
area for a single LLM provider.

| # | Smell | Priority | Timing |
|---|---|---|---|
| 1 | Prompts are inline string constants. For very large prompts, splitting them into per-prompt files under `lib/services/prompts/` improves diffability when iterating prompt wording. Not urgent at current size. | **P2** | `safe-now` |
| 2 | DE and EN prompt versions live as parallel strings. Any structural change to one must be mirrored manually to the other. Long-term this drifts. Could be parameterised, but the cost (added complexity in prompt assembly) probably outweighs benefit until we add a third language. | **P2** | `post-beta` |

---

### 3.7 Cross-cutting: tests

**There are no tests.** Zero unit tests, zero widget tests, zero
integration tests.

Confirmed during architecture review (2026-06-03): not a deliberate
trade-off, just never made it on the priority list. That keeps the
P0 rating on the calorie-target tests — once flagged, the cost of
adding them is low and they catch the most user-visible math
silently regressing. Three categories that should exist before the
codebase gets significantly larger:

| # | What | Priority | Timing |
|---|---|---|---|
| 1 | **Unit tests for `services/calorie_target.dart`** (Mifflin-St-Jeor + supplements). Pure math, no dependencies. Catches accidental regressions on the most user-facing number in the app. | **P0** | `safe-now` |
| 2 | **Unit tests for `services/coach_session_manager.dart`'s bundle combination logic** (sum kcal/macros, union safety warnings). Tested with mock ClaudeClient. | **P1** | `post-beta` |
| 3 | **Widget tests for the parse-result → MealEntry round trip** in ConfirmScreen. Catches the kind of edge case where summary gets clobbered on edit. | **P1** | `post-beta` |

A wider test pyramid (every screen widget-tested, integration tests for
end-to-end flows) isn't justified until the team is bigger than 1.

---

### 3.8 Cross-cutting: stringly-typed enums

Found in multiple places. Each one is a potential silent-failure surface.

| Place | What's stringly-typed | Fix |
|---|---|---|
| `ConfirmScreen.source` | `'text' / 'photo' / 'barcode' / 'favorite' / 'quick_add' / 'edit' / 'history'` | `enum MealEntrySource` |
| `ConfirmScreen._save.popValue` | `MealEntry / 'barcode' / 'photo' / 'text' / null` | `sealed class _ConfirmExit` |
| `ClaudeClient._post.callType` | `'parse' / 'photo' / 'coach' / 'chat' / 'safety' / 'unknown'` | `enum CoachCallType` (also exported to Worker for telemetry consistency) |
| PostHog event names + property keys | All string literals everywhere | `class AnalyticsEvents` with static const fields. Catches typos in events that silently never fire. |

Combined effort: ~1-2 h. Priority **P1**, `safe-now` (mechanical
find/replace).

---

### 3.9 Cross-cutting: duplicate UI patterns

| What's duplicated | Where | Fix |
|---|---|---|
| Rose-tinted info container with icon + text | Bundle hint in ConfirmScreen + thinking bubble in home_screen | Extract `_RoseHintBanner({required icon, required text})` |
| Time formatting `HH:mm` | `_ThreadMealCard` + `_PastDayInputSheet` + ConfirmScreen + onboarding | Already a helper exists for some cases; centralise in `utils/date_format.dart` |
| Locale-aware "isDe" check | Reimplemented in every prompt builder method | A single getter or static helper |

Priority **P2**, `safe-now`. Mostly polish; refactor when next touching the relevant file.

---

## 4. Roadmap (proposed order)

Grouped by what's safe now vs after the beta loop settles. Adjust based
on what hurts most when you next touch the code.

### 4a. Do now (during beta, low-risk)
1. **Split `meal_providers.dart`** into 5 files (~30 min)
2. **Extract `enum MealEntrySource`** + replace stringly-typed `source`
   across the codebase (~30 min)
3. **Add unit tests for `calorie_target.dart`** (~1 h)
4. **Move shared widgets** (`_OutcomeCard`, `_NumberStepper`, etc.) out
   of `settings_screen.dart` into `lib/widgets/` (~30 min)
5. **Split `home_screen.dart` into a `diary/` folder** — mechanical,
   no behaviour change, ~3-4 h

Total: ~half day of mechanical refactor work that materially improves
discoverability with zero user-visible change.

### 4b. After beta (~ 4 weeks out)
6. Decompose `_HomeInputState` into smaller widgets
7. Extract scan-session orchestrator out of HomeScreen
8. Refactor `confirm_screen.dart`'s `_appendToThread` (3 responsibilities → 3 methods)
9. Add tests for coach session bundling logic
10. Replace `popValue: Object?` with a sealed result type

### 4c. Defer / nice-to-have
- Move Claude prompts into per-file modules
- Centralise time formatting helper
- Extract `_RoseHintBanner`
- Parametrise DE/EN prompt structure (only if we add a third language)

---

## 5. Principles for future code

Five rules that, if followed, prevent re-accretion of the smells above.
Add these to `CLAUDE.md` so future AI sessions internalise them.

### 5.1 800-line file ceiling
Any source file approaching 800 lines is a code smell. Split before
crossing the line. (Exception: prompt-heavy files like `claude_client.dart`
where the bulk is data, not logic.)

### 5.2 100-line build method ceiling
A `build()` method over 100 lines is decomposing-by-extraction overdue.
Extract sub-widgets, even if they're only used once — they're easier
to read in isolation.

### 5.3 No new top-level widget class without a question
Before adding a new `class _XxxWidget` to an existing file, ask: does
it belong in the same file as the screen it's used from, or in
`lib/widgets/`? Default to a separate file under widgets/.

### 5.4 No stringly-typed flow control
If a String value drives an `if` / `switch` / call-site decision,
promote it to an `enum` or a sealed class. Strings are for *display*,
not for *logic*.

### 5.5 Providers belong with their layer
- Repository overrides → `repository_providers.dart`
- Data streams → `data_providers.dart`
- UI orchestration (focus, scroll, prefill) → `ui_orchestration_providers.dart`
Don't mix layers in one file. The split tells the reader "what is
state-of-the-world" vs "what is UI plumbing".

---

## 6. What this audit does NOT cover

Honest about scope boundaries:

- **Performance** — no profiling data, no claims about render-time
  hotspots. Audit later with `flutter run --profile` if a screen feels
  slow.
- **Accessibility** — VoiceOver coverage, Dynamic Type, color
  contrast. Worth a separate pass.
- **Native iOS layer** — Swift / Info.plist / entitlements stay as-is;
  none of this is Flutter-side refactor surface.
- **Worker (`api/worker.js`)** — solid for its scope, no action needed.
- **Landing page (`docs/`)** — separate concern, not part of the app
  codebase health.
