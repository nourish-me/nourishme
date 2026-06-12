# Safety-Regeln-Referenz (Schwangerschaft & Stillzeit)

Belegte, endliche Liste der lebensmittelbezogenen Sicherheitsregeln, die
NourishMe Nutzerinnen geben sollte. **Fundament** für (a) den deterministischen
Refactor von `ClaudeClient.safetyCheck` und (b) die Test-Fälle dazu.

Quellen sind seriöse Stellen (EFSA, BfR, DGE/Gesund ins Leben). Das ist eine
Entwickler-Referenz zum Verifizieren, **keine** medizinische Beratung. Vor dem
Hardcoden sollte eine Hebamme/Ernährungsfachkraft drüberschauen.

Evidenz-Spalte ist bewusst dabei: nicht alle "Regeln" sind gleich gut belegt.

| # | Regel | Phase | Schwelle / Auslöser | Evidenz | Quelle |
|---|-------|-------|---------------------|---------|--------|
| 1 | Koffein begrenzen | beide | max. **200 mg/Tag**, über den Tag verteilt (Kaffee, schwarzer/grüner Tee, Cola, Mate, Kakao/dunkle Schokolade). **Energydrinks: Sonderregel — in der Schwangerschaft komplett meiden** (DGE: Taurin, Inosit, weitere Inhaltstoffe mit ungeklärten Wechselwirkungen) | stark | EFSA / DGE |
| 2 | Alkohol | Schwangerschaft: **ganz meiden**. Stillzeit: **ebenfalls meiden** (DGE-Positionspapier + BfR: Alkohol geht in die Milch, schon ein Glas Sekt kann Milchhormone und Milchmenge messbar drücken). Die früher gängige 2–2,5-h-Wartezeit-Faustformel ist nicht mehr DGE-Empfehlung. | jeder Alkohol, auch in Speisen mitgekocht | stark | DGE-Positionspapier / BfR |
| 3 | Rohe Tierprodukte (Listerien/Toxoplasmose/Salmonellen) | v.a. Schwangerschaft | Rohmilch & Rohmilchkäse, rohes/halbgares Fleisch, roher Fisch/Sushi, kalt geräucherter & gebeizter Fisch (Räucherlachs, Graved), Weichkäse mit Rinde, rohe Eier, abgepackte Feinkostsalate, **Wildschwein-Innereien** (PFAS/Dioxine/PCB, BfR) | stark | BfR/DGE |
| 4 | Quecksilber-Raubfisch | v.a. Schwangerschaft (Stillzeit einschränken) | Thunfisch, Hai, Schwertfisch, Hecht, Königsmakrele meiden; Methylquecksilber passiert Plazenta | stark | BfR |
| 5 | Leber / hochdosiertes Vitamin A | **gesamte Schwangerschaft** (T1 strikt, T2/T3 zurückhaltend) | BfR: in der Schwangerschaft auf Leber aller Tierarten verzichten (Retinol-Gehalt schwankt stark, in T1 teratogen, in T2/T3 weiter Kumulationsrisiko). Bei leberhaltigen Produkten (Leberwurst etc.) sehr zurückhaltend. DGE: insbesondere im 1. Trimester. **Vorherige Regel "nur T1" basierte auf älterer/US-Literatur und ist gegenüber DGE/BfR nicht streng genug.** | stark | BfR / DGE |
| 6 | Milchhemmende Kräuter (Salbei, Pfefferminze) | Stillzeit | nur in **großen/medizinischen Mengen** relevant; Alltagsmengen unkritisch | **schwach** | Gesund ins Leben |
| 7 | Algen & Algenprodukte | v.a. Schwangerschaft | abgeraten: stark schwankende und teilweise sehr hohe Jodgehalte (über UL), zusätzlich Arsen und andere Kontaminanten. Triggert z.B. bei Nori, Wakame, Kombu, Algensalat, Algen-Tabletten, Algen-Smoothie | stark | DGE |
| 8 | Chininhaltige Getränke | Schwangerschaft | BfR: während der Schwangerschaft verzichten. Konkret: Tonic Water, Bitter Lemon, manche Bitterspirituosen | stark | BfR |

## Wichtiger Befund für eure aktuelle Logik

Regel 6 (Salbei/Pfefferminze als milchhemmend) steht in eurem bestehenden
Prompt als Sicherheitswarnung. Die Evidenz dafür ist **schwach**: ein
milchhemmender Effekt ist wissenschaftlich nicht zuverlässig belegt und tritt,
wenn überhaupt, erst bei großen Teemengen auf. Eine pauschale Warnung bei jeder
Tasse Pfefferminztee ist also vermutlich **Über-Warnung** und untergräbt
Vertrauen. Empfehlung: entweder ganz raus oder nur als weicher Hinweis bei
explizit großen Mengen. Die anderen fünf Regeln sind solide.

## Wie das zu Code & Tests wird

- Jede Regel wird eine deterministische Funktion: Input (Produktname/Zutaten +
  Phase) → Output (Warn-String oder nichts). Auslöser per Stichwort-/Kategorie-
  Liste, nicht per Modell-Ermessen.
- Pro Regel mindestens zwei Tests: Auslöser trifft (Warnung kommt) und
  Phase-Mismatch (z.B. Quecksilberfisch-Warnung NICHT, wenn weder schwanger
  noch stillend).
- Das Modell bleibt nur für die unscharfen Fälle zuständig; die bekannten
  Risiken oben dürfen nicht mehr stillschweigend ausgelassen werden.

## Quellen

- EFSA, Koffein-Sicherheit (200 mg/Tag Schwangerschaft & Stillzeit): https://www.efsa.europa.eu/sites/default/files/consultation/150115.pdf
- BfR, Quecksilber/Raubfisch in Schwangerschaft & Stillzeit: https://www.bfr.bund.de/cm/343/fischverzehr-in-schwangerschaft-und-stillzeit-einige-fischarten-weisen-hohe-methylquecksilber-gehalte-auf.pdf
- BfR, Schwangere (Risikobewertung Überblick, inkl. Wildschwein-Innereien + Chinin): https://www.bfr.bund.de/ueber-uns/risikobewertung-durch-das-bfr/schwangere/
- DGE, Handlungsempfehlungen Ernährung in der Schwangerschaft: https://www.dge.de/gesunde-ernaehrung/gezielte-ernaehrung/ernaehrung-in-schwangerschaft-und-stillzeit/handlungsempfehlungen-ernaehrung-in-der-schwangerschaft/
- DGE, Handlungsempfehlung Schwangerschaft, Abschnitt Algen/Algenprodukte: https://www.dge.de/gesunde-ernaehrung/gezielte-ernaehrung/ernaehrung-in-schwangerschaft-und-stillzeit/handlungsempfehlungen-ernaehrung-in-der-schwangerschaft/#c3154
- DGE, Positionspapier Alkohol (kein sicherer Konsum, auch nicht in Stillzeit): https://www.dge.de/wissenschaft/referenzwerte/alkohol/
- DGE, Vitamin-A-Referenzwerte (Leber-Hinweis): https://www.dge.de/wissenschaft/referenzwerte/vitamin-a/
- Gesund ins Leben (BLE), Fragen & Mythen rund ums Stillen (Salbei/Pfefferminze): https://www.gesund-ins-leben.de/fuer-familien/das-1-lebensjahr/fragen-und-mythen-rund-ums-stillen/
