# Beta-Learnings: what the beta has taught us (June 2026, rev. 4)

Strategic synthesis across the whole TestFlight beta (T1-T14, builds +20 to +37,
2026-06-15 to 2026-06-30). Sources: [[beta-feedback-log]] (per-tester chronology,
the two June validation interviews, the PMF round 2, raw transcripts) + the
TestFlight session-tracking sheet (3 snapshots: ~13.06, 18.06, 27.06; recruitment
source per tester). North Star = weekly active loggers on 3+ days/week.

This doc is deliberately blunt about NEGATIVE signal. The beta's job was to learn.
It folds in the PMF round (disappointment/payment/recommend), the recruitment-source
engagement split, and (rev. 3) Vanessa's own four learnings verbatim, each backed with
the evidence from the beta. Her learnings come first, in her own words; the
hypothesis-scored analysis underneath is the supporting read.

## TL;DR

The core mechanics work and the "see what's missing" insight resonates. The two
business-deciding questions, retention and willingness to pay, are no longer a blank:
the signal is **cautiously positive but conditional**. Among **self-recruited** testers
(found the LinkedIn post, asked to test) retention is materially better than the flat
aggregate suggested, and 7 of 8 PMF respondents would pay, anchoring at **~5€/month or
~30€/year** (below our 8.99 assumption). But the price is soft, "would pay" is stated
not revealed, the free **ChatGPT** substitute is real, and the whole value model has a
structural tension Vanessa named: **our core promise (live course-correction) depends on
the single highest-friction behaviour, real-time logging.** The clearest next step is a
cheap value test (the iron Concierge test), three low-risk multi-voice builds, a hard
safety launch gate, and reframing toward expert-grounded, pregnancy-first depth.

## Founder's learnings (Vanessa, in her own words) + the evidence

These are Vanessa's four learnings verbatim, with the beta evidence backing each.

### Learning 1 — Tracking is the biggest friction point, and our audience has the least time

> „Der größte Friction Point ist das Tracking. Food Tracking ist generell was ganz schön anstrengend, und jetzt haben wir noch die Zielgruppe, die am wenigsten Zeit hat, nämlich frisch gewordene Mamis."

**Evidence:** the most-named single annoyance across the beta. Isabella: „dass ich
tracken muss ... noch eine App ... regelmäßig rein tippen". Eva: time was the deciding
factor, phone not at the table. Nena: never formed the routine despite reminders. Corina:
busy with work, backfill saved her. Lotte: two small kids, no time/nerve, „jede
Zusatzaufgabe". Lotte's friend bounced on „zu viel Komplexität obendrauf auf den Alltag".
Confirmed and overwhelming, and the time-scarcity is structural to fresh moms, not a UX
detail. See H_friction below.

### Learning 2 — The friction collides with our core promise (live course-correction)

> „Das Problem mit diesem Friction Point ist, dass unser Core-Versprechen ja diese Live-Kurskorrektur ist. Wenn du mir nicht in der Minute sagst, was du gegessen hast, kann ich nicht live kurskorrigieren."

**Evidence:** this is the sharpest point of the whole beta. The value model (per-meal
coach, „was fehlt heute", next-meal nudge) needs in-the-moment logging, but testers log
retroactively or not at all (Eva, Nena, Corina's backfill, Isabella for whom retro-logging
„war eine entscheidende Verbesserung"). So the very moments where live correction would
fire are the moments friction blocks. It forces a fork: **kill the friction** (voice-first
capture, supplements-in-profile, photo) **or shift the value** to retrospective / pattern /
one-time insight, which is what testers actually got value from (Lotte's one protein
insight, Eva's day-trends, Corina's backfill). Naming this fork is itself a learning.

### Learning 3 — Over-focus on macros; testers want micros, but the micro-% is soft

> „Ich war sehr fokussiert auf die Makros, aber die meisten Testerinnen wollen Mikros. Bei den Makros klappt's hervorragend, dass man sagen kann „du hast x % deines Bedarfs gedeckt". Die Fehlerquote, die ein LLM beim Schätzen hat, ist bei Makros geringer als bei Mikros. Bei Mikros kann man das nicht so ganz sagen, da spielt die Verstärkung eine Rolle, wie hoch mein Mangel ist, ob ich einen Mangel habe. Da kann man vielleicht gar nicht sagen „du hast x % erreicht", aber genau diese Zahlen sind das Gamification-Element, das die Leute reizt."

**Evidence:** the gap-insight testers care about is mostly micro-framed (iron for Simone,
DHA, protein for Lotte), and the %-bars are the draw (Isabella: „diese Balken voll
kriegen"). But micro-% is scientifically soft (absorption, deficiency baseline, supplement
contribution), which is exactly where the parser kept failing (the DHA-from-eggs and
iron-from-oats fixes) and where Patrizia's accuracy/credibility gate bites. So the micro-%
is **both the hook and a credibility risk**. Telling detail: the clearest „this helped"
(Lotte) was a **macro** (protein), directional, not a precise micro %. Supplements-in-
profile matters here too: a permanent „0% DHA" despite a daily tablet quietly destroys
the credibility of the whole micro axis.

### Learning 4 — The safety layer was underestimated; a non-deterministic LLM needs a hard guard

> „Kein Showstopper, aber eine große Herausforderung, die ich unterschätzt habe: Wenn Leute essen tracken, gerade Schwangere und Stillende, erwarten sie natürlich, dass ich sie warne, wenn etwas nicht ok ist (rohes Lebensmittel, Alkohol, zu viel Kaffee). Das LLM ist non-deterministisch, also muss ich ein fettes Safety-Layer reinbauen. Das ist sehr aktuell. Ich brauche Hilfe von der Ernährungsberatung, vielleicht sogar von einem Anwalt, um keine Risiken einzugehen."

**Evidence:** this is the P0 launch gate. Patrizia (nutritionist) will not actively
recommend the app until the safety set is verified against DGE / BfR / Netzwerk Gesund ins
Leben. The borderline sign-off surfaced real corrections (hard cheese over-warning, flambé,
liver across the whole pregnancy, algae-in-lactation, raw-egg wording, open Toxoplasmose).
Live bugs reinforce it: lactation profiles wrongly got pregnancy warnings (Isabella, Julia,
P0), Algenöl false-positive (Patrizia), substring over-matching (kombu→Kombucha). Testers
expect and value the warnings (Corina liked „you drank too much coffee"). A
non-deterministic LLM over health data needs a deterministic rules layer on top
(already partially built) plus expert and likely legal review before a public launch.

## The hypotheses, scored

| Hypothesis | Status | One-line |
| --- | --- | --- |
| H_value-A: "seeing my gaps" is valued | ✅ confirmed (experience side) | the bar-filling / gap-insight loop lands; for some it is the *whole* value (Lotte: a one-time protein insight was enough) |
| H_value-B: prescriptive ("tell me what to eat to fix it") is the load-bearing value | 🟢 strengthening, first behaviour-change evidence | Sarah **cooked the suggested Kartoffel-Brokkoli-Lachs to hit 100%**; Simone wants coach-adjusted weekly plans; Nena & Corina cite prescriptive moments that worked. Still nobody pays *because* of it, but they now *act* on it |
| H_retention | 🟡 better than first read, gated by routine + recruitment source | every "Aktiv" tester at 27.06 is self-recruited; friend-asked testers churn; but high activity ≠ attachment (Simone) |
| H_payment | 🟡 early-positive, price-sensitive | 7/8 PMF say yes-with-conditions; anchor ~5€/mo, ~30€/yr; 8.99 likely too high; stated ≠ revealed |
| H_friction | ✅ confirmed, the structural killer | "dass ich tracken muss" is the #1 annoyance; and it collides head-on with the live-correction value model |

### H_value-A — gap insight resonates (confirmed)

Four-plus voices value seeing what's missing (Lotte „super Aufschluss ... viel zu wenig
Protein", Rebecca „suuuuper straightforward", Isabella's bar-loop, Sarah's pattern
learning). Important nuance from Lotte: for a busy, non-meticulous user **the one-time
directional insight is the entire value** ("ich weiß jetzt einfach, mehr auf Protein
achten") and she neither tracks daily nor pays. So gap-insight is real but for a slice
of users it is a one-shot, not a recurring-use, value.

### H_value-B — prescriptive depth: now the strongest lead, with real behaviour change

This is the most important shift in rev. 4. The exit round gives the first **acted-upon**
prescriptive evidence, not just stated interest:

> Sarah (T7): die Vorschläge, was sie als Nächstes essen könnte, um auf 100% zu kommen, waren das, was geholfen hat. Sie hat einmal **Kartoffel-Brokkoli-Lachs gekocht, um in allen Werten auf 100% zu kommen**, weil die App es vorschlug, „und das fand ich ganz cool".

> Simone (T6): ihr eigentliches Thema ist **Mahlzeiten planen** — ein „Wochenplan, den der Coach anpasst je nachdem was ich wirklich geloggt habe", plus „konkrete Rezeptvorschläge mit Mengenangaben und Zubereitung".

Earlier voices already pointed here (Simone „geht manchmal noch nicht weit genug"; Nena's
hummus snack she „mega gefeiert"; Corina's warnings „pretty good"). So the prescriptive
rung is no longer empty: **at least one tester changed what she cooked because of a
gap-closing suggestion**, and the demand is escalating toward coach-adjusted **weekly meal
planning** (Simone). Caveats stay: nobody pays *because* of it yet, and per **Learning 3
(above)** the micro-% behind these suggestions is scientifically soft, so the prescriptive
output is only as trustworthy as the underlying estimate, which is exactly Patrizia's gate.

Positioning tension to hold consciously: this demand pulls toward "meal planner", which the
*Stop/avoid* section warns against as a generic-tracker trap. Reconcile by keeping the
prescriptive value **inside the daily log loop** (next-meal-to-hit-100% nudges, like
Sarah's salmon) before considering full weekly-plan generation, which is a much bigger,
riskier build.

### H_retention — better than the first read, but confounded and conditional

First synthesis called this "weakened" (2/2 interviews wouldn't strongly miss it,
ChatGPT substitute). Two corrections:

1. **Recruitment source confounds it.** In the session sheet, **every "Aktiv"/"Star"
   tester at 27.06 is self-recruited** (Rebecca +65, Julia +36, Lotte +35, Patricia +26,
   Corina +24, Simone +22). **Zero friend-asked testers are active**; they cluster in
   Inaktiv/Gestoppt (the most engaged friend-ask, Isabella, only "reactivated", +12).
   The flat aggregate retention curve is partly an artefact of a pool heavy with
   friend-recruited *helpers* who never intended to retain. Among self-recruited users,
   ~46% are still actively growing at two weeks and ~69% at least warm.
2. **But two caveats keep the skepticism honest.** (a) "Self-recruited via LinkedIn"
   also selects for professionally/founder-interested people (e.g. Patricia the
   nutritionist), not purely target users, so some stickiness is product-curiosity.
   (b) High activity ≠ attachment: **Simone is self-recruited and very active (54
   sessions) yet "würde ... nicht stark vermissen"** — curiosity (iron-checking), not
   bonding. Corina is the genuine positive ("quite disappointed", would continue past
   lactation).

Net: retention is real where genuine intent + a formed routine meet, and recruitment
channel is a strong predictor. Future PMF/retention reads must **segment by acquisition
source**; the friend cohort is bug-finding signal, not retention signal.

### H_payment — early-positive, price-sensitive, still soft

No longer a blank. Most PMF respondents would pay with conditions, but the price anchors
keep coming in **low**:

> Corina (T3): "yes, probably"; 7-day trial too short, a month "hooks you"; anchor **~5€/Monat bzw. ~30€/Jahr**, mehr „I don't know if people would pay right now".

> Sarah (T7): „so 3-4 € dafür ... im Monat".

> Eva (T1): ja, vor allem **Erstlingsmamas**; **werbefrei** ist ein großer Zahlungsgrund.

> Nena (T14): ja, sobald für sich etabliert und Mehrwert gefunden.

Lotte is the no ("aber ich bin auch generell jemand, der nicht zahlt"). Implications:
the **8.99/month assumption is clearly too high**; the converging tester anchor is now
**~3-5€/mo or ~30€/yr** (annual). Conditions that recur: a **longer trial (a month, not 7 days)**, **no
ads**, and **routine established first**. Caveat: stated willingness in a friendly
interview is cheap and over-optimistic, and the same people lapsed in actual use
(Corina enthusiastic yet stopped logging the last days). Treat ~5€/mo as a **hypothesis
to test with real money**, not a proven price.

### H_friction — confirmed, and it fights the value model

The biggest single annoyance is the act of tracking itself (Isabella: „dass ich tracken
muss ... noch eine App ... regelmäßig rein tippen"; Eva: phone not at table, time the
deciding factor; Nena: never formed the routine; Corina: busy, backfill saved her;
Lotte: no time/nerve, an indicator is enough). What *retained* people was friction
removal (retro-logging „eine entscheidende Verbesserung" for Isabella).

Per **Learning 2 (above)**, the core promise, *live course-correction*, structurally
depends on the **highest-friction behaviour** (telling the app what you ate in the
moment). That fundamental tension forces a fork:

- **Kill the friction** so real-time logging becomes near-effortless: voice-first capture
  (Nena explicitly wants "reinsprechen, Coach übernimmt"; Eva's photo win and Corina's
  "photo or text, fit any way" point the same way), and supplements-in-profile so the
  daily picture isn't wrong by default.
- **Or shift the value** from live correction to **retrospective / pattern / one-time
  insight** — which is what testers actually got value from (Lotte's one protein insight,
  Eva's day-trends, Corina's backfill). Lower-friction, but a different product.

Naming this fork is itself a beta learning.

## Recruitment-source segmentation (new in rev. 2)

From the TestFlight session sheet (column I = self-recruited 1/0, column G = growth
18→27.06, the reliable activity signal; founder + family excluded):

- **Self-recruited (LinkedIn, intent-rich):** the entire active core. 6 still actively
  growing (Rebecca, Julia, Lotte, Patricia, Corina, Simone), 3 cooled-but-were-strong
  (Sarah, Céline, Katharina), 2 stopped (Leonie, Henrike), 2 inactive (Louisa, Christin).
- **Friend-asked (helping find bugs):** 0 active; 1 reactivated (Isabella); the rest
  inactive/stopped; family (Heizmann) excluded; a few installed too late to judge.

**Read:** acquisition channel is a strong engagement predictor. The PMF-relevant cohort
is the self-recruited one; the friend cohort over-weighted the pessimistic aggregate.
The launch should target intent-rich acquisition and all metrics should segment by source.

## What the beta confirms

- Core mechanics work (photo, barcode, micros, coach); gap-insight resonates.
- Friction is the structural barrier AND is in tension with the live-correction promise.
- The safety layer is trusted; a nutritionist will sign off on specific borderline cases.
- Retention and payment are conditionally positive among genuinely-interested users.

## What the beta does NOT confirm

- Prescriptive value as a *must-have* that retains/pays (promising, not proven).
- 3+ days/week stickiness as a stated intent.
- A defensible price (~5€/mo is an anchor to test, not validated; 8.99 likely too high).
- That we beat free ChatGPT/Claude, which interviewees name as their substitute (Simone: „Google oder Claude ... funktioniert ähnlich ... flexibler im Scope").
- A defensible *price level*: anchors cluster at ~3-5€/mo, well under the 8.99 assumption.

What the beta now DOES show (rev. 4 upgrade): **behaviour change is real**, at least once —
Sarah cooked the suggested salmon meal to close her gaps. Small n, but it moves
"prescriptive value" from theory to a first data point.

## Multi-voice, low-risk builds (do these regardless of the bet)

1. **Supplements in the profile, with a daily check-in** (auto-counted, but per-day
   confirmable). Fixes "0% DHA trotz Tablette". Voices: Isabella (detailed), Celine,
   Rebecca, Sarah, Julia. CAUTION from Sarah's exit answer: a *static* profile entry is
   double-edged and can backfire, she **stopped logging on days** because the app counted
   her Folio as taken when she'd forgotten it on a weekend trip, and removing it per-day
   was too fiddly, so "the whole day was wrong". So the build must include a lightweight
   "did you take your supplement today?" prompt (day start/end) or a one-tap per-day toggle,
   not just a set-and-forget profile field. Accuracy → credibility, and it lowers friction.
2. **A visible expert face + curated content behind the recommendations.** Isabella asked
   for it unprompted as a trust + adherence lever („dann halte ich mich daran") and a
   counter to "it's just AI"; Simone wants **curated content / knowledge nuggets** on
   pregnancy/lactation nutrition on top of tracking. Doubles as the answer to Patrizia's
   safety gate. Trust + retention + safety + an educational hook, at once.
3. **Cut logging friction further, voice-first.** The one retention lever with evidence.
   Now multi-voice: Nena (speak it), Eva (photo), Corina (photo-or-text). Sharpen the one
   daily loop (log → "what's missing today" → next-meal nudge).

## What to stop / avoid

- **No more tabs.** Trends & Verlauf barely used (Isabella explicitly; "Trends wenig
  informativ", and feels wrong after a skipped day → demotivating). Consider merging them.
- **Don't bury prescriptive value or tips in a separate chat window.** Chat is barely used
  (Simone, Isabella). Prescriptive suggestions and "Tipp des Tages" belong inline in the
  log loop. (Isabella explicitly: separate chat from logging; tip-of-the-day with an
  expert face.)
- **Community moat: note, don't build yet.** Isabella floated a light "40 other moms also
  ate pasta / I'm not alone" presence as a copy-resistant moat. Real founder question, but
  heavy product muscle that fights the account-less privacy model. The likelier moat is
  expert-grounded, phase-specific depth + brand.
- **Don't assume 8.99/mo or free-forever.** Both are guesses; payment needs its own test.

## The open existential question

> Does the prescriptive micronutrient value beat free ChatGPT/Claude clearly enough, at
> low enough logging friction, that an intent-rich user stays and pays (at ~3-5€/mo)?

Update from the exit round: we now have one user *acting* on the prescriptive value
(Sarah's salmon) and escalating demand toward coach-adjusted meal planning (Simone) — so
the prescriptive layer is the most promising answer to this question, and the Concierge
test below is the way to prove or kill it.

## How we proceed (recommendation)

1. **Run the Concierge test first (cheap, days, no code).** One nutrient (iron),
   hand-deliver "here's exactly what to eat today to close it" to a few **self-recruited**
   testers for a few days. Measure: do they act, return, and rate it above ChatGPT? Tests
   H_value-B and retention together. Highest-leverage next step.
2. **Ship the three low-risk multi-voice builds** (supplements-in-profile, expert face,
   voice-first friction cut) in parallel; safe independent of the test.
3. **Clear the safety launch gate (P0, non-negotiable).** Patrizia will not recommend the
   app until the safety set is verified against DGE / BfR / Netzwerk Gesund ins Leben.
   Signed-off rules (hard cheese out, flambé still warns, liver whole pregnancy, algae in
   lactation, raw-egg wording) + open items (Toxoplasmose, sage). Per **Learning 4**, the
   non-deterministic LLM needs a deterministic safety/rules layer over it, and possibly
   legal review, before a public launch.
4. **Probe positioning, pregnancy-first.** Value + payment skew to first-time / pregnant
   users (Eva explicit, Corina "anxiety higher in pregnancy"). The pregnancy expansion in
   CLAUDE.md may be the **primary payable wedge**, not a later add-on. Test the narrative:
   expert-grounded, pregnancy/lactation-specific nutrient + supplement coaching, educational
   and prescriptive *inside the log loop*, not a meal-prescriber and not a generic tracker.
5. **Design a real payment test** before pricing. Test ~5€/mo (and a ~30€/yr annual),
   a one-month trial (not 7 days), no ads, on self-recruited users. Prescriptive depth is
   the natural premium candidate, but only after the Concierge test shows must-have pull.
6. **Segment all future metrics by acquisition source** and target intent-rich channels.

## Caveats on the evidence

- Deep interviews are n=1 each, friends-of-founder bias, self-reported; voice transcripts
  are gappy.
- "Self-recruited" conflates "wants the value" with "professionally/founder-interested".
- Stated willingness-to-pay over-states revealed behaviour (enthusiastic interviewees
  still lapsed). The Concierge test + a real paywall are the corrective.
