---

kanban-plugin: board

---

## Backlog

- [ ] **Component granularity per meal** · Sarah + Corina (2) · #P1 · [[beta-feedback-log#2026-06-17 → 2026-06-18 · Sarah (T7) · Build +33 → +35 · WhatsApp|→ Log]]
	Sarah wants to see, per meal, which component contributed which micronutrient: "the iodine in my porridge: oats, flaxseed, or walnuts?". She uses NourishMe primarily to LEARN food patterns, not just track totals, so a coach-on-demand answer is not enough; she wants the breakdown inline on every meal card. Corina is the second voice per the View 2 table; she has no dedicated chronological item on this.
- [ ] **More than 3 micros + dedicated tab** · Sarah + Isabella (2) · #P1 · [[beta-feedback-log#2026-06-17 → 2026-06-18 · Sarah (T7) · Build +33 → +35 · WhatsApp|→ Log]] ^wdvlqx
	Both want to see more nutrients than the three that fit in the diary header. Sarah's preferred structure: keep three prominent in the header for the daily glance and add a dedicated tab with all selected micros for the deeper view. Isabella hints at the same need via her "history tiles show only kcal" report.
- [ ] **Daily-weight + auto kcal-adjust** · Corina (1) · #P2 · [[beta-feedback-log#2026-06-17 → 2026-06-18 · Corina (T3) Round 2 · Build +33 → +35 · WhatsApp|→ Log]]
	Corina wants to type her morning weight (regular scale, no smart-scale integration) and have the daily kcal target react accordingly: "eat less today" or "ok to eat more". Per scope: the input mechanism is in scope as kcal calibration; trend/streak UI stays out of scope.
- [ ] **Water tap counter** · Corina (1) · #P2 · [[beta-feedback-log#2026-06-17 → 2026-06-18 · Corina (T3) Round 2 · Build +33 → +35 · WhatsApp|→ Log]]
	Corina wants two tap-icons under the diary header (her glass, her bottle), each with a custom ml setting. No reminders, no streak UI: just hydration as a daily status counter that fits her chaotic-day reality.
- [ ] **German banner in EN supplement form** · Rebecca (1) · #P2
	The supplement form's coaching-not-yet-enabled banner appears in German while the rest of the form (Name, Folate, Iron, etc.) is in English. There's also a secondary suspicion: the warning shows even though onboarding consent was given, which needs separate investigation. (Source: View 2 table; no chronological block for Rebecca yet.)
- [ ] **Pattern-avoidance weekly coach** · Corina (1) · #P3 · [[beta-feedback-log#2026-06-17 → 2026-06-18 · Corina (T3) Round 2 · Build +33 → +35 · WhatsApp|→ Log]]
	Corina wants a behaviour-pattern coach that names trends across the week, not just per-day micronutrient-deficit nudges. Her example: "hey, you've had a lot of sugar this week". Weekly-review style, not real-time meal advice.
- [ ] **Item list mixed languages when re-tracking** · Lotte (1) · #P3 · [[beta-feedback-log#2026-06-19 · Lotte (T11) · TestFlight (current beta) · WhatsApp text|→ Log]]
	When Lotte tries to re-log her daily Müsli, the suggestion list shows items in mixed languages because each entry was saved in whatever language it came in with (typed in DE one day, EN another, French via barcode). This is the downstream effect of the scan-time item in Warten auf Testerin; it might resolve once names are normalised at scan time, or it might need a display-side fallback for already-saved items.
- [ ] **Beta-Bug "bundled scan + text" ordering** · #code #mittel
	A tester reported that when several entries are saved as a bundle and a text entry follows, the text entry ends up at the top of the day instead of at its actual time. We have never reproduced the exact symptom; one provable ordering bug (the Mitternachts-Bug, now Shipped) was fixed but it is unclear whether that was the same one. Needs a real repro before any further fix.
- [ ] **ThreadRepository.add() race** · #code #mittel
	The repository's add method does an unguarded read-modify-write on the per-day key. Under fast bundle-save flows, two concurrent adds can read the same starting state and one will overwrite the other. Hard to test deterministically; the right fix is probably a guarded write, but the current user impact is theoretical, not a confirmed user-visible bug.
- [ ] **Tages-Aggregation provider tests** · #test
	The provider layer that computes the daily totals shown to the user has no test coverage. These are the numbers the user trusts most ("how many kcal did I log today"), so a regression here would be high-impact even if low-likelihood. *Source too thin for more detail.*
- [ ] **Coach-Kombinier-Logik tests (submitMeals)** · #test
	The submitMeals path combines multi-meal logs into a single coach call, including sums and the daily-total anchor. No unit tests today; bugs here would silently affect the coach prompt the model receives. *Source too thin for more detail.*
- [ ] **Repository-CRUD tests (Hive-Harness)** · #test
	Meal, favorite and weight repositories have no integration tests against a Hive harness. Their CRUD paths are the primary persistence layer and would benefit from a focused test suite. *Source too thin for more detail.*
- [ ] **Onboarding-Logik tests (reine Validierung)** · #test
	The pure validation and data-flow logic in the onboarding screens has no unit-test coverage today, even though the path is tested manually each TestFlight cycle. Tests would catch regressions in the data layer (not UI bugs). *Source too thin for more detail.*
- [ ] **_post Fehler-Mapping tests (HTTP-Mock)** · #test
	The _post helper that wraps the Worker API call has branching for timeouts and HTTP 401/429/500 responses, but no tests with a mocked HTTP layer. Failure modes here affect every coach interaction. *Source too thin for more detail.*
- [ ] **Final-Sign-off Safety-Grenzfälle** · #safety
	A handful of safety-rule edge cases are intentionally inclusive (e.g. salami included in the listeria warning) or intentionally soft (sage and peppermint as gentle hints rather than hard warnings). These borderline calls need a final review from the nutritionist before launch.
- [ ] **Freier Coach-Chat ohne Safety-Layer** · #safety #gross
	The safety rules currently only run on food parsing (scan + meal logging). Free-form coach chat, where the model could say anything in plain prose, is not gated by the safety layer at all. Larger structural gap, likely needs its own design pass before any code.
- [ ] **Energydrink-Keyword "effect" wirkungslos** · #safety #kosmetisch
	The energy-drink safety rule's secondary keyword "effect" only matches if a caffeine keyword has already matched first, which makes it functionally redundant: the rule was already firing on caffeine alone. Cosmetic, low priority.
- [ ] **Sentry PII scrubbing audit** · #dsgvo
	Sentry captures stack traces and breadcrumbs, and we have not verified that PII (especially health-context strings in error messages) is scrubbed before transmission, nor that consent for Sentry is captured. Verify and document, then close or escalate.
- [ ] **Data-subject-rights UI reachability** · #dsgvo
	The repositories have a `clearAll()` method that wipes local data (Article 17 GDPR) and the data is exportable in principle (Article 20), but neither is exposed in the UI. Verify reachability and add a Settings entry if missing.


## Warten auf Testerin

- [ ] **Weekly micronutrient overview** · Celine (1) · #P1 · JTBD question open · [[beta-feedback-log#2026-06-15 · Celine (T2) · Build +24 · WhatsApp text|→ Log]] ^mfk1r1
	Celine wants a dedicated weekly view of all relevant micronutrients (as % of the daily target, color-coded) so she can see "what's still missing this week" rather than getting day-by-day nags. Open question: is the purpose reassurance ("all green") or active gap-closing? That decides whether the surface is passive or recommendation-driven. We pre-floated a Sonntag-Recap push, also pending her confirmation.
- [ ] **Iodine-gap nag trigger tuning** · Celine (1) · #P2 · JTBD question open · [[beta-feedback-log#2026-06-15 · Celine (T2) · Build +24 · WhatsApp text|→ Log]] ^jbqo1t
	Celine deliberately takes a Femibion variant without iodine, so the chronic "iodine low" nudge is correct on the data but exhausting on tone. A cooldown (e.g. once a week) and an opt-out toggle were floated in WhatsApp; the question still open is whether 1×/week is still too often (toggle as default?) and whether this applies only to iodine or to other deliberate non-supplements too.
- [ ] **Item language at scan time** · Lotte (1) · #P2 · JTBD question open · [[beta-feedback-log#2026-06-19 · Lotte (T11) · TestFlight (current beta) · WhatsApp text|→ Log]] ^0s7kpw
	Lotte scanned a nut mix and the app saved the product name in French (the product's source language) rather than her UI language (EN). Open question: should the ideal be "always show items in the UI language" or "give me a reliable re-track list, language doesn't matter as long as the entry is findable"? Those diverge on what we'd actually build.
- [ ] **DHA shown 0 from eggs** · Rebecca (1) · #P2 · JTBD question open ^l47km2
	The coach prose mentions DHA in eggs, but the structured DHA value in the meal entry stays at 0. Eggs typically deliver 30-90 mg DHA each, so 0 is wrong. Open question: should the fix populate the structured value to a realistic number, or should the coach stop mentioning nutrients that are not reflected in the data? Both are valid for different jobs-to-be-done. (Source: View 2 table; no chronological block.)
- [ ] **Trimester auto-advance from due date** · Rebecca (1) · #P3 · JTBD question open ^apse36
	Rebecca entered her trimester manually during onboarding and asked whether a due-date input could let the app auto-advance the trimester over time. Open question: is the "I'll have to update this myself in a couple of months" a concrete friction she actively expects to hit, or more a hypothetical observation while doing setup? That decides polish vs idea-backlog. (Source: View 2 table; no chronological block.)


## Explore

- [ ] **Holistic scroll-behavior audit (all flows)** · Vanessa (+ Isabella for #2) · #P1 · [[beta-feedback-log#2026-06-11 · Isabella Hoesch (T8) · TestFlight v18 · Screenshots|→ Log]] ^s7c7jg
	Two patch attempts on the day-switch scroll bug have not converged. The home screen has at least seven concurrent scroll dispatchers (newly-rendered meals, totals-delta, focused-day-change, scroll-to-meal, scroll-to-bottom-bump, initState bottom, retry loops) and the right next step is a single audit pass that maps every dispatcher against every user flow before any further code change. Output: a state-machine doc plus a single coordinating handler that owns scroll-on-day-or-meal-change. Acceptance: switching to a past day via the AppBar date picker must land the diary at the top of that day, not mid-conversation (Isabella's original repro, formerly the separate "Day-switch scroll race" Backlog card, now folded in here).


## Blocked

- [ ] **Paywall / Receipt-Quota tests** · #test · ⛔ blocked: Launch nicht nah ^989ba9
	The paywall and receipt-quota branching is pure logic (no UI dependencies) and directly tied to revenue, but has no unit-test coverage today. Blocked: paywall/monetisation only goes live at launch, so the tests wait until that surface is final. *Source too thin for more detail.*


## Geplant



## Bau



## Review & Test



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
{"kanban-plugin":"board","list-collapse":[false,false,false,false,false,false,false,true,false]}
```
%%