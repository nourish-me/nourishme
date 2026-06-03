# NourishMe — Architecture

A reference for any human or AI that needs to understand this codebase
without prior context. Covers what the app does, how the moving parts
fit together, and the *why* behind decisions that look arbitrary from
the outside.

Read this first; then `CLAUDE.md` (project context + workflow
preferences); then `CODE_AUDIT.md` (known smells + refactor backlog).

---

## 1. What this is

**NourishMe** is an iOS-only personal nutrition coach for pregnant and
breastfeeding women. The user logs meals via text, photo or barcode;
the app derives daily calorie + macro targets from the user's actual
phase (trimester / nursing volume) and gives a short live coach reply
after each meal. Food-safety warnings (caffeine, alcohol, mercury fish,
listeria) are baked in.

- **Single user per device.** No accounts, no cloud sync, no multi-user
  model.
- **Local-first.** All persistent data lives in Hive boxes on the
  device. Cloud calls are transient (Anthropic API, Open Food Facts,
  PostHog, Sentry).
- **Closed beta as of 2026-06.** TestFlight external group. Public App
  Store launch later, behind a 7-day-trial → subscription model
  (locked spec; see `CLAUDE.md` / task #34).

---

## 2. Tech stack

| Layer | Choice | Why |
|---|---|---|
| Framework | Flutter 3.41 / Dart 3.11 | Single codebase, fast iteration solo. iOS only for MVP. |
| State | Riverpod 2.x | Compile-time safe DI + reactive providers, less boilerplate than Bloc. |
| Local DB | Hive 2 | Pure-Dart, no native deps, sufficient for our scale (single user, ~thousands of meal records). |
| LLM | Anthropic Claude (Haiku 4.5) | Cheapest model with structured-output reliability. Proxied through our Worker so the API key never ships in the app. |
| Backend proxy | Cloudflare Worker (`api/worker.js`) | Hides the Anthropic key, enforces a daily call-cap (circuit breaker), logs per-call usage for COGS analytics. |
| Barcode product data | Open Food Facts v2 API | Public, free, brand-accurate. We call it directly from the app. |
| Analytics | PostHog (EU region) | Anonymous events, no PII, opt-out in Settings. |
| Crash reporting | Sentry (EU region, Frankfurt) | DSN-gated — init is skipped silently when `.env` doesn't contain `SENTRY_DSN`. |
| Notifications | flutter_local_notifications | All reminders are *local* scheduled notifications. No remote push, no APNs server. |
| Barcode scan | mobile_scanner 7.x | Native camera frame processing. |
| Image picking | image_picker | Camera + gallery, same picker for foto-flow. |
| l10n | gen-l10n (ARB files) | German + English. Device-locale-driven; no in-app switch. |

Anything not in this list is either dev-only (`flutter_lints`) or
something we explicitly chose *not* to use (see § 6).

---

## 3. Directory layout

```
lib/
├─ main.dart                 entry; init order (dotenv → Hive → repos →
│                            notifications → Sentry → runApp)
├─ providers/
│  └─ meal_providers.dart    THE Riverpod hub. Every cross-screen state
│                            lives here.
├─ services/                 business logic + repo wrappers
├─ models/                   plain data classes with toJson/fromJson
├─ screens/                  one file per route/screen
├─ widgets/                  shared UI bits (KcalSummary, info-buttons…)
├─ utils/                    pure helpers (date format, weight trend…)
├─ theme/                    Field-Manual palette + ThemeData builders
└─ l10n/                     ARB sources + generated AppLocalizations
api/
├─ worker.js                 Cloudflare Worker proxy
├─ wrangler.toml             worker config + KV binding
└─ README.md                 deploy + cost-telemetry docs
docs/                        public landing page (GitHub Pages) — NOT
                             internal documentation
```

Internal docs live at repo root (this file, `CLAUDE.md`,
`CODE_AUDIT.md`) so AI tools pick them up by default.

---

## 4. Data model (Hive boxes)

Each model has `toJson` / `fromJson` for Hive persistence. Hive stores
JSON strings, not typed adapters — keeps migrations trivial (just
tolerate missing fields with defaults in `fromJson`).

| Model | Box | Fields (essentials) | Lives in |
|---|---|---|---|
| `UserProfileSettings` | `settings` (key: `profile`) | phase, trimester, height, weight, age, activity, numChildrenNursing, milkSharePercent, dietStyle, restrictions, dietaryNotes | `models/user_profile_settings.dart` |
| `MealEntry` | `meals` | id, createdAt, rawText, summary, kcal, proteinG, carbsG, fatG, portionAmount, portionUnit, portionAlias, safetyWarnings | `models/meal_entry.dart` |
| `ThreadItem` | `thread` | id, timestamp, type (meal / coachResponse / userQuestion / coachAnswer), mealId?, text? | `models/thread_item.dart` |
| `FavoriteMeal` | `favorites` | id, summary, kcal, macros, portion | `models/favorite_meal.dart` |
| `WeightEntry` | `weights` | id, kg, at | `models/weight_entry.dart` |
| `ReminderSettings` | `settings` (key: `meal_reminders`) | masterEnabled, per-slot entries (hour, minute, enabled) | `models/reminder_settings.dart` |
| Misc settings keys | `settings` | `theme_mode`, `disclaimer_accepted_at`, `analytics_distinct_id`, `analytics_opt_out`, `tips_seen_v1`, `bundling_toast_seen` | `services/settings_repository.dart` |

`MealEntry` and `ThreadItem` are separate models. **Historical, not
deliberate** — meals came first, the ThreadItem abstraction was added
later when chat-style entries (user questions + coach answers without
an associated meal) needed somewhere to live. It happens to work
because `userQuestion` and `coachAnswer` items genuinely have no meal
to attach to, so they wouldn't fit cleanly in a MealEntry-extended
model. Don't unify without first checking that pure chat entries are
still a use case.

### Schema evolution rules (Beta-critical)

Hive boxes are `Box<String>` storing raw JSON. There is no schema
version field. The model survives drift by `fromJson` tolerating
missing fields with safe defaults (see `meal_entry.dart` portion
fallback for the existing example).

**Rules for modifying a persisted model during the beta or after any
release shipped to real users:**

1. **Nullable add: safe.** Adding `field: Type?` is the only change
   that is always safe. `fromJson` reads `null` for old records.
2. **Required add: forbidden.** A required new field makes `fromJson`
   throw on every existing record → app fails to start → user must
   reinstall → tester data lost. If you need a new field to be
   required at the type level, add it nullable, write a one-shot
   backfill in the repository's `open()`, then make it required in a
   later release once backfill is verified.
3. **Rename: forbidden.** Renaming a field silently loses the data
   (new code reads `null`). If a rename is unavoidable, write
   explicit dual-read in `fromJson`: try the new key, fall back to
   the old key.
4. **Semantic change: forbidden.** Changing what a field *means*
   (e.g. `portionAmount` from "per 100g" to "total") silently
   corrupts every existing record. If you must, introduce a *new*
   field with the new semantics and migrate explicitly.
5. **Field removal: safe.** Unknown JSON keys are ignored.

When you can no longer follow these rules (a real semantic refactor,
or several migrations stack up), switch to a versioned wrapper
(`{"version": N, "data": {...}}`) plus a migration chain in the
repository's `open()` method. Do not pre-build the wrapper before it
is needed — the current JSON-with-defaults pattern handles all
nullable-add cases for free.

---

## 5. State management map (Riverpod)

Every provider lives in `lib/providers/meal_providers.dart`. Group by
purpose:

### Repository providers (overridden in `main.dart`)
- `mealRepositoryProvider`, `settingsRepositoryProvider`,
  `favoriteRepositoryProvider`, `threadRepositoryProvider`,
  `weightRepositoryProvider`

### Reactive streams from repositories
- `mealsProvider` — `StreamProvider<List<MealEntry>>`, newest-first
- `mealsByDayProvider` — derived map keyed by day
- `todayMealsProvider`, `yesterdayMealsProvider` — convenience filters
- `todayThreadProvider` — diary's living thread
- `userProfileProvider` — `StreamProvider<UserProfileSettings>`
- `favoritesProvider`, `weightsProvider`

### Derived state
- `calorieTargetProvider` — Mifflin-St-Jeor + pregnancy/lactation
  supplements applied to the current profile
- `macroTargetsProvider` — derived from kcal target
- `weightTrendProvider` — weekly rate-of-change from `WeightEntry` log

### UI-only / orchestration
- `insightLoadingProvider` — bool, drives the chat-flow loading banner
- `mealInputFocusRequestProvider` — counter; bumped to ask `_HomeInput`
  to pull focus + open keyboard
- `mealInputPrefillProvider` — payload + version counter for prefilling
  the input from a coach follow-up chip
- `scrollToDayProvider` — `DateTime?`, asks the diary to scroll to that
  day's first meal entry
- `selectedTabProvider` — current bottom-tab index
- `themeModeProvider` — overridden in `main.dart` from `SettingsRepository`

### Coach session machinery
- `coachSessionProvider` — `StateNotifierProvider<CoachSessionManager,
  Set<String>>`. State is the set of meal IDs whose coach call is
  currently in-flight. Drives the inline thinking-bubble in the diary.
- `pendingScanBundleProvider` — `StateProvider<List<MealEntry>>`. Meals
  saved during a scan-session that haven't been handed to the coach
  yet. Drained when the user finally taps Speichern.

### Integration clients (singletons)
- `claudeClientProvider`, `openFoodFactsClientProvider`,
  `analyticsServiceProvider`

---

## 6. Key technical decisions (with rationale)

Knowing the *why* matters more than knowing the *what* — code can be
re-read, but reasons evaporate. If a future change reverses one of
these, do it deliberately, not by accident.

### 6.1 Local-first, no backend
**Why:** MVP scope, single-user model, no Auth/Sync feasibility for one
developer with twin babies. Earlier (pre-rebuild) NourishMe-predecessor
had Supabase + Auth + PKCE — was complex and got lost. Conscious
decision not to replicate.

**Implication:** delete app → data gone. Communicated honestly in
landing + privacy.

### 6.2 Claude via Cloudflare Worker proxy, not direct
**Why:** Anthropic key must never ship in the iOS bundle (extractable
from IPA). Worker holds the key as a Cloudflare secret, app sends a
shared `x-app-secret` header.

**Worker also does:** per-call usage logging (token counts, callType
label) for COGS telemetry, and a daily call-cap circuit breaker via
KV (defaults to 800 calls/day) to prevent runaway-loop billing
disasters.

### 6.3 Coach call is per-meal, fired instantly — not debounced
**Why this is the current state:** an earlier version bundled rapid-fire
logs via a 25-second debounce timer. Live testing showed the wait felt
sluggish even for the dominant single-item case, and the bundling logic
had a subtle race where a save during the calling phase silently
overwrote the in-flight session.

**Current model:** each saved meal fires its own coach call
immediately. `CoachSessionManager.state` is just a `Set<String>` of
meal IDs currently being processed.

**Bundling is preserved** for one explicit case: the **barcode-flow
"Weiteren Bestandteil hinzufügen"** affordance. There, the user
explicitly chains multiple items into one meal and only the final
"Speichern" fires the coach with all bundled items. Bundle queue lives
in `pendingScanBundleProvider`.

### 6.4 No prompt caching on Anthropic side
**Why:** Claude Haiku 4.5 requires ≥ 4096 input tokens for a cacheable
prefix. All our prompts (parse ~1368, per-meal coach ~1004,
coachContextBlock ~412, chat ~839) are well under that threshold, so
`cache_control` would have no effect. Measured + verified — don't add
caching without re-measuring.

### 6.5 Edits bypass the session manager
**Why:** an edit is a targeted re-generation for one specific
already-logged meal. It shouldn't pick up unrelated rapid-fire logs as
"part of the same meal". Edit path calls `claudeClient.generatePerMealResponse`
directly (in `confirm_screen.dart`'s `_appendToThread`), with the
`insightLoadingProvider` driving a bottom banner for visible feedback.

### 6.6 Coach output deliberately short (max 70 words)
**Why:** output tokens cost 5× input on Haiku, so output length is the
dominant cost lever. Also mobile UX: shorter reply means no scrolling
to see the whole answer. Hard-cap reinforced in `_perMealPromptDe/En`
+ `maxTokens: 600` ceiling.

### 6.7 Parse prompt forbids generalisation
**Why:** live testing showed "Tomate, Gurke" → "Gemüse" silently
losing components. Tracking accuracy + history-suggestion matcher both
suffered. Prompt explicitly forbids collapsing to umbrella categories
in both DE and EN. Don't relax this without testing.

### 6.8 History suggestions = lokal, not via API
**Why:** the chip row above the diary input matches against
locally-cached meals (last 30 days, case-insensitive token-containment
on summary). Each chip-tap opens the confirm sheet pre-filled with
exact prior values — *no* parseMeal call. Wins on cost (saved tokens)
and accuracy (brand-correct values from prior barcode scans).

Provider: `mealHistorySuggestionsProvider` (family on the query string).

### 6.9 Bundle-mode mixes barcode + photo + text
**Why:** real meals are mixed (scanned skyr + typed apple). The
"Weiteren Bestandteil hinzufügen" affordance in `_ActionRow` opens a
chooser sheet; `_runScanSession` in `home_screen.dart` loops through
`_doBarcodeStep` / `_doPhotoStep` / `_doTextStep` based on the popped
return value from ConfirmScreen.

### 6.10 Tips deck shown via post-mount delay + slide-up route
**Why:** earlier we pushed TipsScreen inside MainScaffold's initState
post-frame; it jumped in instantly on top of onboarding's exit, felt
like a hard cut. Now: 900 ms delay so Diary lands first, then custom
`PageRouteBuilder` slides + fades the deck up. Versioned `hasSeenTipsV1`
flag in settings so future deck refreshes don't lock previous users out.

### 6.11 Notifications are local-scheduled, recipe baked at schedule time
**Why:** `flutter_local_notifications` schedules notifications with
fixed payload text. iOS does not re-localize at fire time. Locale
changes therefore leave one stale-language push in the queue until the
app is opened and `NotificationScheduler.rescheduleFor(...)` runs with
the new `AppLocalizations`. Known minor edge case; the next launch
heals it.

### 6.12 Privacy: PostHog + Sentry both EU, no PII either way
**Why:** users are EU (initially DE). PostHog events carry only
metadata (event name + small props like `method`, `count`, `ok`); no
meal content, no weight values, no profile fields. Sentry has
`sendDefaultPii: false` + `attachScreenshot: false`. Both are
explicitly disclosed on `docs/privacy.html`.

### 6.13 Pricing locked: 7-day trial → 8.99 €/mo or 49.99 €/yr
**Why:** see decision log in task #27. Apple Small Business Program
(15 % commission) yes; Family Sharing no (each mother has own
profile/phase, no shared use case). Implementation deferred until
beta produces 4+ weeks of usage data (task #34).

### 6.14 Anthropic Claude — default choice, not deliberate
**Honest disclosure:** Anthropic was top-of-mind because development
happens in Claude Code. There was no systematic evaluation against
Gemini Flash or GPT-4o-mini (both significantly cheaper at comparable
structured-output quality). The current cost is acceptable for beta
volume. Post-beta, a side-by-side eval on real prompts is queued as
task #36. **Do not propose switching during beta** — output
consistency would shift mid-test and confuse testers.

### 6.15 CloudKit sync is Phase 2, not "no-cloud forever"
**Today** the app is local-only by design (privacy USP + scope
control). **Phase 2 trigger** (task #35): when the first real
data-loss complaint comes in, or when paying-user count crosses ~50
(churn risk from data loss becomes too expensive), add an
iCloud-via-CloudKit sync layer. Private database, encrypted, no
third-party server — keeps the "your data never leaves your Apple
devices" promise intact. Anything beyond that (real backend, Android,
partner-sharing) is a separate, larger decision.

### 6.16 is_meal=false routing via LLM — pragmatic, not principled
**What:** the parse prompt classifies whether the user's text is a
meal (`is_meal=true`) or a question (`is_meal=false`); the app routes
to the chat flow on the latter. **Trade-off:** frictionless single
input bar (no "are you logging or asking?" toggle) vs occasional
misclassification (the LLM decides). Acceptable as long as
mis-routing is rare in real usage. If beta data shows >5 % wrong
routing, replace with an explicit UI mode toggle.

---

## 7. Critical user flows (sequence sketches)

### 7.1 Log a meal via text
```
_HomeInput._send()
  → claudeClient.parseMeal(text, locale, phase)
      → POST /messages via Worker (callType: 'parse')
  → MealParseResult returned
  → if !isMeal: route to chat flow (_askAsQuestion)
  → else: showModalBottomSheet(ConfirmScreen, source: 'text')
       → user taps Speichern
       → _save() builds MealEntry, persists via mealRepo
       → _appendToThread(meal): persists ThreadItem.meal +
         coachSession.submitMeal(meal, locale)
       → pop sheet
CoachSessionManager._runCallFor([meal])
  → claudeClient.generatePerMealResponse(...)
      → POST /messages via Worker (callType: 'coach')
  → threadRepo.add(ThreadItem.coachResponse(mealId: meal.id, text, at))
  → state.remove(meal.id)  // hides the thinking bubble
```

### 7.2 Scan-bundle (barcode + photo + text mixed)
```
_HomeInput → tap scanner icon → _scanBarcode()
  → _runScanSession(firstType: 'barcode')
  → loop {
      _doBarcodeStep()  → scanner → OFF lookup → ConfirmScreen
                        (allowScanAnother: true)
        On "Weiteren Bestandteil hinzufügen" tap:
          → chooser sheet: barcode / photo / text
          → _save(fireCoach: false, popValue: chosen)
          → meal persisted + appended to pendingScanBundleProvider
        On "Speichern":
          → _save(fireCoach: true)
          → drains pendingScanBundleProvider
          → coachSession.submitMeals([...bundle, current], locale)
          → one coach call for the whole meal
        Loop continues if popValue is 'barcode'|'photo'|'text';
        breaks on null/saved meal.
    }
  → finally: flush any pendingScanBundleProvider remnants
    (defends against user dismissing via swipe-down)
```

### 7.3 Cold-launch from a meal-reminder push
```
iOS launches the app from notification tap
main()
  → NotificationScheduler.init()
    → getNotificationAppLaunchDetails()
    → if true: tapNotifier.value++  (before listeners attached!)
  → runApp(NourishMeApp)
NourishMeApp.initState
  → addListener to tapNotifier
  → check tapNotifier.value > 0 → postFrame → _onNotificationTap
_onNotificationTap()
  → selectedTabProvider = 0 (force Diary tab)
  → mealInputFocusRequestProvider.state++ (×3 with delays 50/300/800ms,
     covers cold-launch race where TextField FocusNode attaches late)
_HomeInputState.build (watching focusReq)
  → if focusReq changed → _focusAndOpenKeyboard()
    → loop 5× with growing delays, _focusNode.requestFocus()
      until hasFocus or give up
```

### 7.4 Retro-log (logging a past day's meal)
```
User taps an empty past-day row in Diary
  → _logForDay(day) shows past-day input sheet
  → user types + picks time → parseMeal → ConfirmScreen
       → _save → _appendToThread
       → mealDay != today → scrollToDayProvider = mealDay
HomeScreen rebuilds (watches scrollToDayProvider)
  → _scrollKeyToTop(_keyForDay(scrollTarget))
     retries up to 12× until the day's RenderBox is laid out
  → diary scrolls so the user sees their new entry land
```

---

## 8. Conventions in this codebase

- **Per-screen state** stays inside the screen's State class. Cross-
  screen state goes through a Riverpod provider in `meal_providers.dart`.
- **Repos** wrap Hive boxes and expose `Stream<List<X>>` via
  `Box.watch()`. UI doesn't touch Hive directly.
- **Services** = business logic that needs DI (Claude client, OFF
  client, analytics). Wrapped in providers.
- **Models** = pure data with `toJson` / `fromJson`. Defaults in
  `fromJson` so old records survive new fields without migration.
- **Comments**: only when *why* is non-obvious. We don't dartdoc every
  function — see § 6 here for the "why" log instead.
- **l10n**: every user-facing string goes through ARB. No hard-coded
  German or English in widgets. ARB strings get generated to
  `app_localizations*.dart` via `flutter gen-l10n`.
- **Em-dashes** in user-facing copy: forbidden (per CLAUDE.md voice
  rule). Use commas, colons or new sentences instead.
- **Commit messages**: focus on *why*, not *what*. The diff shows what.

---

## 9. Build + deploy

| Action | Command | Notes |
|---|---|---|
| Local run | `flutter run` | Uses `.env` for secrets |
| Build IPA | `flutter build ipa --release` | Output: `build/ios/ipa/nurturetrack.ipa` |
| Upload TestFlight | `xcrun altool --upload-app --type ios --file build/ios/ipa/nurturetrack.ipa --apiKey 9T3Z4P8ANY --apiIssuer <ID>` | ASC API key in `~/.appstoreconnect/private_keys/` |
| Deploy Worker | `cd api && wrangler deploy` | Cloudflare account login required |
| Inspect Worker logs | `cd api && wrangler tail` | Live structured-log stream of every API call |
| Generate l10n | `flutter gen-l10n` | Runs automatically on `flutter pub get` if `l10n.yaml` is present |

`.env` keys (gitignored):
- `NOURISHME_API_URL` — worker URL
- `APP_SECRET` — shared with worker for `x-app-secret` header
- `POSTHOG_API_KEY`, `POSTHOG_HOST`
- `SENTRY_DSN` (optional — Sentry init is skipped when empty)

iOS bundle id: `com.vanessaheizmann.nurturetrack` (frozen — App-Store-
registered, not worth renaming).

---

## 10. Non-goals

Documented so future-AI doesn't propose them by mistake:

- ❌ User accounts — local-first by design
- ❌ Third-party backend / Supabase / own server — explicitly out of
  scope. CloudKit sync (Apple-private, no third party) is the only
  cloud direction on the roadmap (task #35, Phase 2)
- ❌ Android port — iOS-only MVP
- ❌ Lifetime IAP — explicitly rejected in pricing decision (only
  trial → recurring)
- ❌ Family Sharing — would halve subscription revenue without UX gain
- ❌ Generic adult nutrition mode — scope-creep; the value is in
  pregnancy/lactation-specific math
- ❌ In-app meal photos retained server-side — photos go to Claude for
  analysis only, never stored
