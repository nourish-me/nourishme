---

kanban-plugin: board

---

## Backlog

- [ ] **Algae safety false-positive on "Algenöl" (substring "algen")** · Patricia (1) · #P1 #safety · [[beta-feedback-log#2026-06-21 · Patricia (T13) · current beta · WhatsApp|→ Log]]
	The pregnancy-only algae rule (safety_rules.dart) matches "Algenöl" via the substring token "algen"; algaeExclusions only holds ["kombucha"]. Exactly the kombu/kombucha pattern. Refined DHA algae oil is a controlled, purified supplement, not raw seaweed, so the iodine/arsenic warning is both wrongly triggered and factually misleading here. Fix: add "algenöl" to algaeExclusions plus a warn-text nuance. Safety change, so a quick nutritionist confirm per the sign-off norm, but low-risk with the kombucha precedent.
- [ ] **Quick-reply chips suggest fish to vegetarians** · Lotte (1) · #P2 · [[beta-feedback-log#2026-06-21 · Lotte (T11) · current beta · WhatsApp|→ Log]]
	Lotte set Diet = Vegetarian but a coach quick-reply offered "I rarely eat fish or seafood". Root cause: followUpInstruction (EN/DE) carries "I rarely eat fish" as a literal example that the model echoes regardless of the diet line that is correctly in context. Small, safe fix: replace the literal example with diet-neutral ones.
- [ ] **Coach error messages hardcoded English (whole family)** · Vanessa (1) · #P2 #i18n
	Every CoachApiException message in claude_client.dart is hardcoded English (timeout :410, no-internet :415, connection :420, overloaded :432, unavailable :438/444/465) and surfaces verbatim in the DE app (coach_session_manager.dart:376, home_input.dart:541/1135). Same class as the supplement-banner i18n bug. Fix (option B): localize the whole error family at the callsites (isDe branch; claude_client has no BuildContext) and point the error bubble at the existing workaround (re-save the meal, or ask in chat). No dedicated retry button for now: the "T42 retry-loop" was the scroll retry, not a coach retry, so none exists today; add one only if timeouts recur.
- [ ] **DHA shown 0 from eggs** · Rebecca (1) · #P2 ^l47km2
	The coach prose mentions DHA in eggs, but the structured DHA value in the meal entry stays at 0. Eggs typically deliver 30-90 mg DHA each, so 0 is wrong. The fix direction (populate a realistic structured value vs stop the coach mentioning nutrients not reflected in the data) gets decided in Explore. (Source: View 2 table; no chronological block.)
- [ ] **Iodine-gap nag trigger tuning** · Celine (1) · #P2 · [[beta-feedback-log#2026-06-15 · Celine (T2) · Build +24 · WhatsApp text|→ Log]] ^jbqo1t
	Celine deliberately takes a Femibion variant without iodine, so the chronic "iodine low" nudge is correct on the data but exhausting on tone. Direction: a cooldown (e.g. once a week) plus an opt-out toggle for deliberately-skipped nutrients, so the same nag doesn't repeat daily. Open sub-questions (is 1×/week still too often, toggle as default? iodine-only or all deliberate gaps?) get resolved in Explore, no need to block on Celine's reply.
- [ ] **Item language at scan time** · Lotte (1) · #P2 · [[beta-feedback-log#2026-06-19 · Lotte (T11) · TestFlight (current beta) · WhatsApp text|→ Log]] ^0s7kpw
	Lotte scanned a nut mix and the app saved the product name in French (the product's source language) rather than her UI language (EN). The direction question (normalise to UI language vs a reliable findable re-track list regardless of language) gets resolved in Explore; pairs with the downstream "Item list mixed languages when re-tracking" card. No need to block on Lotte.
- [ ] **Item list mixed languages when re-tracking** · Lotte (1) · #P3 · [[beta-feedback-log#2026-06-19 · Lotte (T11) · TestFlight (current beta) · WhatsApp text|→ Log]]
	When Lotte tries to re-log her daily Müsli, the suggestion list shows items in mixed languages because each entry was saved in whatever language it came in with (typed in DE one day, EN another, French via barcode). This is the downstream effect of the scan-time item ("Item language at scan time", now in Backlog); it might resolve once names are normalised at scan time, or it might need a display-side fallback for already-saved items.
- [ ] **Stated time in free text not applied to entry timestamp** · Patricia (1) · #P2 · [[beta-feedback-log#2026-06-21 · Patricia (T13) · current beta · WhatsApp|→ Log]]
	Patricia told the app she ate at 9:00 but the entry was timestamped at submit time (22:47). The text time is never parsed; the manual time picker in the confirm screen exists but she missed it. Decision on depth: proposed approach is an optional "suggested_time_hhmm" field in the parse JSON that feeds the existing suggestedCreatedAt path (reused from EXIF). 1 voice so far.
- [ ] **Coach can't see name-only / onboarding supplements** · Julia (1) · #P2 · [[beta-feedback-log#2026-06-18 · Julia Mayer (T10) · App 1.0.0 (35) · TestFlight, iPhone 14 Pro, iOS 26.5|→ Log]]
	Julia set a daily supplement at setup; when she asked the coach whether it's enough, it didn't reference it. The supplement context block only emits supplements with parsed nutrient values, so a name-only entry (no label scan) is invisible. The two code reads disagree on whether onboarding supplements ever reach the coach (chat vs per-meal path), so this needs an Explore pass plus a tester question.
	❓ Offene Frage an Julia (T10): Etikett gescannt, oder Supplement-Name nur getippt? (gesendet 2026-06-21)
- [ ] **Freier Coach-Chat ohne Safety-Layer** · #safety #gross
	The safety rules currently only run on food parsing (scan + meal logging). Free-form coach chat, where the model could say anything in plain prose, is not gated by the safety layer at all. Larger structural gap, likely needs its own design pass before any code.
- [ ] **Final-Sign-off Safety-Grenzfälle** · #safety
	A handful of safety-rule edge cases are intentionally inclusive (e.g. salami included in the listeria warning) or intentionally soft (sage and peppermint as gentle hints rather than hard warnings). These borderline calls need a final review from the nutritionist before launch.
- [ ] **Sentry PII scrubbing audit** · #dsgvo
	Sentry captures stack traces and breadcrumbs, and we have not verified that PII (especially health-context strings in error messages) is scrubbed before transmission, nor that consent for Sentry is captured. Verify and document, then close or escalate.
- [ ] **Data-subject-rights UI reachability** · #dsgvo
	The repositories have a `clearAll()` method that wipes local data (Article 17 GDPR) and the data is exportable in principle (Article 20), but neither is exposed in the UI. Verify reachability and add a Settings entry if missing.
- [ ] **Broader micronutrient view (beyond the 3-micro header)** · Sarah + Isabella + Celine (3) · #P1 · [[beta-feedback-log#2026-06-17 → 2026-06-18 · Sarah (T7) · Build +33 → +35 · WhatsApp|→ Log]] · [[beta-feedback-log#2026-06-15 · Celine (T2) · Build +24 · WhatsApp text|→ Log]] ^wdvlqx
	Problem: the diary header shows only three micronutrients and several testers want the fuller picture. Sarah and Isabella want a dedicated tab listing all selected micros for the deeper view, with the header keeping three for the daily glance; Celine wants a weekly aggregate (% of daily target, colour-coded) to see "what's still missing this week" instead of day-by-day nags. Whether the surface becomes a dedicated micros tab, a weekly overview, or both is a plan-time decision, not now; Celine's open JTBD question (reassurance vs active gap-closing, plus the floated Sonntag-Recap push) gets resolved when we plan it. Formerly two cards (dedicated tab + weekly overview).
- [ ] **Component granularity per meal** · Sarah + Corina (2) · #P1 · [[beta-feedback-log#2026-06-17 → 2026-06-18 · Sarah (T7) · Build +33 → +35 · WhatsApp|→ Log]]
	Sarah wants to see, per meal, which component contributed which micronutrient: "the iodine in my porridge: oats, flaxseed, or walnuts?". She uses NourishMe primarily to LEARN food patterns, not just track totals, so a coach-on-demand answer is not enough; she wants the breakdown inline on every meal card. Corina is the second voice per the View 2 table; she has no dedicated chronological item on this.
- [ ] **Daily-weight + auto kcal-adjust** · Corina (1) · #P2 · [[beta-feedback-log#2026-06-17 → 2026-06-18 · Corina (T3) Round 2 · Build +33 → +35 · WhatsApp|→ Log]]
	Corina wants to type her morning weight (regular scale, no smart-scale integration) and have the daily kcal target react accordingly: "eat less today" or "ok to eat more". Per scope: the input mechanism is in scope as kcal calibration; trend/streak UI stays out of scope.
- [ ] **Water tap counter** · Corina (1) · #P2 · [[beta-feedback-log#2026-06-17 → 2026-06-18 · Corina (T3) Round 2 · Build +33 → +35 · WhatsApp|→ Log]]
	Corina wants two tap-icons under the diary header (her glass, her bottle), each with a custom ml setting. No reminders, no streak UI: just hydration as a daily status counter that fits her chaotic-day reality.
- [ ] **Trimester auto-advance from due date** · Rebecca (1) · #P3 ^apse36
	Rebecca entered her trimester manually during onboarding and wants a due-date input so the app auto-advances the trimester over time instead of her updating it by hand. Treated as a real no-brainer friction, not a hypothetical, so no need to wait on Rebecca to confirm. In scope: the trimester drives the pregnancy-phase recommendations. (Source: View 2 table; no chronological block.)
- [ ] **Pattern-avoidance weekly coach** · Corina (1) · #P3 · [[beta-feedback-log#2026-06-17 → 2026-06-18 · Corina (T3) Round 2 · Build +33 → +35 · WhatsApp|→ Log]]
	Corina wants a behaviour-pattern coach that names trends across the week, not just per-day micronutrient-deficit nudges. Her example: "hey, you've had a lot of sugar this week". Weekly-review style, not real-time meal advice.
- [ ] **Coach tip: algae oil needs fat for absorption** · Patricia (1) · #P3 · [[beta-feedback-log#2026-06-21 · Patricia (T13) · current beta · WhatsApp|→ Log]]
	Patricia notes DHA algae oil must be taken with a fat-rich meal to be absorbed (fat-soluble omega-3), a coaching point that's missing today. In scope as supplement coaching in the Communication-Layer. Pairs with the Algenöl safety-rule fix; decide whether the tip lives in the per-meal coach response or as a supplement-setting hint.
- [ ] **Protein target: UI macro split vs coach proteinTargetGrams diverge** · Patricia (1) · #P3 · [[beta-feedback-log#2026-06-21 · Patricia (T13) · current beta · WhatsApp|→ Log]]
	When a custom protein% is set (macro slider), the diary ring shows targetKcal × proteinPct / 4 while the coach reasons with proteinTargetGrams() (BMI-25-capped, phase-aware), so the two can disagree (Patricia saw 148 g in the ring, the coach used ~80 g). Confirmed not a calc error: Patricia had set the split herself. Design gap rather than a bug, downgraded to #P3: make the ring and the coach tell the same story (align the paths, or flag/clamp a custom % that exceeds the capped target).
- [ ] **Energydrink-Keyword "effect" wirkungslos** · #safety #kosmetisch
	The energy-drink safety rule's secondary keyword "effect" only matches if a caffeine keyword has already matched first, which makes it functionally redundant: the rule was already firing on caffeine alone. Cosmetic, low priority.
- [ ] **Beta-Bug "bundled scan + text" ordering** · #code #mittel
	A tester reported that when several entries are saved as a bundle and a text entry follows, the text entry ends up at the top of the day instead of at its actual time. We have never reproduced the exact symptom; one provable ordering bug (the Mitternachts-Bug, now Shipped) was fixed but it is unclear whether that was the same one. Needs a real repro before any further fix.
- [ ] **ThreadRepository.add() race** · #code #mittel
	The repository's add method does an unguarded read-modify-write on the per-day key. Under fast bundle-save flows, two concurrent adds can read the same starting state and one will overwrite the other. Hard to test deterministically; the right fix is probably a guarded write, but the current user impact is theoretical, not a confirmed user-visible bug.
- [ ] **Tages-Aggregation provider tests** · #test
	The provider layer that computes the daily totals shown to the user has no test coverage. These are the numbers the user trusts most ("how many kcal did I log today"), so a regression here would be high-impact even if low-likelihood. *Source too thin for more detail.*
- [ ] **Coach-Kombinier-Logik tests (submitMeals)** · #test
	The submitMeals path combines multi-meal logs into a single coach call, including sums and the daily-total anchor. No unit tests today; bugs here would silently affect the coach prompt the model receives. *Source too thin for more detail.*
- [ ] **_post Fehler-Mapping tests (HTTP-Mock)** · #test
	The _post helper that wraps the Worker API call has branching for timeouts and HTTP 401/429/500 responses, but no tests with a mocked HTTP layer. Failure modes here affect every coach interaction. *Source too thin for more detail.*
- [ ] **Repository-CRUD tests (Hive-Harness)** · #test
	Meal, favorite and weight repositories have no integration tests against a Hive harness. Their CRUD paths are the primary persistence layer and would benefit from a focused test suite. *Source too thin for more detail.*
- [ ] **Onboarding-Logik tests (reine Validierung)** · #test
	The pure validation and data-flow logic in the onboarding screens has no unit-test coverage today, even though the path is tested manually each TestFlight cycle. Tests would catch regressions in the data layer (not UI bugs). *Source too thin for more detail.*


## Explore

- [ ] **Holistic scroll-behavior audit (all flows)** · Vanessa (+ Isabella for #2) · #P1 · [[beta-feedback-log#2026-06-11 · Isabella Hoesch (T8) · TestFlight v18 · Screenshots|→ Log]] ^s7c7jg
	Two patch attempts on the day-switch scroll bug have not converged. The home screen has at least seven concurrent scroll dispatchers (newly-rendered meals, totals-delta, focused-day-change, scroll-to-meal, scroll-to-bottom-bump, initState bottom, retry loops) and the right next step is a single audit pass that maps every dispatcher against every user flow before any further code change. Output: a state-machine doc plus a single coordinating handler that owns scroll-on-day-or-meal-change. Acceptance: switching to a past day via the AppBar date picker must land the diary at the top of that day, not mid-conversation (Isabella's original repro, formerly the separate "Day-switch scroll race" Backlog card, now folded in here).


## Warten auf Testerin



## Blocked

- [ ] **Paywall / Receipt-Quota tests** · #test · ⛔ blocked: Launch nicht nah ^989ba9
	The paywall and receipt-quota branching is pure logic (no UI dependencies) and directly tied to revenue, but has no unit-test coverage today. Blocked: paywall/monetisation only goes live at launch, so the tests wait until that surface is final. *Source too thin for more detail.*


## Geplant



## Bau



## Review & Test

- [ ] **German banner in EN supplement form** · Rebecca (1) · #P2 · 🔧 i18n fixed, needs device verify
	The coaching-not-yet-enabled banner showed in German inside the otherwise-English supplement form. Root cause: the consent-gate exception in `claude_client.dart` carries a hardcoded German `userMessage` (the service layer has no l10n access), which leaked verbatim into the form. Fixed in `supplement_setup.dart` by localizing that one exception in the catch (EN/DE), matching the file's existing isDe pattern. The secondary "banner despite consent" suspicion is NOT a gate bug: the consent resolver reads the Hive box live on every call (see the `claudeClientProvider` comment plus `ConsentGate`), so a written consent is seen immediately. The most likely cause for Rebecca is a legacy profile onboarded before the mandatory Art. 9 consent step, whose box has no `health_data_consent_at`, which makes the banner technically correct. Open: a quick device check that the banner now renders in English. (Source: View 2 table; no chronological block for Rebecca yet.)


## Shipped

- [x] **Phase safety filter (lactation-only)** · Isabella + Julia (2) · #P1 · ✅ +36 · [[beta-feedback-log#2026-06-11 · Isabella Hoesch (T8) · TestFlight v18 · Screenshots|→ Log]]
	The app no longer applies pregnancy-specific safety rules (raw-milk cheese, smoked salmon, etc.) to lactation-only profiles. Isabella reported it on red beets and mozzarella, Julia on pancakes with smoked salmon. Was P0 clinical; fixed with a phase-discipline block in the parse prompt plus a deterministic filter that drops pregnancy markers when the profile is lactation-only.
- [x] **Retro-logging discovery (date as title)** · Eva + Svenja + Isabella (3) · #P1 · ✅ +36 · [[beta-feedback-log#2026-06-15 · Eva (T1) · Build +24 · voice message|→ Log]]
	All three testers tried to log a meal for a past day and didn't find the existing AppBar date picker. Solved by making the date itself the screen title with an arrow, plus a "VERGANGENER TAG" eyebrow and a "Heute" reset button on past days.
- [x] **kcal single-food anchors (egg, banana, apple)** · Henrike (1) · #P1 · ✅ +36 · [[beta-feedback-log#2026-06-13 → 17 · Henrike Böckmann (T9) · TestFlight v20/v33 · Screenshots|→ Log]]
	Henrike reported that a single boiled egg was estimated at 155 kcal, well above the realistic ~85. Fixed by adding single-food anchors to the parse prompt (egg ~85, banana ~105, apple ~95, etc.) with a hard ceiling, so the model can't overshoot common items.
- [x] **kcal estimate calibration (over/under)** · Simone + Henrike (2) · #P1 · ✅ +35-36 · [[beta-feedback-log#2026-06-17 · Simone (T6) · Build +33 → +34/+35 · WhatsApp|→ Log]]
	Simone hit the inverse problem on composite dishes (Conchigliette chicken soup at 320 kcal vs ~555 in reality) while Henrike saw single items overshoot. Both patterns fixed in +35/+36 with single-item anchors plus a separate density anchor for soups-with-pasta-or-starchy-side.
- [x] **DHA hallucination 325% from porridge** · Sarah (1) · #P1 · ✅ +35 · [[beta-feedback-log#2026-06-17 → 2026-06-18 · Sarah (T7) · Build +33 → +35 · WhatsApp|→ Log]]
	Sarah's porridge with walnuts and flaxseed was estimated at 325% of the daily DHA target because the model counted plant ALA as DHA. Fixed in +35 with a DHA-zero rule in the parse prompt and by giving the coach visibility into both micros and supplements during chat context.
- [x] **Shell-pasta confusion (Conchigliette)** · Simone (1) · #P1 · ✅ +34/+35 · [[beta-feedback-log#2026-06-17 · Simone (T6) · Build +33 → +34/+35 · WhatsApp|→ Log]]
	Simone photographed a chicken soup with shell-shaped Conchigliette pasta and the model identified mussels, triggering a phantom listeria warning. Fixed in +34/+35 with a pasta-shape anchor in the parse prompt plus a safety-layer filter that excludes obvious non-animal items from the listeria rule.
- [x] **Push reminder fires despite logging** · Simone + Corina (2) · #P1 · ✅ +35 · [[beta-feedback-log#2026-06-17 · Simone (T6) · Build +33 → +34/+35 · WhatsApp|→ Log]]
	Both reported that the default breakfast push (8am) still fired even though they had already logged a meal earlier that morning. Fixed in +35 with a recomputation pass that suppresses reminders for slots already covered by an entry.
- [x] **Salad midwife disclaimer** · Corina (1) · #P1 · ✅ +35
	The coach was attaching a generic "speak to your midwife" disclaimer to routine salad entries. Hardened the per-meal tone in +35 so this kind of deflection only fires on genuine safety questions, not on every greens-based meal. (Source: View 2 table; not in Corina's chronological blocks.)
- [x] **Photo recognition inaccurate** · Eva (1) · #P1 · ✅ up to +33 · [[beta-feedback-log#2026-06-15 · Eva (T1) · Build +24 · voice message|→ Log]]
	Eva's blueberry-yoghurt was read as "plums with cream" and her salads dropped small items entirely. Sharpened the photo prompt progressively across builds up to +33 (component enumeration, brand history injection) so common everyday meals come back correctly.
- [x] **Backcamembert false-positive raw-milk warning** · Celine (1) · #P1 · ✅ old · [[beta-feedback-log#2026-06-15 · Celine (T2) · Build +24 · WhatsApp text|→ Log]]
	Celine's baked camembert triggered the raw-milk warning even though baking neutralises the listeria risk. Fixed by adding a heat marker to the SafetyRules so cooked-camembert and similar prepared dishes pass through cleanly.
- [x] **Onboarding daily-volume "computed for you" card** · Isabella (1) · #P2 · ✅ +36 · [[beta-feedback-log#2026-06-11 · Isabella Hoesch (T8) · TestFlight v18 · Screenshots|→ Log]]
	Isabella didn't realise the daily-milk-volume slider was an OUTPUT derived from her earlier answers, not yet another input to invent. Fixed in +36 by moving the value into a "Berechnet für dich" card with a calculator icon, so the derived nature is visually obvious.
- [x] **History tiles show micros with status icons** · Isabella + Sarah + Corina (3) · #P2 · ✅ +36 · [[beta-feedback-log#2026-06-11 · Isabella Hoesch (T8) · TestFlight v18 · Screenshots|→ Log]]
	Three voices wanted at-a-glance nutrient status in the history view, not just kcal. In +36 each history tile now shows three micronutrient chips with status icons, so days with key gaps can be spotted in seconds. (Sarah's link is indirect via her "more than 3 micros" item; Corina is only in the View 2 table.)
- [x] **Multi-photo bulk flow for afternoon catch-up** · Celine (1) · #P2 · ✅ +27 · [[beta-feedback-log#2026-06-15 · Celine (T2) · Build +24 · WhatsApp text|→ Log]]
	Celine often catches up on logging in the afternoon and didn't want to repeat the single-photo flow per meal. Shipped earlier (+27) as a multi-photo picker that lands all selected photos in one review screen for editing and a single save; in Celine's case it was a discovery problem, not a missing feature.
- [x] **Coach guardrail for daily-target frustration** · Eva (1) · #P2 · ✅ +36 · [[beta-feedback-log#2026-06-15 · Eva (T1) · Build +24 · voice message|→ Log]]
	When Eva was below the daily kcal target in the evening, the coach pushed her to eat more, which read as guilt-tripping. The +36 coach prompt now frames the daily target as a weekly average and offers a gentle "small gaps are normal" line instead of a forced snack suggestion.
- [x] **Repeat-meal discovery (favourites SnackBar tip)** · Eva + Svenja + Corina (3) · #P2 · ✅ +36 · [[beta-feedback-log#2026-06-15 · Corina (T3) · Build before +24 · WhatsApp voice + follow-up|→ Log]]
	Three testers asked for some kind of "remember this meal" or "log my usual coffee" function without realising the favourites star already exists in the save sheet. Shipped in +36 as a one-time SnackBar tip on the first meal save pointing at the existing feature. (Eva's link is indirect via her "snacks forgotten" item; Svenja's only chronological item is retro-logging; Corina's link is via "Coffee remember".)
- [x] **Snack recommendations too frequent (Settings toggle)** · Corina (1) · #P2 · ✅ +25 · [[beta-feedback-log#2026-06-15 · Corina (T3) · Build before +24 · WhatsApp voice + follow-up|→ Log]]
	Corina wanted to opt out of the coach's snack suggestions, which felt prescriptive on top of her existing eating rhythm. Shipped in +25 as a Settings toggle for meal structure: classic / one snack / three meals / intuitive, and the coach respects the choice.
- [x] **Time picker AM/PM cumbersome (24h Cupertino)** · Julia (1) · #P3 · ✅ +37 · [[beta-feedback-log#2026-06-17 · Julia Mayer (T10) · TestFlight v33 · Screenshots|→ Log]]
	Julia reported that the AM/PM toggle in the meal-time picker didn't always commit her selection. Fully replaced in +37 with a Cupertino combined date+time wheel in 24-hour format and a native maximumDate=now bound, which also closes the future-time leak from the +36 re-test.
- [x] **App-Value-Confirmation** · Sarah + Lotte + Rebecca (3) · ✅ positive feedback · [[beta-feedback-log#2026-06-19 · Lotte (T11) · TestFlight (current beta) · WhatsApp text|→ Log]]
	Three independent voices confirmed the core value-prop: insight into what is missing in the diet (Sarah, Lotte), strong photo recognition and barcode scanning (Lotte), and that logging feels "suuuuper straightforward" while raising mindfulness (Rebecca). Treated as ✅ tone confirmation, not an action item. (Sarah's and Rebecca's quotes are in the View 2 table only.)
- [x] **Praise even for chocolate (tone confirmation)** · Celine (1) · ✅ tone confirmation · [[beta-feedback-log#2026-06-15 · Celine (T2) · Build +24 · WhatsApp text|→ Log]]
	Celine flagged that the coach praised her even when she ate chocolate, and that this lands well rather than feeling sycophantic. Treated as confirmation that the non-judgemental coach tone is working as intended; no fix needed.
- [x] **Cycle / period awareness** · Corina (1) · ⛔ out of scope (idea-backlog) · [[beta-feedback-log#2026-06-17 → 2026-06-18 · Corina (T3) Round 2 · Build +33 → +35 · WhatsApp|→ Log]]
	Corina asked for the app to take menstrual-cycle context into account (PMS cravings, water retention). Decision: out of scope, parked in the idea backlog because cycle is its own lifecycle phase with its own data model and specialised apps (Clue, Apple Health) handle it better. Revisit when the maintenance phase grows.
- [x] **Dynamic activity adjustment (HealthKit)** · Julia + Corina (2) · ⛔ parked in idea-backlog · [[beta-feedback-log#2026-06-17 · Julia Mayer (T10) · TestFlight v33 · Screenshots|→ Log]]
	Julia clarified by email that the static onboarding activity level doesn't match her variable real life ("good and bad days/weeks") and proposed Apple HealthKit as a source. Decision: out of scope for the current beta wave because HealthKit pulls OS permission flows and a non-trivial fallback UI; parked in the idea backlog with notify-when-revisiting on Julia and Corina. (Corina is the second voice via the activity pattern; only Julia has a chronological block.)
- [x] **Delete bug** · Corina (1) · ⛔ closed by tester · [[beta-feedback-log#2026-06-15 · Corina (T3) · Build before +24 · WhatsApp voice + follow-up|→ Log]]
	Corina reported a delete bug but closed it herself before we could reproduce. Kept in the log as ⛔ closed-by-tester so the report doesn't get re-opened by accident.
- [x] **Daily calorie estimate too high (2600 kcal)** · Corina (1) · ⛔ clarified · [[beta-feedback-log#2026-06-15 · Corina (T3) · Build before +24 · WhatsApp voice + follow-up|→ Log]]
	Corina questioned her ~2600 kcal target as too high. After walking through the Mifflin baseline plus her activity setting and the lactation supplement, the number checked out. Resolved as clarified; no app change.
- [x] **"Coffee remember" feature** · Corina (1) · ⛔ favourites discovery · [[beta-feedback-log#2026-06-15 · Corina (T3) · Build before +24 · WhatsApp voice + follow-up|→ Log]]
	Corina wanted the app to "remember her usual coffee" without having to log it fresh each morning. Most likely the favourites-discovery problem covered by the SnackBar tip (Shipped, above); treat as resolved unless she still reports friction after +36.
- [x] **Forgets to log because phone isn't at table** · Eva (1) · ⛔ push reminder discovery · [[beta-feedback-log#2026-06-15 · Eva (T1) · Build +24 · voice message|→ Log]]
	Eva said she misses meals in the log because her phone isn't always at the table. The right surface is the push reminder system; treated as a discovery problem covered by the reminder work rather than a separate feature.
- [x] **Supplement setup timeout (Google screenshot)** · Henrike (1) · ⛔ closed · [[beta-feedback-log#2026-06-13 → 17 · Henrike Böckmann (T9) · TestFlight v20/v33 · Screenshots|→ Log]]
	Henrike uploaded a Google search-result screenshot for Femibion (instead of a photo of the label) and the coach response timed out. On retest the upload worked, so the original timeout was most likely train connectivity rather than an app bug; closed.
- [x] **Protein target at high BMI** · #code #hoch · ✅
	The protein target for users with overweight BMI was computed as naive weight × 1.2 without a BMI-25 cap and ignoring the phase. Flagged by the nutritionist. Fixed with a single source-of-truth `proteinTargetGrams` plus tests.
- [x] **Micronutrient cast (v as num) crash** · #code #hoch · ✅
	The micronutrient parser cast every value with `(v as num)`, which would crash the entire meal-save flow if the model returned a string for a single nutrient. Fixed with a tolerant `_parseMicronutrients` that survives type mismatches, plus tests.
- [x] **Midnight ordering bug** · #code #mittel · ✅
	The coach reply for a meal logged late in the evening could drift to the next day in the thread order, appearing at the top of "today" instead of at the end of "yesterday". Fixed with a `coachAnchorFor` that anchors the coach bubble to its meal's day, plus a regression test.
- [x] **Kombucha wrongly triggered seaweed rule** · #code #mittel · ✅
	The seaweed safety rule was matching "kombucha" via the substring "kombu". Added an explicit exclusion plus a test, so kombucha no longer triggers a seaweed warning.
- [x] **Safety rules: nutritionist sign-off** · #safety · ✅
	A qualified nutritionist reviewed the full safety-rule set and the corrections were folded in (alcohol covered in lactation too, liver warning across full pregnancy, energy drinks, plus new rules for seaweed / quinine / wild-boar offal). Treated as ✅ for the systemic review; the remaining borderline calls are tracked separately in Backlog.
- [x] **Local-only data (Hive) audit baseline** · #dsgvo · ✅
	Audit confirmed: meal and profile data live locally in Hive, analytics goes to PostHog EU with anonymous IDs and no PII, and the Anthropic API key only exists inside the Worker. Treated as ✅ for the baseline architecture; the open items in Backlog (Sentry, data-subject rights) close the remaining gaps around this strong baseline.
- [x] **Art. 9 GDPR consent for health data** · #dsgvo · ✅ verified in code ^p40th8
	Explicit Art. 9 (2) lit. a consent is in place: a mandatory health-data consent checkbox in onboarding step 7 (lib/screens/onboarding_screen.dart), persisted via setHealthDataConsentAt, and every Anthropic call is gated by _assertHealthDataConsent / ConsentGate.canSendHealthData (lib/services/claude_client.dart, lib/services/consent_gate.dart), which blocks the call when consent is null. Covered by test/consent_gate_test.dart. Card described it as "not in place"; verified done 2026-06-21.
- [x] **Analytics opt-out → opt-in (EU)** · #dsgvo · ✅ verified in code ^jjl6zl
	Analytics is opt-in, default-off: PostHog only fires when getAnalyticsConsentAt() is non-null (lib/services/analytics_service.dart), the onboarding consent checkbox starts false and is separate from the health-data consent, and the Settings toggle clears to null on opt-out. Host is eu.i.posthog.com. Card described "defaults to on"; verified done 2026-06-21.
- [x] **LLM cost / margin audit** · ✅
	Cost audit showed a healthy margin: large prompts are already cached, total LLM cost lands around 0.30-0.60 EUR per intensive monthly user, well under 10% COGS. No action item; closed. *Source was a short note; this single sentence carries most of the substance.*


## Idea Backlog

- [ ] **Cycle / period awareness** · Corina · [[beta-feedback-log#2026-06-17 → 2026-06-18 · Corina (T3) Round 2 · Build +33 → +35 · WhatsApp|→ Log]]
	Menstruationszyklus-Kontext berücksichtigen (PMS-Cravings, Wasserretention), manuell oder via Apple Health. Geparkt, weil Cycle eine eigene Lifecycle-Phase mit eigenem Datentyp ist und während Schwangerschaft und dem Großteil der Stillzeit unterdrückt oder abwesend ist, der Nutzen also erst in einer Post-Wean-Maintenance-Phase landet, die wir heute kaum bespielen. Revisit, wenn Maintenance zur primären Fläche wird oder 3+ Stimmen danach fragen.
- [ ] **Dynamic activity adjustment (HealthKit)** · Julia + Corina · [[beta-feedback-log#2026-06-17 · Julia Mayer (T10) · TestFlight v33 · Screenshots|→ Log]]
	Apple HealthKit lesen (Active Energy + Workouts), um das tägliche kcal-Ziel zu flexen, mit 1-Tap-Fallback für Nicht-Watch-Userinnen, weil ein statisches Onboarding-Aktivitätslevel „gute und schlechte Tage/Wochen" nicht abbildet. Geparkt für diese Beta-Welle, weil HealthKit OS-Permission-Flows plus eine nicht-triviale Fallback-UI mitbringt und Richtung Fitness-Tracker driftet, während das statische Level den Scope-Test weiter besteht. Revisit, falls HealthKit aus anderem Grund dazukommt (Gewicht/Hydration-Auto-Import); Julia und Corina benachrichtigen.




%% kanban:settings
```
{"kanban-plugin":"board","list-collapse":[false,false,false,false,false,false,false]}
```
%%