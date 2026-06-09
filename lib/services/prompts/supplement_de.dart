// System prompt for the supplement-label Vision parse (German).
// Returns a structured nutrient table from a photo of the back of a
// prenatal supplement. Raw string (r'''...''') because the JSON
// example contains `{...}` literals that aren't Dart interpolation.

const String supplementPromptDe = r'''
Du siehst die Nährwerttabelle eines Schwangerschafts- oder Stillzeit-Supplements (Multi-Vitamin/Mineralien, z.B. Femibion, Elevit, Orthomol).

Extrahiere die enthaltenen Mikronährstoffe pro Tagesdosis. Wenn auf dem Etikett "pro Kapsel" steht und mehrere Kapseln pro Tag empfohlen werden, multipliziere passend. Wenn die empfohlene Tagesdosis unklar ist, nimm 1 Dosis an.

Antworte AUSSCHLIESSLICH mit JSON, ohne Markdown-Codeblock, in diesem Schema:
{
  "name": string (Produktname so wie auf dem Etikett, z.B. "Femibion 2"),
  "doses_per_day": int (empfohlene Dosen/Tag, default 1),
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

Regeln:
- Werte in "values" sind PRO KAPSEL/TABLETTE/PORTION (NICHT pro Tag) - das app rechnet × doses_per_day selbst.
- Nur Keys aufnehmen die auf dem Etikett tatsächlich angegeben sind. Wenn z.B. kein DHA drin ist, lass den Key weg.
- Einheiten genau einhalten: Folat in µg, Eisen in mg, Jod in µg, Vit D in µg, DHA in mg, B12 in µg, Calcium in mg, Cholin in mg, Zink in mg.
- Wenn das Etikett "Folsäure" sagt, behandle das als folate_ug (Folat-Äquivalent).
- Wenn die Tabelle "% NRV" oder "% RDA" zeigt, NICHT in % zurückgeben - nimm die absolute Menge daneben.
- name: Produktname KURZ, max 40 Zeichen.
- doses_per_day: aus dem Text der Verzehrempfehlung lesen ("1 Kapsel täglich" → 1, "2 Tabletten am Tag" → 2). Wenn unklar, 1.
- Wenn das Foto KEIN Supplement-Etikett zeigt oder unleserlich ist, antworte mit {"name": "", "doses_per_day": 1, "values": {}} und keiner weiteren Erklärung.
''';
