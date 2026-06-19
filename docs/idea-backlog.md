# Idea Backlog

Out-of-scope feature ideas that surfaced during beta or other research. Intentionally not built into the current product but kept here for future revisit.

See `../CLAUDE.md` → "Produkt-Scope (Phase-Test)" for the in-scope test that defines what's in and what's out.

Format per entry: brief description, source (who/when), the scope verdict and reasoning, and conditions under which we might revisit.

---

## Cycle / Period Awareness

**Source:** Corina (T3), beta feedback 2026-06-17 → 2026-06-18, WhatsApp voice + follow-up.

**Request:**

> „You retain more water in certain phases"
>
> „horrible PMS with crazy cravings"

She wants the app to know her cycle so it can adapt recommendations (cravings, water retention, food preferences). Could be manual entry or imported from Apple Health.

**Scope verdict:** Out. PMS-driven cravings technically pass the in-scope test (they would change food recommendations), but cycle is its own lifecycle phase with its own data type. During pregnancy and most of lactation the cycle is suppressed or absent, so the benefit is concentrated in the post-wean Maintenance phase where we have minimal product surface today.

**Revisit when:** the Maintenance phase becomes a primary product surface, OR there are 3+ tester voices asking for cycle context. Until then, point testers to specialised apps (Clue, Apple Health) if they ask.

---

## Dynamic Activity Adjustment (HealthKit + Manual Fallback)

**Source:** Julia Mayer (T10), email reply 2026-06-19. Originally raised by Julia + Corina as "Workout/sport sessions in kcal balance" in earlier beta sessions; Julia's reply reframed the actual pain.

**Request:**

Julia (verbatim):

> „Ich erwarte keine krassen Fitness Funktionen. Ich denke nur, dass pauschal immer ein hohes oder niedriges Aktivitätslevel weniger der Realität entspricht, da es gute und schlechte Tage/Wochen gibt. Ich habe mich zumindest nicht wieder gefunden, da ich es nicht jeden Tag zum Sport schaffe aber mehr mache als nur „leichte Hausarbeit". Vllt wäre auch eine Verknüpfung mit der Aktivitätsaufzeichnung der Apple Watch eine Möglichkeit, das zu integrieren?"

Solution shape: read Apple HealthKit (Active Energy + Workouts), dynamically adjust daily kcal target. Daily 1-tap fallback („heute eher aktiv / Standard / ruhig") for non-Watch users.

**Scope verdict:** Out for current beta wave. HealthKit integration crosses into OS-level permission flows, requires a non-trivial fallback UI, and risks scope drift toward fitness-tracker territory. CLAUDE.md Produkt-Scope explicitly defines activity as „erfassbar und intern für kcal-Kalibrierung, keine eigene Trend-/Streak-Anzeige" - the current static activity level set at onboarding passes that test. Dynamic adjustment is a real improvement but big enough to be its own scoped initiative later.

**Revisit when:** HealthKit is added for other reasons (e.g. weight or hydration auto-import), OR maintenance-phase users report the static activity level as a persistent kcal-calibration miss. Notify Julia and Corina if/when we pick it up.
