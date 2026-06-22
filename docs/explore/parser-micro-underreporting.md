# Explore: Parser under-reports micronutrients for whole/plant foods

Board card: "Parser unterschätzt Mikros bei nicht-verankerten Lebensmitteln
(Prompt-Bias + Golden-Corpus)" (#P1 #parse). Scope of THIS doc: understand the
problem only. The fix (bias flip vs golden corpus) is /create-plan, not here.

## What testers experienced

- **Rebecca:** logged eggs, the coach mentioned DHA but the structured DHA value
  stayed 0. (Already patched as a one-off: egg yolk added to the DHA zero-rule's
  allowlist, 2026-06-22.)
- **Henrike:** logged Haferflocken, the iron in the tracker came ONLY from her
  Femibion supplement, the oats themselves contributed 0 iron. ("Haferflocken
  enthalten aber Eisen laut Google 😂 ... ich muss mein Halbwissen immer kurz
  kontrollieren.")

## The mechanism (verified, not assumed)

Two different surface causes, one family:

1. **Hard zero-rule (DHA):** the prompt's STRICT DHA ZERO RULE listed only fatty
   sea fish / fish oil / algae oil as permitted sources and forced `dha_mg=0` for
   everything else. Eggs were simply not in the allowlist → always wrong for eggs.
   This was deterministic and is now patched.

2. **Soft inconsistent omission (iron, and the general case):** there is NO zero
   rule for iron. Whole grains ARE anchored ("Getreide-Vollkorn 2-3 mg/100 g",
   `parse_de.dart:146`). Yet the model still drops iron for oats. Probed live
   against the worker (2026-06-22, lactation profile):

   | Meal | iron_mg returned | expected |
   |---|---|---|
   | 40 g Haferflocken + Hafermilch | **(omitted)** | ~1.6 mg (8% of target) |
   | 100 g gekochte Linsen | 3.0 ✓ | ~3 |
   | 100 g Quinoa gekocht | 1.5 ✓ | ~1.5 |
   | 1 Scheibe Vollkornbrot (50 g) | 1.2 ✓ | ~1 |

   The key insight: oats are dropped while **quinoa (not even named in the prompt)
   is included**, and oats sit at ~8% of the daily target, ABOVE the prompt's own
   ~5% inclusion threshold (`parse_de.dart:152`). So this is not anchor-absence
   and not the threshold rule working correctly. It is the model applying the
   defensive "im Zweifel den Key weglassen" framing inconsistently per call,
   trigger-happy on omission for borderline items.

**Consequence of (2):** "add more food anchors" provably will not fix it. Oats
are anchored and still drop; quinoa is unanchored and passes. The lever is the
omission bias + a way to catch per-food inconsistency, not the anchor list.

## Breadth

- Any tracked micro × any borderline-portion food can be inconsistently dropped.
  Most exposed: iron, folate, calcium, DHA in plant/whole-food meals, exactly the
  nutrients that matter in pregnancy/lactation.
- Direction of error is UNDER-reporting → the user looks more deficient than she
  is, the header shows a gap, and the coach may nudge for a nutrient the meal
  already supplied. Erodes trust ("I have to Google-check everything").
- Precedent that the team already hit this per-nutrient: iodine has a baked-in
  correction paragraph ("das Modell unterschätzt Iod systematisch ... sonst stehen
  Nutzerinnen scheinbar chronisch defizitär da", `parse_de.dart:140`). That is the
  same problem, solved once for one nutrient by hand. DHA-eggs and iron-oats are
  the next two instances of the same recurring shape.

## Scope boundary

- IN scope: the structured `micronutrients` values the parser emits (claude_client
  `parseMeal` → `_parseMicronutrients`), which feed the diary header rings and the
  coach context. Both `parse_de.dart` and `parse_en.dart` (mirrored, both carry the
  same anchors + threshold + defensive framing).
- OUT of scope: the coach prompt wording, the safety layer, the kcal/macro
  estimation. Sibling structural card: "Scalable safety matching" (same whack-a-mole
  shape on the safety side).

## Decided going in (Vanessa, 2026-06-22)

No stopgap per-food patch. Go structural. The two candidate directions to weigh in
/create-plan (NOT decided here): (1) flip the default bias from "omit when unsure"
to "estimate from standard nutritional values, omit only when genuinely <5%";
(2) a golden food→micros regression corpus that catches BOTH under- and
over-reporting before testers do. Loosening risks over-reporting/hallucination, so
the corpus likely guards whichever bias change is made. Next step: /create-plan.
