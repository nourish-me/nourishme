# Beta Dashboards

Operational playbook for tracking the four learning goals from Task #37
during the closed mothers' beta. Each goal has either a measurement
mechanic (PostHog query / Worker endpoint) or a manual ritual (audit
checklist / interview script). Use weekly during the beta; revisit
the go/no-go thresholds at the end of week 4.

---

## L1: Safety-Integrity (HARD NO-LAUNCH gate)

Catches cases where the app cleared something it shouldn't have. The
only learning goal that's a HARD stop on public launch: one
documented case blocks shipping until the prompt fix is verified.

### Weekly audit, ~30 min

1. Open PostHog → Events → filter `event = meal_logged` → last 7 days.
2. Random-sample 20 entries (sort by timestamp, pick every Nth row to
   spread the sample across the week).
3. For each sample, locate the corresponding `MealEntry` in your own
   test device's diary (or, if it's another tester's entry, ask
   them to share a screenshot via WhatsApp DM with the meal text,
   coach reply, and any safety warning shown). Note:
   - **What was logged** (text + portion + estimated kcal)
   - **What the coach said** (per-meal reply)
   - **What safety warning fired** (if any)
4. Flag every case where the app cleared something it shouldn't have
   for the user's phase. Examples:
   - High-mercury fish (shark, swordfish, marlin, king mackerel,
     bigeye tuna) without a mercury warning during pregnancy or
     while producing breast milk.
   - Alcohol logged without a waiting-time hint during lactation.
   - Raw milk / soft cheese / sushi / tartare without a listeria
     hint during pregnancy.
   - Liver in T1 pregnancy without a vitamin A hint.
   - Sage tea or peppermint oil in larger amounts without a
     galactofuge note for lactation.

### Exit-interview question (also feeds this)

Ask every tester at end of beta:

> "Hat dir die App mal etwas freigegeben, das du im Nachhinein nicht
> hättest essen oder trinken wollen? Wenn ja, was war es?"

### Stop-Condition (no-launch)

≥1 documented case from audit or interview. Public launch waits until
the parse prompt is fixed AND the same case re-tested clean.

---

## L2: Retention nach Woche 2 (Wert-Validierung)

Are testers coming back unprompted in week 3? This is the proxy for
"the app actually delivers real value beyond the novelty of week 1".

### PostHog setup, one-time, ~15 min

PostHog → **Insights** → **+ New insight** → **Retention**.

- **Performed event**: `meal_logged`
- **Returning event**: `meal_logged`
- **Cohortize by**: First Time
- **Period**: Daily, last 30 days
- **Date range**: Beta start date → today

This produces the standard "% of users logging on day N who also
logged on day N+1, N+2, ...". Read the Day-14 to Day-21 cohort
columns to answer L2.

For "unprompted" filtering (excluding logs that happened right after
a push reminder tap), the current build does NOT distinguish push-
triggered opens from cold opens, so we read the metric as-is and
acknowledge the bias. Post-beta, instrument a `app_opened` event
with `source: push | cold | warm` to clean this up.

### Go/Stop reading

- **Go**: ≥50% of testers who started in week 1 still log on ≥3 days
  during week 3.
- **Stop**: <30% → serious value doubt, revisit feature/coach
  hypothesis before public launch.

---

## L3: Anthropic-Cost pro aktive Userin pro Woche

Drives the pricing-model sanity check. If unit-economics don't survive
the beta cohort, public launch needs either a price increase or a
provider switch (Task #36).

### Pull the cost summary

The Worker exposes a secured endpoint:

```bash
curl -H "x-app-secret: $APP_SECRET" \
  "https://nourishme-api.vanessa-heizmann5.workers.dev/budget/summary?days=7"
```

Response shape:

```json
{
  "days": 7,
  "summary": [
    {"day": "2026-06-04", "calls": 142, "inputTokens": 38211, "outputTokens": 9847, "costUsd": 0.0875},
    ...
  ],
  "totals": {
    "calls": 980,
    "inputTokens": 246_115,
    "outputTokens": 67_402,
    "costUsd": 0.5832
  }
}
```

Pricing constants are baked into the Worker: Claude Haiku 4.5 at
$1/M input + $5/M output. When you switch model, update both lines
in `api/worker.js` and the model ID in `lib/services/claude_client.dart`.

### Cost per active user per week

1. **Total weekly USD** = `totals.costUsd` from `?days=7`.
2. **Weekly active users (WAU)** = PostHog → Insights → Trends → event
   `meal_logged`, unique users, last 7 days.
3. **Cost/user/week** = total USD ÷ WAU.

### Go/Stop reading

- **Go**: <€0.50 / user / week (≈$0.55) → 8.99 €/month carries ~75 %
  margin.
- **Stop**: >€1.50 / user / week → model kippt, LLM-provider switch
  (Task #36) becomes P0 before launch.

---

## L4: Coach-Erinnerungswert (qualitativ)

Do testers remember anything the coach said unprompted? If the
answer is "no" across the cohort, we've spent 70 % of the token
budget on noise.

### Exit-interview script, 15 min per tester

Run at end of beta. Don't lead — ask, wait, listen. Don't follow up
with "yes the coach replies for every meal" if she draws a blank.

1. "Du hast in den letzten Wochen die App genutzt — was ist dir am
   meisten in Erinnerung geblieben?"
2. "Gab es einen Moment, wo du dachtest: *das hat mir gerade was
   gebracht*? Was war das?"
3. **Hold for silence.** Wenn sie nichts Konkretes nennt: weiter, nicht
   nachhelfen.
4. "Erinnerst du dich an etwas, was dir der Coach (die kleine
   Glühbirne über den Mahlzeiten) gesagt hat?"
5. Wenn ja: bitte sie, das Zitat möglichst genau zu rekonstruieren
   (Marketing-Gold).
6. Wenn nein: "Liest du die Coach-Antworten überhaupt?"
   - Ja → "Was hält dich vom Erinnern ab?"
   - Nein → "Warum nicht?"

### Tally template

Pro Testerin in einer einfachen Tabelle:

| Testerin | Coach-Zitat erinnert? | Zitat (wenn ja) | Liest Coach? |
|---|---|---|---|
| ... | yes/no | "..." | yes/no |

### Stop-Condition (qualitativ)

- **0/N erinnert ein konkretes Zitat** → Coach-Konzept überdenken,
  möglicherweise Token-Budget anders einsetzen (z.B. detailliertere
  Mahlzeit-Analyse statt General-Coach).
- **Go-Signal (Bonus)**: ≥3/N liefern Zitat → Marketing-Material +
  Coach-Validierung.

---

## Weekly cadence

A 30 min slot in your Sunday calendar:

1. (5 min) Pull L3 cost summary via curl. Note WAU from PostHog.
2. (10 min) L1 random-sample audit (20 entries).
3. (5 min) Skim L2 retention cohort, note week-over-week drift.
4. (10 min) Process DM-Feedback from testers into Tasks
   (use Task #38 / #41 etc. as template).

L4 runs once at the end (not weekly), one 15 min slot per tester.
