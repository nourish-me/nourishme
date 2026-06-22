# Plan: Parser micro-reliability (bias recalibration + golden corpus)

**Fortschritt:** `0%`

Board card: "Parser unterschätzt Mikros bei whole/plant foods" (Explore) ·
Explore: `[[docs/explore/parser-micro-underreporting]]`

## TLDR

Stop the parser from inconsistently dropping micronutrients for whole/plant foods
by (a) recalibrating the parse prompt's defensive "omit when unsure" framing to
"estimate for every recognizable food, omit only when genuinely <5%", and (b)
building a golden food→micros eval corpus that measures the current gap, gates the
prompt change, and catches both under- AND over-reporting on every future release.

## Critical Decisions

- **Gewählt: Option 1 (prompt-bias recalibration + golden corpus).** Matches the
  structural decision (no per-food stopgap). The corpus is what makes an LLM
  extractor measurable and regression-safe; the bias flip targets the verified
  mechanism (inconsistent defensive omission, not missing anchors).
- **Verworfen: Option 2 (deterministic food→micro lookup DB).** The "real"
  deterministic fix, but a large project that reintroduces the German-compound
  fuzzy-matching problem (same whack-a-mole as the safety card) plus a food DB to
  build and maintain. Revisit only if Option 1 proves insufficient.
- **Verworfen: Option 3 (prompt fix only, no corpus).** Blind for health data: no
  way to know if it works or tips into over-reporting, regressions invisible. The
  recent fixes already needed worker-probes to confirm, so flying blind is out.
- **Verworfen: nichts tun.** Whack-a-mole per nutrient, already rejected.
- No DSGVO / App-Store / permissions impact (no new data, no sharing). The only
  sensitive axis is nutrition accuracy, handled by the corpus gate + device check.
- This touches the micronutrient VALUES shown to the user and fed to the coach, so
  every phase is **CRITICAL** and gated on the corpus + a device spot-check.

## Rollback

Additive: a new eval script + corpus file, plus a text change in the two parse
prompts. Each phase is a commit. Rollback = revert the prompt commit to restore the
old behaviour; the corpus stays (harmless, useful). No data migration. Medium risk
because it changes nutrition output, hence the corpus gate before anything ships.

## Schritte

- [ ] 🟥 **Phase 1: Golden corpus + baseline (measure FIRST)**
  - [ ] 🟥 🟥 CRITICAL: define ~30-50 representative foods (plant/whole-food heavy,
    the gap zone) with expected per-meal micro RANGES for the tracked keys (iron,
    folate, calcium, DHA, B12, iodine, zinc, fiber, vitamin D, choline, vitamin A).
    Ranges sourced from the prompt's own anchors + DGE 2025 references already in
    the repo. Store as a versioned data file (e.g. `test/fixtures/micro_corpus.json`).
  - [ ] 🟥 Build the eval harness: a script (`tool/micro_eval.dart`, same shape as
    the throwaway probes) that posts each corpus food to the worker, parses the
    micronutrients, asserts each tracked key is within range (flags BOTH under = key
    missing/too low AND over = key too high/hallucinated), prints a pass/fail report.
  - [ ] 🟥 Run it against the CURRENT prompt → capture the baseline (which foods
    under-report today, e.g. oats→iron). This is the before-picture we fix against.
  - [ ] 🟥 (Optional strengthening) have Patrizia (nutritionist + tester) sanity-check
    the corpus ranges, since she is already in the loop on safety/nutrition sign-off.

- [ ] 🟥 **Phase 2: Prompt-bias recalibration (both locales) — CRITICAL**
  - [ ] 🟥 🟥 CRITICAL: rewrite the defensive framing in `parse_de.dart` +
    `parse_en.dart`: from "im Zweifel den Key weglassen" to "schätze für JEDES
    erkennbare Lebensmittel aus üblichen Nährwerten; lass einen Key NUR weg, wenn der
    Beitrag wirklich <5% der Tagesreferenz ist." Keep the existing anchors, the
    iodine systematic-underestimate correction, and the DHA egg fix. Make the
    inclusion rule explicit and consistent so borderline foods (oats) stop dropping.
  - [ ] 🟥 Keep the over-reporting guardrail explicit (don't invent micros a food
    doesn't contain) so the bias flip can't silently start hallucinating.

- [ ] 🟥 **Phase 3: Re-run corpus, tune to green — CRITICAL**
  - [ ] 🟥 🟥 CRITICAL: run the eval against the new prompt, diff vs baseline. Iterate
    the prompt wording until the under-reporting cases pass AND no new over-reporting
    appears (both directions asserted). The corpus IS the acceptance gate.
  - [ ] 🟥 Record the final report in the plan (before/after per food).

- [ ] 🟥 **Phase 4: Lock in as a release gate + device spot-check**
  - [ ] 🟥 Document `dart run tool/micro_eval.dart` as a pre-TestFlight step
    (sibling to the pre-ship checks), with a clear pass/fail so a future prompt edit
    that regresses micros is caught before testers see it.
  - [ ] 🟥 🟥 CRITICAL device spot-check: log oats + 2 plant meals on the device,
    confirm the header micros now populate (closes Henrike's iron case). `flutter
    analyze` clean, `flutter test` green.
