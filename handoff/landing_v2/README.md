# NourishMe Landing Page — Restyling (V1)

Drop-in Ersatz für die aktuelle Landingpage unter
`https://nourish-me.github.io/nourishme/` (Source: `docs/` im Repo
`nourish-me/nourishme`).

## Was hier drin ist

```
handoff/landing_v2/
├── index.html              # ersetzt docs/index.html
├── vanessa-portrait.jpg    # neu — in docs/ ablegen
└── README.md               # diese Datei
```

Das ist eine einzelne statische HTML-Datei. Kein Build-Step, kein npm,
keine Frameworks. Nur Google Fonts (Newsreader + JetBrains Mono) werden
extern geladen — wie auch schon vorher.

## Integration in 3 Schritten

### 1. Beide Dateien in `docs/` kopieren

```bash
cd ~/wo-auch-immer/nourish-me/nourishme
cp handoff/landing_v2/index.html docs/index.html
cp handoff/landing_v2/vanessa-portrait.jpg docs/vanessa-portrait.jpg
```

`index.html` überschreibt die bestehende Datei. `vanessa-portrait.jpg`
ist neu — das ist der Portrait-Crop, der jetzt in der Story-Sektion
sitzt. Falls das bestehende Foto unter einem anderen Namen liegt, kann
es entfernt werden.

### 2. Lokal prüfen (optional)

```bash
cd docs && python3 -m http.server 8765
# → http://localhost:8765/index.html
```

### 3. Committen und pushen

```bash
git add docs/
git commit -m "Landing page v2 — Field Manual restyling, neue Story-Architektur"
git push
```

GitHub Pages baut automatisch neu. Nach ~1 Min ist die neue Seite live
unter `https://nourish-me.github.io/nourishme/`.

## Was sich geändert hat (gegenüber der alten Seite)

### Brand
- **Farbschema umgedreht**: warmer Paper-Background (`#F4EFE6`) mit
  dunkler Pine-Tinte (`#1E4A45`) als CTA-Farbe — selbe Palette wie die
  App (Field Manual). Vorher: dunkler Hintergrund mit hellem Text.
- **Typografie konsolidiert**: Newsreader durchgehend (Display +
  Body), JetBrains Mono für Labels/Quellen. Italic-Newsreader als
  Akzent in Headlines.
- **Logo-Bug** (Pine-Quadrat mit zwei Punkten) ist im Header und im
  Coach-Bubble inline als SVG drin.

### Struktur (komplett neu sortiert)
Alt: Hero → Foto → Vanessa-Story (lang) → Zielgruppen → USPs → How → CTA → Quellen
Neu: Hero (mit App-Mockup) → Trust-Strip → 3 USPs → interaktiver
Konstellations-Selector → How → Story (gekürzt) → Quellen → CTA → Footer

### Copy
- **Hero-Headline**: „Ernährung, *die mitrechnet.*" (vorher: „Ernährung,
  die mitdenkt. Auch wenn du gerade nicht kannst.")
- **Hero-Sub** ohne Anti-Diät-Rhetorik (das war eine Polarisierung, die
  manche Schwangere ablehnen).
- **Gründerinnen-Story** von ~250 auf ~130 Wörter gekürzt und nach
  hinten verschoben.
- **USP-Reihenfolge**: Echtzeit-Versorgung → Wissenschaftliche Basis
  → Persönliche Konstellation (Mehrlinge nicht hervorgehoben).
- **Vanessas Foto**: nicht mehr Wochenbett-Bild im Hero, sondern
  Portrait-Crop in der Story-Sektion.

### Neu: interaktiver Selector
Unter den USPs steht ein 2-Achsen-Chooser („Du bist gerade… / und
versorgst…"). Klick durch die Konstellationen, die Output-Box rechts
zeigt jeweils Mehrbedarf in kcal + Protein und einen kurzen
Erklärtext. Vanilla JS, kein React.

## Falls etwas nicht passt

- **Schriftarten laden nicht?** Google Fonts wird extern geladen.
  Falls die Seite in einer Umgebung ohne externen Netzzugriff
  ausgeliefert wird (sollte hier nicht der Fall sein), müssen die Fonts
  lokal eingebunden werden.
- **Selector reagiert nicht?** JS ist inline am Ende der Datei. Falls
  ein CSP-Header `script-src` einschränkt, müsste der Inline-Block in
  eine separate `.js`-Datei.
- **Mailto-Link verhält sich komisch?** Der Beta-CTA und der Footer
  öffnen `mailto:vanessa.heizmann5@gmail.com`. Falls stattdessen ein
  Formular gewünscht ist, kann der `<a class="btn">` durch ein
  `<form>` ersetzt werden.

## Was bewusst NICHT angefasst wurde

- Datenschutzerklärung, Privacy Policy, Impressum, Support — die Links
  zeigen aktuell auf `#`. Bestehende Pfade müssen hier wieder
  eingetragen werden.
- App-Store-Badges (TestFlight-Beta läuft noch, daher kein Public-Link).
- Englische Version. PS im CTA-Block kündigt sie an.

## Designentscheidungen, falls Rückfragen kommen

- **Warum Body in Serif statt Sans?** Field-Manual-Charakter. Wenn das
  zu „Magazin" wirkt, kann Body auf System-Sans gewechselt werden
  (Suchen-und-Ersetzen `font-family: var(--serif)` in `.hero-sub`,
  `.lede`, `.usp-body`, `.selector-output-body`, `.step-body`,
  `.story-content p`, `.basis-list li`).
- **Warum Pine-CTA und nicht Amber?** Konsistenz mit App — primary
  Action ist immer Pine, Amber ist Coach/Akzent.
- **Warum das Mockup im Hero statt einem Foto?** Die Seite zeigte
  bisher null Produkt. Ein abstrahierter Screenshot beantwortet die
  „Wie sieht das aus?"-Frage sofort.
