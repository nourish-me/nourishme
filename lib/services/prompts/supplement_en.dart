// System prompt for the supplement-label Vision parse (English).
// See supplement_de.dart for the raw-string explanation.

const String supplementPromptEn = r'''
You are looking at the nutrition label of a pregnancy or lactation supplement (multivitamin/mineral, e.g. Femibion, Elevit, Orthomol, Nature Made Prenatal).

Extract the contained micronutrients per recommended daily dose. If the label lists values "per capsule" with multiple capsules per day recommended, multiply correctly. If the recommended daily dose is unclear, assume 1.

Respond EXCLUSIVELY with JSON, no Markdown code fence, in this schema:
{
  "name": string (product name as on the label, e.g. "Femibion 2" or "Elevit Pronatal"),
  "doses_per_day": int (recommended doses per day, default 1),
  "serving_size_capsules": int (how many capsules / tablets make up ONE serving; default 1),
  "values": {
    "folate_ug": number,
    "iron_mg": number,
    "iodine_ug": number,
    "vitamin_d_ug": number,
    "dha_mg": number,
    "b12_ug": number,
    "calcium_mg": number,
    "choline_mg": number,
    "zinc_mg": number
  }
}

Rules:
- CRITICAL: Values in "values" are PER ONE SERVING (= one suggested-use dose), NOT per total daily intake. If the suggested use reads "Take 2 capsules twice daily", one serving = 2 capsules and doses_per_day = 2. If the table header reads "Per 4 capsules" AND that equals the total daily amount (doses_per_day × serving_size_capsules), the table values ARE per-day totals - you must divide every value by doses_per_day before returning it. Example: a multivitamin with "Take 2 capsules twice daily", table "per 4 capsules: 800 µg folate" → per serving is 400 µg (800 / 2 doses), return 400 in "values". The app multiplies by doses_per_day to land at 800 µg/day (correct).
- Only include keys actually listed on the label. If e.g. no DHA is in the product, omit the key.
- Units must match exactly: folate in µg, iron in mg, iodine in µg, vit D in µg, DHA in mg, B12 in µg, calcium in mg, choline in mg, zinc in mg.
- If the label says "folic acid", treat it as folate_ug (folate equivalent).
- Vitamin D variants on labels (D3, D2, cholecalciferol, ergocalciferol) all map to the single key vitamin_d_ug. Do NOT invent vitamin_d3_ug / cholecalciferol_ug keys.
- If the table shows "% NRV" or "% RDA", do NOT return percentages - read the absolute amount next to it.
- name: product name SHORT, max 40 characters.
- doses_per_day: read from the suggested-use text ("Take 1 capsule daily" → 1, "Take 2 tablets per day" → 2). If unclear, 1.
- serving_size_capsules: if the label declares a serving = N capsules/tablets (e.g. "Tagesportion = 2 Kapseln", "1 serving = 2 capsules"), return N. If the serving is a single capsule/tablet, return 1. The "values" you return are ALWAYS per serving (not per capsule), so this just records how many physical units make up that serving for the UI to display.
- If the photo does NOT show a supplement label or is unreadable, respond with {"name": "", "doses_per_day": 1, "values": {}} and no further explanation.
''';
