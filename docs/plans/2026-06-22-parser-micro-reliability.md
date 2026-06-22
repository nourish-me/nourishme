# Plan: Parser micro-reliability (bias recalibration + golden corpus)

**Fortschritt:** `55%` (Phase 1 fertig, Phase 2 Bias-Flip drin, Phase 3 Tuning läuft)

> **Phase-3-Zwischenstand (2026-06-22):** Bias-Flip hat geholfen, Lachs/Hering-DHA
> kamen nach dem Flip durch (Baseline: rot). ABER noch nicht sauber grün: Ei-DHA fällt
> einzelne Runs noch weg, und es gibt hohes Run-zu-Run-Rauschen (Süßkartoffel-A 560 statt
> ~1400, Hähnchen-Cholin mal da/mal weg). Erkenntnis: ein EINZEL-Run ist als LLM-Gate zu
> brittle. Phase 3/4 brauchen ein Mehrfach-Run-Akzeptanzkriterium (z.B. Corpus 3x, ein Food
> gilt als grün, wenn es in der Mehrheit besteht) statt einer einzelnen Pass-Zahl. Plus:
> die DHA-Eier-Karte in „Bereit für Tester" ist real nur INTERMITTIEREND gefixt, die
> strukturelle Lösung hier ist der echte Fix.

> **Baseline (2026-06-22, `dart run tool/micro_eval.dart`, 29 Foods):** ~22-26/29 je
> Run, die Zahl WACKELT LLM-bedingt zwischen Runs, und genau das ist der Befund. Echte,
> wiederkehrende Fehler:
> - **DHA pervasiv instabil + grob zu niedrig**, nicht nur bei Eiern: in einzelnen Runs
>   liefert Lachs nur 210, Hering 285-300 (statt ~2000-3000 mg), und das Ei lässt DHA
>   ganz weg, obwohl explizit erlaubt. Die STRIKTE DHA-NULLREGEL macht das Modell
>   trigger-happy beim Weglassen/Unterschätzen selbst für die kanonischen Quellen.
> - **Eisen bei Haferflocken** mal weggelassen, mal 2.8 (Henrikes Fall, bestätigt instabil).
>
> Die übrigen ~5 anfänglichen Fehler waren zu eng gesetzte Corpus-Bereiche (Süßkartoffel/
> Chia/Himbeer-Ballast, Sonnenblumen-Folat geröstet, Pizza/Quark-Calcium, Tofu-Eisen),
> auf vertretbar-großzügig kalibriert. Phase 2 muss also nicht nur Eier/Hafer, sondern die
> defensive Auslass-/Unterschätz-Tendenz generell entschärfen, v.a. die DHA-Nullregel.

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

- [x] 🟩 **Phase 1: Golden corpus + baseline (measure FIRST)**
  - [x] 🟩 CRITICAL: 29-food corpus in `test/fixtures/micro_corpus.json` (plant/whole
    heavy + animal/fortified controls + a water no-op), per-meal `expect` ranges
    (only micros clearly >5% of the lactation target, so an omission is a real bug)
    and `absent` over-reporting guards (esp. dha for ALA plant sources). Ranges from
    the prompt anchors + DGE 2025.
  - [x] 🟩 Eval harness `tool/micro_eval.dart`: posts each food to the worker, checks
    `expect` present + in range (UNDER) and no `absent` key returned (OVER), prints a
    report and exits non-zero on failure (release-gate ready).
  - [x] 🟩 Baseline captured (see box above): the corpus correctly flags the DHA
    instability + oats-iron omission; the calibration false-fails were tuned out.
  - [ ] 🟥 (Optional, deferred) Patrizia sanity-check of the corpus ranges. Not a
    blocker; ranges are from standard references.

- [x] 🟩 **Phase 2: Prompt-bias recalibration (both locales) — CRITICAL**
  - [x] 🟩 CRITICAL: rewrote both `parse_de.dart` + `parse_en.dart`. The general
    framing flipped from "im Zweifel weglassen / liste primär ≥5%" to "schätze für
    JEDES erkennbare Lebensmittel, lass nur bei echtem <5% weg" (+ named oats/quinoa/
    millet as whole-grain iron). The DHA rule reframed from the suppressive "STRIKTE
    NULLREGEL ... = 0, WEGGELASSEN" to "ALWAYS estimate when a real source is present,
    do NOT shrink the anchors (150 g salmon > 1000 mg), omit ONLY for lean meat/lean
    fish/pure-plant." Anchors, iodine correction and the egg source kept.
  - [x] 🟩 Over-reporting guardrail kept explicit (no DHA for plants, no B12 for
    pure-plant, don't invent). analyze clean.

- [ ] 🟨 **Phase 3: Re-run corpus, tune to green — CRITICAL**
  - [x] 🟩 First post-flip run: salmon/herring DHA now pass (were red in baseline) →
    the flip works directionally. No new over-reporting (plant ALA sources stayed
    DHA-free, water stayed empty).
  - [ ] 🟥 🟥 CRITICAL OPEN: still flaky single-run (egg DHA dropped this run; A/choline
    noise). Need a multi-run acceptance criterion (run the corpus N×, a food is green if
    it passes the majority) instead of one brittle pass-count, then iterate the DHA-egg
    wording until it is stably green. Harness hardened against empty worker responses.
  - [ ] 🟥 Record the final before/after once the multi-run criterion is green.

- [ ] 🟥 **Phase 4: Lock in as a release gate + device spot-check**
  - [ ] 🟥 Document `dart run tool/micro_eval.dart` as a pre-TestFlight step
    (sibling to the pre-ship checks), with a clear pass/fail so a future prompt edit
    that regresses micros is caught before testers see it.
  - [ ] 🟥 🟥 CRITICAL device spot-check: log oats + 2 plant meals on the device,
    confirm the header micros now populate (closes Henrike's iron case). `flutter
    analyze` clean, `flutter test` green.
