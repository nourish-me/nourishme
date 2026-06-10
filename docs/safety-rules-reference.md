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
| 1 | Koffein begrenzen | beide | max. **200 mg/Tag**, über den Tag verteilt (Kaffee, schwarzer/grüner Tee, Cola, Energydrinks, Mate, Kakao/dunkle Schokolade) | stark | EFSA |
| 2 | Alkohol | Schwangerschaft: **ganz meiden**. Stillzeit: ~**2–2,5 h Wartezeit pro Standarddrink** | je nach Phase | jeder Alkohol, auch in Speisen mitgekocht | stark | BfR/DGE |
| 3 | Rohe Tierprodukte (Listerien/Toxoplasmose/Salmonellen) | v.a. Schwangerschaft | Rohmilch & Rohmilchkäse, rohes/halbgares Fleisch, roher Fisch/Sushi, kalt geräucherter & gebeizter Fisch (Räucherlachs, Graved), Weichkäse mit Rinde, rohe Eier, abgepackte Feinkostsalate | stark | BfR/DGE |
| 4 | Quecksilber-Raubfisch | v.a. Schwangerschaft (Stillzeit einschränken) | Thunfisch, Hai, Schwertfisch, Hecht, Königsmakrele meiden; Methylquecksilber passiert Plazenta | stark | BfR |
| 5 | Leber / hochdosiertes Vitamin A | v.a. **1. Trimester** | Leber im 1. Trimester einschränken (Retinol teratogen); keine Vitamin-A-Hochdosis-Supplemente | moderat/differenziert | BfR |
| 6 | Milchhemmende Kräuter (Salbei, Pfefferminze) | Stillzeit | nur in **großen/medizinischen Mengen** relevant; Alltagsmengen unkritisch | **schwach** | Gesund ins Leben |

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
- BfR, Schwangere (Risikobewertung Überblick): https://www.bfr.bund.de/en/about-us/risk-assessment/pregnant-people/
- DGE, Handlungsempfehlungen Ernährung in der Schwangerschaft: https://www.dge.de/gesunde-ernaehrung/gezielte-ernaehrung/ernaehrung-in-schwangerschaft-und-stillzeit/handlungsempfehlungen-ernaehrung-in-der-schwangerschaft/
- Gesund ins Leben (BLE), Fragen & Mythen rund ums Stillen (Salbei/Pfefferminze): https://www.gesund-ins-leben.de/fuer-familien/das-1-lebensjahr/fragen-und-mythen-rund-ums-stillen/
