# Beta-Learnings: what the beta has taught us (June 2026)

Strategic synthesis across the whole TestFlight beta (T1-T13, builds +20 to +37,
2026-06-15 to 2026-06-27). Source detail: [[beta-feedback-log]] (per-tester
chronology + the two June validation interviews). Roadmap framing: the
`post-beta-roadmap` memory (Phase 1 = "learn, don't build"). North Star = weekly
active loggers on 3+ days/week.

This doc is deliberately blunt about NEGATIVE signal. The beta's job was to learn,
not to feel good.

## TL;DR

The core mechanics work and the "see what's missing" insight resonates as a
nice-to-have. But the two things that decide whether this is a business, **retention
and willingness to pay, are unproven and the early signal is concerning**: both deep
interviews say they "wouldn't strongly miss it" and both name **free ChatGPT** as
their substitute. The differentiator we are betting on (prescriptive, expert-grounded,
pregnancy/lactation-specific depth) is **not built and not validated yet**. The honest
next step is a cheap validation (the iron Concierge test) plus three low-risk,
multi-voice builds, NOT more features on an unproven value layer. And a hard launch
gate: the nutritionist will not recommend the app until the safety set is verified.

## The hypotheses, scored

| Hypothesis | Status | One-line |
| --- | --- | --- |
| H_value-A: "seeing my gaps" is valued | ✅ confirmed (experience side) | 4 voices like the gap-insight / bar-filling loop |
| H_value-B: prescriptive ("tell me what to eat to fix it") is the load-bearing value | ❓ unoccupied & untested | 2 voices ask for it, 0 confirm it would retain them; this is step 3 of the depth ladder, currently empty |
| H_retention: testers would miss it / use it 3+ days/week | 🔴 weakened | 2/2 interviews "wouldn't strongly miss it"; even the 32-session tester = curiosity, not bonding |
| H_payment: willingness to pay ~8.99/mo | ⚪ untested (yellow) | 0 payment signals; the one data point spent ~20-25€ on *content*, not tracking |
| H_friction: logging friction is the real barrier | ✅ confirmed (structural) | "dass ich tracken muss" is the #1 annoyance; what retained Isabella was friction removal (retro-logging) |

### H_value-A — gap insight resonates (confirmed, experience side)

Four independent voices value seeing what's missing:

> „Es gibt einem super Aufschluss darüber was in der Ernährung fehlt (z.b. bei mir Protein)." (Lotte, T11)

> „logging feels suuuuper straightforward" + raises awareness (Rebecca, T12)

Isabella (T8) lives it as a loop: the bars change immediately, she "wants to fill
the bars," and it nudges her next-meal choice toward the day's gap. Sarah (T7) uses
it to learn patterns. **This is real but it is a step-1-to-3-yourself experience:
see the gap, act on it yourself.** Nobody called it indispensable.

### H_value-B — prescriptive depth is the empty rung (untested)

The deeper value ("compose the meal that closes my iron gap") is **asked for but not
yet offered**:

> Simone (T6): man könne nach Lebensmitteln fragen, aber das gehe „nicht weit genug". Wunsch: eine konkrete Mahlzeiten-Zusammenstellung.

Two voices (Simone, Sarah) point at it; it is the unoccupied step 3 of the depth
ladder. **Critically, no tester said this would make them stay or pay.** So
prescriptive depth is our leading *hypothesis* for the must-have layer, not a
validated fact. It is exactly what the next test must probe.

### H_retention — the concerning one

Both deep interviews, despite genuine engagement, say they would not strongly miss
the app, and both name the same substitute:

> Isabella (T8): würde den Überblick vermissen, käme aber zurecht. Alternative wäre ChatGPT.

> Simone (T6): wäre die App weg, würde sie sie nicht stark vermissen.

Simone is one of the **most active testers (32 sessions)** and still low felt-value:
high usage here is *curiosity / looking things up*, not bonding. This matches the
flat `meal_logged` retention curve. **2 of 2 interviews name free ChatGPT as the
fallback** — the most dangerous competitor is a tool the target group already has,
for free.

### H_payment — untested, one yellow data point

Zero testers raised price, asked about cost, or expressed willingness to pay. The
only payment data point:

> Simone (T6): Geld ausgegeben nur einmal, Wochenbett-App „The Weeks" mit täglichem Lese-Content, ca. 20 bis 25 Euro.

She paid for *content/companionship*, not for tracking. That is a yellow light for an
8.99/month tracking subscription. **We cannot assess H_payment from this beta at all.**

### H_friction — confirmed as the structural killer

The biggest single annoyance named is the act of tracking itself:

> Isabella (T8): größtes Ärgernis, dass sie überhaupt tracken muss (mag weder kochen noch tracken). Max zwei Notifications pro Tag, sonst Schnell-Deinstallierer.

Eva (T1) forgets because the phone isn't at the table; Lotte (T11) finds it
„mühsamer ... als ich dachte". And what *retained* Isabella was friction removal:
retro-logging „war für sie eine entscheidende Verbesserung". **Micro-depth is
worthless if logging stays effortful.** Friction reduction is the retention lever we
have actual evidence for.

## What the beta confirms

- Core mechanics work: photo, barcode, micronutrient tracking, coach, all functional.
- Gap-insight resonates as a nice-to-have (4 voices).
- The safety layer is trusted: no "boy who cried wolf" complaints; warnings are respected.
- Friction is fixable with UX: retro-logging, time-picker, favourites discovery all solved mid-beta.
- A nutritionist is willing to sign off on specific borderline cases (path to credibility exists).

## What the beta does NOT confirm (and the gaps that matter)

- **Prescriptive value** as the must-have: nobody validated it would retain/pay them.
- **Weekly-active stickiness**: no tester confirmed 3+ days/week intent.
- **Payment viability**: zero signal.
- **Behaviour change**: no evidence anyone *acted* on a gap (bought a supplement, changed a meal) because of the app.
- **Beats ChatGPT**: the substitute is free and already in their hands; we have no evidence we win that comparison.

## Multi-voice, mature, low-risk builds (do these regardless of the bet)

These pay off whatever the value experiment concludes, and each has independent
support:

1. **Supplements in the profile** (auto-counted into the daily view). Fixes the
   permanent „0% DHA trotz genommener Tablette" problem. Touches Isabella, Celine,
   Rebecca, Sarah, Julia. Raises accuracy → raises credibility of the whole micro axis.
2. **A visible expert face behind the recommendations.** Isabella asked for it
   unprompted as a trust + adherence lever („dann halte ich mich daran"), and it
   doubles as the safety/credibility answer to Patrizia's launch gate. Pays into
   trust, retention AND safety at once.
3. **Keep reducing logging friction.** The one retention lever with evidence. Sharpen
   the daily loop (log → "what's missing today" → next-meal nudge); do NOT add tabs.

## What to stop / avoid

- **No more tabs.** Trends and Verlauf are barely used (Isabella explicitly, Simone implicitly). Sharpen the one daily loop instead.
- **Don't bury prescriptive value in a chat window.** Chat is barely used (Simone, Isabella). If we test prescriptive suggestions, they belong inline in the log flow, not in a separate coach chat.
- **Don't chase a community moat (yet).** Heavy product muscle that fights the account-less, privacy-first model. The likelier moat is expert-grounded, phase-specific prescriptive depth.
- **Don't assume free-forever or 8.99/mo.** Both are guesses; payment needs its own test.

## The open existential question

> Does the prescriptive micronutrient value beat free ChatGPT clearly enough that
> someone would stay and pay?

Everything above says this is THE unanswered question. We should not build a large
prescriptive feature on faith.

## How we proceed (recommendation)

1. **Run the Concierge test first (cheap, days, before building).** Pick one nutrient
   (iron), hand-deliver prescriptive "here's exactly what to eat today to close it"
   to a few testers for a few days, manually (no code). Measure: do they act, come
   back, and say it beats what ChatGPT gives them? This directly tests H_value-B and,
   indirectly, retention. This is the highest-leverage next step.
2. **Ship the three low-risk multi-voice builds** (supplements-in-profile, expert
   face, friction reduction) in parallel — they're safe bets independent of the test.
3. **Clear the launch gate (P0, non-negotiable).** Patrizia will not recommend the
   app until the safety set is verified against DGE / BfR / Netzwerk Gesund ins Leben.
   The already-signed-off borderline rules (hard cheese out, flambé still warns, liver
   whole pregnancy, algae in lactation, raw-egg wording) plus the open items
   (Toxoplasmose, sage) are the content of this gate.
4. **Probe positioning.** The evidence points away from "meal prescriber" and
   "generic tracker" toward **expert-grounded, pregnancy/lactation-specific nutrient +
   supplement coaching, educational and prescriptive inside the log loop.** Test that
   narrative, don't assume it.
5. **Design a payment test** before pricing decisions. The prescriptive depth is the
   natural premium candidate, but only after the Concierge test shows it has must-have
   pull.

## Caveats on the evidence

- The two deep interviews are n=1 each, friends-of-founder bias, self-reported.
- Most beta feedback was operational (bugs/friction/features), not strategic — value,
  retention and payment were under-probed in the beta itself. The interviews and the
  Concierge test are the corrective.
