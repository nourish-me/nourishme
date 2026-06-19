# Beta Feedback Log

Collection point for tester voices from the beta phase. One block per session, sorted chronologically. **Internal document** - real names are in here so Vanessa can trace per-tester what needs to be addressed where. Do NOT share in demo screenshots or public repos.

**Pattern rule:** single voices are noted but NOT acted on invasively right away. Only when two or more testers independently raise the same point does it become a UI/feature change. Exception: no-brainer improvements that benefit every tester (prompt sharpening, coach tone, safety corrections) go in directly.

## Legend

**Type:**
- 🐛 Bugfix - broken behaviour or wrong data, usually small to medium
- 💎 Polish - UX/tone/trigger fine-tuning, usually small
- 🚀 Feature - new mechanic, usually larger

**Status:**
- ✅ fixed
- 🟡 planned (open)
- ❓ waiting on tester follow-up
- 🔬 single voice, collecting
- ⛔ closed (closed-by-tester / clarified / wontfix / out-of-scope)

**Build column:**
- `+36` = already shipped
- `→ +37` = planned for build
- `→ ?` = not yet scheduled

## View 1 - Master Long List (sorted by priority)

Order: **priority descending** (P1 → P3), within priority: bugs + polish (small) before features (large). All shipped fixes are consolidated in the "Done" table at the bottom; closed/clarified items follow.

### P1 - open

| # | Item | Tester | Type | Status | Build | Prio | Reason |
|---|---|---|---|---|---|---|---|
| 2 | Day-switch scroll race / past-day-scroll | Isabella | 🐛 | 🟡 | → +37 | P1 | scroll race condition, related to F3, banner pattern planned |
| 3 | kcal estimate calibration (over/under) | Simone + Henrike | 🐛 | ❓ | → ? | P1 | Henrike's piece fixed in +36 (single-food anchors); need Simone v36 retest before deciding on main-dish anchor |
| 4 | Component granularity per meal | Sarah + Corina | 🚀 | 🟡 | → +39 | P1 | 2 voices, data model extension |
| 5 | More than 3 micros + dedicated tab | Sarah + Isabella | 🚀 | 🟡 | → +39 | P1 | 2 voices, header overflow |
| 6 | Weekly micronutrient overview (dedicated tab) | Celine | 🚀 | 🟡 | → +39 | P1 | Task #107, partial addressing in +36 history pills |

### P2 - open

| # | Item | Tester | Type | Status | Build | Prio | Reason |
|---|---|---|---|---|---|---|---|
| 15 | Coach guardrail for daily-target frustration | Eva | 💎 | 🟡 | → +37 | P2 | coach tone, "daily target is weekly average" |
| 16 | Repeat-meal discovery (favourites via coach hint) | Eva + Svenja + Corina | 💎 | 🟡 | → +37 | P2 | 3 voices, discovery cluster |
| 17 | Iodine-gap nag trigger tuning (supplement w/o iodine) | Celine | 💎 | ❓ | → +37 | P2 | clinical micro for lactation; waiting on Celine's preferred trigger mode |
| 18 | Daily-weight + auto kcal-adjust | Corina | 🚀 | 🟡 | → +37 | P2 | per scope: input mechanism for kcal calibration, no trend/streak UI |
| 19 | Workout/sport sessions in kcal balance | Julia + Corina | 🚀 | 🟡 | → +38 | P2 | 2 voices; per scope: kcal-input, not fitness tracker (no streak/trend UI) |
| 20 | Multi-photo bulk flow for afternoon catch-up | Celine | 🚀 | 🟡 | → +38 | P2 | Task #105, new save flow |
| 21 | Water tap counter | Corina | 🚀 | 🟡 | → +38 | P2 | per scope: hydration daily status (raised need in lactation), no streak UI |

### P3 - open

| # | Item | Tester | Type | Status | Build | Prio | Reason |
|---|---|---|---|---|---|---|---|
| 25 | Supplement setup timeout on Google screenshot | Henrike | 🐛 | ❓ | → ? | P3 | edge case, vision model with unusual source, tester follow-up pending |
| 26 | Time picker AM/PM cumbersome | Julia | 💎 | 🟡 | → +40 | P3 | single voice, polish round |
| 27 | Pattern-avoidance weekly coach | Corina | 🚀 | 🟡 | → +38 | P3 | single voice, new coach mode |

### Done (history, all priorities)

Sorted by Prio descending, then by Build descending.

| # | Item | Tester | Type | Status | Build | Prio | Reason |
|---|---|---|---|---|---|---|---|
| 1 | Lactation profile gets pregnancy warnings | Isabella + Julia | 🐛 | ✅ | +36 | P0 | 2 voices, clinical safety, wrong phase-gate in LLM |
| 7 | Retro-logging discovery (header pill) | Eva + Svenja + Isabella | 💎 | ✅ | +36 | P1 | 3 voices, discovery cluster |
| 11 | kcal single-food too high (egg 155 vs 100) | Henrike | 🐛 | ✅ | +36 | P1 | single-food anchors in prompt |
| 8 | DHA hallucination 325% from porridge | Sarah | 🐛 | ✅ | +35 | P1 | clinical safety, ALA-to-DHA error |
| 9 | Shell-pasta confusion (Conchigliette) | Simone | 🐛 | ✅ | +34/+35 | P1 | phantom listeria warning |
| 10 | Push reminder fires despite logging | Simone + Corina | 🐛 | ✅ | +35 | P1 | 2 voices |
| 14 | Salad midwife disclaimer | Corina | 💎 | ✅ | +35 | P1 | per-meal tone hardening |
| 12 | Photo recognition inaccurate | Eva | 💎 | ✅ | up to +33 | P1 | prompt sharpening across multiple builds |
| 13 | Backcamembert false-positive raw-milk warning | Celine | 🐛 | ✅ | old | P1 | heat marker in SafetyRules |
| 23 | Onboarding daily-volume slider as "estimated card" | Isabella | 💎 | ✅ | +36 | P2 | single voice, no-brainer polish |
| 24 | History tiles show micros with status icons | Isabella + Sarah + Corina | 💎 | ✅ | +36 | P2 | 3 voices, partial addressing |
| 22 | Snack recommendations too frequent | Corina | 💎 | ✅ | +25 | P2 | settings toggle for meal structure |

### Closed / clarified / out-of-scope / waiting (no action item)

| # | Item | Tester | Status | Comment |
|---|---|---|---|---|
| 28 | Cycle / period awareness | Corina | ⛔ | out-of-scope per CLAUDE.md Produkt-Scope; moved to `docs/idea-backlog.md`. Revisit when maintenance phase grows or 3+ voices ask. |
| 29 | Delete bug | Corina | ⛔ | closed-by-tester |
| 30 | Daily calorie estimate too high (2600 kcal) | Corina | ⛔ | clarified, correctly computed from Mifflin + activity + lactation supplement |
| 31 | "Coffee remember" feature | Corina | ❓ | likely favourites discovery problem (covered by #16) |
| 32 | Forgets to log because phone isn't at table | Eva | ❓ | push reminder discovery (covered by reminder work) |
| 33 | Praise even for chocolate lands well | Celine | ✅ | confirmation of non-judgemental tone |

---

## View 2 - Per-Tester View

For per-tester update messages: what each tester reported, with status and build.

### Eva (T1) — lactation, often out and about with toddler

| Feedback | Type | Status | Build |
|---|---|---|---|
| Photo recognition inaccurate | 💎 | ✅ | up to +33 |
| Retro-logging discovery (header pill) | 💎 | ✅ | +36 |
| Daily-target frustration (snacks forgotten, coach guardrail) | 💎 | 🟡 | → +37 |
| Repeat-meal discovery (favourites via coach) | 💎 | 🟡 | → +37 |
| Forgets to log because phone isn't at table | - | ❓ | - |

### Celine (T2) — lactation, works at a school

| Feedback | Type | Status | Build |
|---|---|---|---|
| Backcamembert false-positive raw-milk warning | 🐛 | ✅ | old |
| Praise even for chocolate (tone confirmation) | - | ✅ | - |
| Iodine-gap nag trigger tuning | 💎 | ❓ | → +37 |
| Multi-photo bulk flow for afternoon | 🚀 | 🟡 | → +38 |
| Weekly micronutrient overview (dedicated tab) | 🚀 | 🟡 | → +39 (partial in +36) |

### Corina (T3) — lactation, 1-year-old child

| Feedback | Type | Status | Build |
|---|---|---|---|
| Salad midwife disclaimer | 💎 | ✅ | +35 |
| Push reminder fires despite logging | 🐛 | ✅ | +35 |
| Snack recommendations too frequent | 💎 | ✅ | +25 |
| History tiles show micros | 💎 | ✅ | +36 |
| Repeat-meal discovery (favourites) | 💎 | 🟡 | → +37 |
| Daily-weight + auto kcal-adjust | 🚀 | 🟡 | → +37 |
| Workout/sport sessions in kcal balance | 🚀 | 🟡 | → +38 |
| Water tap counter | 🚀 | 🟡 | → +38 |
| Pattern-avoidance weekly coach | 🚀 | 🟡 | → +38 |
| Component granularity per meal | 🚀 | 🟡 | → +39 |
| Cycle / period awareness | - | ⛔ | out-of-scope (see idea-backlog) |
| Delete bug | - | ⛔ | closed-by-tester |
| Daily calorie estimate 2600 kcal | - | ⛔ | clarified |
| "Coffee remember" feature | - | ❓ | - |
| Recruitment of 9 lactating moms | - | strategic | - |

### Svenja (T5) — new

| Feedback | Type | Status | Build |
|---|---|---|---|
| Retro-logging discovery (header pill) | 💎 | ✅ | +36 |
| Repeat-meal discovery (favourites via coach) | 💎 | 🟡 | → +37 |

### Simone (T6) — lactation

| Feedback | Type | Status | Build |
|---|---|---|---|
| Shell-pasta confusion (Conchigliette) | 🐛 | ✅ | +34/+35 |
| Push reminder fires despite logging | 🐛 | ✅ | +35 |
| kcal estimate too low (320 vs 555) | 🐛 | ❓ | → ? |

### Sarah (T7) — lactation, Folio supplement

| Feedback | Type | Status | Build |
|---|---|---|---|
| DHA hallucination 325% from porridge | 🐛 | ✅ | +35 |
| Coach chat sees micros + supplements | 💎 | ✅ | +35 |
| Component granularity per meal | 🚀 | 🟡 | → +39 |
| More than 3 micros + dedicated tab | 🚀 | 🟡 | → +39 |

### Isabella Hoesch (T8) — TestFlight, iPhone 11

| Feedback | Type | Status | Build |
|---|---|---|---|
| Lactation profile gets pregnancy warnings | 🐛 | ✅ | +36 |
| Onboarding daily-volume slider as "estimated card" | 💎 | ✅ | +36 |
| History tiles show micros with status icons | 💎 | ✅ | +36 |
| Retro-logging discovery (pizza for yesterday) | 💎 | ✅ | +36 |
| Day switch lands at end of today's chat | 🐛 | 🟡 | → +37 |
| More than 3 micros + dedicated tab | 🚀 | 🟡 | → +39 |

### Henrike Böckmann (T9) — TestFlight, iPhone 16 Pro

| Feedback | Type | Status | Build |
|---|---|---|---|
| kcal single-food too high (egg 155 vs 100) | 🐛 | ✅ | +36 |
| Supplement setup timeout on Google screenshot | 🐛 | ❓ | → ? |

### Julia Mayer (T10) — TestFlight, iPhone 14 Pro

| Feedback | Type | Status | Build |
|---|---|---|---|
| Lactation profile gets pregnancy warnings | 🐛 | ✅ | +36 |
| Time picker AM/PM cumbersome | 💎 | 🟡 | → +40 |
| Workout/sport sessions in kcal balance | 🚀 | 🟡 | → +38 |

---

## Pattern Clusters (reference)

Which themes were mentioned how often. For pattern-rule decisions.

| Cluster | Voices | Type | Severity |
|---|---|---|---|
| ⚠️ Safety phase: lactation profile gets pregnancy warnings (fixed +36) | 2 (Isabella + Julia) | 🐛 | **P0** |
| kcal estimate calibration (over/under) | 2 (Henrike + Simone) | 🐛 | P1 |
| Retro-logging discovery (fixed +36) | 3 (Eva + Svenja + Isabella) | 💎 | P1 |
| Micronutrient visibility + depth | 4 (Isabella + Sarah ×2 + Corina) | 🚀 | P1 |
| Repeat-meal discovery / favourites | 3 (Eva + Svenja + Corina) | 💎 | P2 |
| Activity / workout / daily-calorie-adjust | 2 (Julia + Corina) | 🚀 | P2 |
| Water tracking | 1 (Corina) | 🚀 | P2 |
| Weight tracking + auto-adjust | 1 (Corina) | 🚀 | P2 |
| Picker UX (time + date) | 1 (Julia) | 💎 | P3 |
| Supplement setup robustness (timeout) | 1 (Henrike) | 🐛 | P3 |
| Cycle / period awareness | 1 (Corina) | ⛔ | out-of-scope, see idea-backlog |
| Onboarding daily-volume discoverability (fixed +36) | 1 (Isabella) | 💎 | P3 |
| Pattern-avoidance weekly coach | 1 (Corina) | 🚀 | P3 |

---

## Code Bugs (separate from tester feedback)

From the code review session:

| Severity | Finding | Status |
|---|---|---|
| High | **Protein target with overweight** was wrong in coach path. Reported by dietitian. | ✅ fixed (`proteinTargetGrams`) |
| High | **Micronutrient cast** `(v as num)` could crash meal save. | ✅ fixed (`_parseMicronutrients`) |
| Medium | **Midnight ordering bug**. | ✅ fixed (`coachAnchorFor`) |
| Medium | **Kombucha** triggered the algae rule incorrectly. | ✅ fixed (exclusion) |
| Medium | **Beta bug "bundled scan + text lands at top"** - reported, never reproduced. | 🐛 open |
| Medium | **`ThreadRepository.add()`** race on rapid bundle save. | 🐛 open, hard to test deterministically |

---

## Open Items Without Tester Status

- 🐛 F3 past-day scroll: highlight pulse as patch in +35, real fix still open
- 💎 A6 capsule math: prompt hardening in +34/+35, model adherence to verify (Henrike tested Femibion)
- ✅ Salad midwife bug: per_meal hardening in +35, Vanessa tested herself

## Known Limitations (wontfix-discussed)

- Push reminder with <1 min lead time: iOS system race, not app-fixable (Corina's test with 1-min lead)
- Progressive disclosure in Settings: was never in, won't be added back (decided by Vanessa)

---

## Detail Blocks (chronological by session)

Original notes per session as a detail view. View 1 + View 2 above aggregate from this.

## 2026-06-15 · Eva (T1) · Build +24 · voice message

Profile: lactating mother, often out and about with toddler.

1. **Photo recognition inaccurate** (status: in-progress, no-brainer)
   - Example A: "plums with cream" instead of blueberries with yogurt.
   - Example B: salad with cucumber/tomato/nuts → small items not recognised.
   - Planned: sharpen photo prompt, inject brand history.

2. **Forgets to log because phone isn't at the table** (status: waiting)
   - Discovery problem with push reminders.

3. **Retroactive logging - how?** (status: open, PATTERN Eva+Svenja+Isabella)
   - Exists (AppBar day picker), discovery problem.

4. **Daily target not reached, small snacks forgotten** (status: in-progress)
   - Coach "daily target is a weekly average" as guardrail. Plus explain favourites feature.

---

## 2026-06-15 · Celine (T2) · Build +24 · WhatsApp text

Profile: works at a school, relaxed eater, looks at data curiously rather than tracking meticulously.

1. **Multi-photo upload for afternoon catch-up** (status: open)
   - Preference: save all photos at once + edit individually → bulk queue.
   - Task #105 created.

2. **Backcamembert false-positive raw-milk warning** (status: ✅ fixed)
   - Heat marker added to SafetyRules.

3. **Praise even for chocolate lands well** (status: ✅ fixed, confirmation)
   - Confirms non-judgemental tone works.

4. **Iodine systematically low** (status: waiting/in-progress)
   - Has Femibion-style supplement (no iodine). Values are REAL.
   - Micronutrient-gap trigger is too naggy when nutrient is chronically deficient. Task #106.
   - Confirmed: weekly overview would be great (Task #107).
   - Donut sporadic → passive notification > prominent donut status.

---

## 2026-06-15 · Corina (T3) · Build before +24 · WhatsApp voice + follow-up

Profile: lactating mother, ~1-year-old child, working (school), uses CHAT path to log.

1. **Backfill / coach doesn't know meal time** (status: in-progress, PATTERN Celine+Corina)
   - She logs late, coach reacts at the wrong time of day.
   - Chat path: chat_base_de/en now detects past-meal language.

2. **Delete bug** (status: closed-by-tester)

3. **"Coffee remember" feature** (status: waiting)
   - Likely favourites discovery problem.

4. **Calorie estimate too high (2600 kcal)** (status: clarified, no action)
   - Correctly computed from Mifflin + activity + lactation supplement.

5. **Snack recommendations too frequent** (status: ✅ fixed)
   - Task #108: settings toggle for meal structure, shipped in +25.

6. **Recruitment of 9 lactating mothers** (status: open, strategic)

---

## 2026-06-16 · Svenja (T5) · Build +24 · WhatsApp text

Profile: new, one message so far.

1. **Retro-logging discovery: "log food for the day before"** (status: open, PATTERN Eva+Svenja+Isabella)
   - Feature exists, discovery problem.

---

## 2026-06-17 · Simone (T6) · Build +33 → +34/+35 · WhatsApp

Profile: lactating mother.

1. **Shell-pasta bug: photo confused with mussels** (status: ✅ fixed in +34/+35)
   - Photo of chicken soup with Conchigliette → coach interpreted as mussels, phantom listeria warning in the diary.
   - Pasta-shape anchor in parse prompt (+34) + safety-layer filter + rawAnimal exclusion (+35).
   - Verification pending (Simone was still on v33 at first retest, should retest the same photo on v35).

2. **Calorie estimate too low (320 vs ~555)** (status: open, PATTERN Simone+Henrike)
   - First estimate of Conchigliette soup was 320 kcal, real ~555 for 380g.
   - Henrike reports the opposite: single items too high.

3. **Push reminder fires despite meal log** (status: ✅ fixed in +35)
   - Default reminder times (8am breakfast) fired even though she had logged earlier.
   - recomputeSkipsForToday built, verification pending.

---

## 2026-06-17 → 2026-06-18 · Corina (T3) Round 2 · Build +33 → +35 · WhatsApp

Profile: same as T3, now with more detailed feedback after a testing round.

1. **Daily-weight logging with hard adjustment** (status: open)
   - Manual entry in the morning (normal scale, no smart scale).
   - Wants the calorie target to auto-adjust.
   - Per scope: input mechanism for kcal calibration, no trend/streak UI in the app.

2. **Cycle / period context** (status: ⛔ out-of-scope per CLAUDE.md Produkt-Scope, moved to idea-backlog)

   > „You retain more water in certain phases"
   >
   > „horrible PMS with crazy cravings"

   - Wanted the app to know the cycle (manually or via Apple Health).
   - Decision: cycle is its own lifecycle phase; revisit when maintenance phase grows or 3+ voices ask. See `docs/idea-backlog.md`.

3. **Food-avoidance pattern coach** (status: open)
   - „du isst zu viel Zucker"-style coaching, not micronutrient-deficit style.
   - Coach weekly review with pattern detection.

4. **Water tracking** (status: open)
   - Tap-glass icon, personalisable („not all glasses are equal").
   - Proposed: setting for „1 glass = X ml" + „1 bottle = Y ml", two icons under the diary header.
   - Per scope: in scope as hydration daily status (raised need in lactation), no streak UI.

5. **Push reminder fires despite meal log** (status: ✅ fixed in +35)
   - Same bug as Simone. To verify on v35.

---

## 2026-06-17 → 2026-06-18 · Sarah (T7) · Build +33 → +35 · WhatsApp

Profile: lactating mother, has Folio supplement.

1. **DHA hallucination 325% from porridge** (status: ✅ fixed in +35)
   - Porridge with walnuts + flaxseed → model counted ALA as DHA.
   - DHA zero rule in parse prompt + coach now sees micros + supplements in chat context.
   - Sarah confirmed the v35 fix:

   > „Bei Jod sehe ich jetzt aus welcher Mahlzeit es kommt" ✅

2. **Component granularity per meal** (status: open, PATTERN Sarah+Corina)

   > „Bei Jod sehe ich jetzt aus welcher Mahlzeit es kommt, weiß aber noch nicht aus welchem Bestandteil."

   - Wants per-component (oats/walnuts/almond milk) view of who contributes what.

3. **More than 3 micros + dedicated tab** (status: open, PATTERN Sarah+Isabella)
   - Today: max 3 micros in header. Wants more data without header overflow.
   - Suggestion: top 3 prominent, dedicated tab for all selected.

---

## 2026-06-11 · Isabella Hoesch (T8) · TestFlight v18 · Screenshots

Profile: iPhone 11, iOS 26.4.2, sends structured TestFlight feedback.

1. **Onboarding daily-volume slider misunderstood** (status: open)

   > „Bei Babies die keine Flasche nehmen schwer zu beantworten."

   - Doesn't realise the value is an output of the previous questions.
   - Solution proposal: visual separation as „calculated card" with different background.

2. **Day switch lands at end of TODAY's chat** (status: open)
   - Expected: start of selected day's chat.
   - Scroll race condition on day switch. Related to F3 (past-day scroll).

3. **⚠️ Lactation profile shows pregnancy warnings** (status: open at time of report, fixed in +36)
   - Red beets and mozzarella carpaccio → warning „avoid raw-milk cheese in pregnancy" although Isabella set lactation.
   - Hypothesis: LLM layer too defensive or deterministic rule has wrong phase gate.

4. **Cannot add retroactive entry** (status: open, PATTERN Eva+Svenja+Isabella)
   - Pizza from yesterday → couldn't set the date. Discovery problem.

5. **History tiles show only kcal, not micros** (status: open at time, addressed in +36)

   > „Tägliche Übersicht über meine Nährwerte und was noch fehlt cool."

   - Plus: „nährstoffreiche Ernährung motiviert mehr als ein Kalorienziel."

---

## 2026-06-13 → 17 · Henrike Böckmann (T9) · TestFlight v20/v33 · Screenshots

Profile: iPhone 16 Pro, iOS 26.5.

1. **Supplement setup timeout on Google search screenshot** (status: open)
   - Searched for Femibion via Google and uploaded the screenshot (not a photo of the label).
   - Coach response:

   > „The coach is taking too long, try again in a moment."

   - Likely: vision model struggled with the unusual source.

2. **kcal estimate too high (egg: 155 vs ~100)** (status: open at time, fixed for single items in +36)

   > „Grundsätzlich kommt es mir so vor dass eher über- als unterschätzt wird."

   - Conflict with Simone, who reported under-estimate on a German main dish.
   - Hypothesis: model is generous on single items, conservative on complex dishes.

---

## 2026-06-17 · Julia Mayer (T10) · TestFlight v33 · Screenshots

Profile: iPhone 14 Pro, iOS 26.5.

1. **Time picker AM/PM cumbersome** (status: open)

   > „Das Auswählen der Uhrzeit (morgens oder der Switch auf abends) wird nicht immer übernommen."

   - Suggestion: a morning/evening slider at the top, then a single clock face instead of two.

2. **⚠️ Lactation profile shows pregnancy warnings** (status: open at time, fixed in +36)

   > „Ich habe angegeben, dass ich eine stillende Mutter bin. Trotzdem erhalte ich Warnungen für Lebensmittel, die in der Schwangerschaft nicht erlaubt sind."

   - Screenshot shows a pancake meal with smoked-salmon/ham/raw-milk related warning.

3. **Workout/sport sessions in kcal balance** (status: open, PATTERN Julia+Corina)
   - Activity level hard to set at the start because it varies.
   - Wants to add sport sessions as kcal-plus.
   - Per scope: in scope as kcal-input mechanism, not as fitness tracker (no streak/trend UI).
