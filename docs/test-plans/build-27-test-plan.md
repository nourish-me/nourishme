# Build +27 Test-Plan

Pro Feature: ein Happy-Path + 2-4 Edge-Cases. Markiert als **🟢 V**
(Vanessa testet auf Device) oder **🟦 C** (Claude testet via Unit-Test
oder Code-Audit). Bei jedem Punkt steht das erwartete Verhalten.

Übersicht der gebündelten Features in Build +27:

- Build +25 Bugs (welcome, custom radio, privacy link, multi-photo
  picker, EN emergency keywords, markdown link, Backcamembert)
- Build +25 Design-Picks (AppBar order, micronutrient sort, coach retro
  pause, tips screen extension, per-child milk share)
- Build +26 Bugs (custom slider lock, photo picker naming, cholin font
  consistency, retro scroll-to-meal, single-photo EXIF cross-day,
  multi-photo cross-day day-switch, disclaimer shield icon)

---

## 1. Onboarding-Welcome-Step

**Was:** „Keine Sorge: alles was du in den folgenden Onboarding-Schritten
einträgst kannst du jederzeit in den Einstellungen ändern."

- 🟢 V Happy: Start Onboarding → Welcome-Step zeigt neuen Text DE
- 🟢 V Edge: App in EN → Welcome zeigt „in the following onboarding
  steps..."

---

## 2. Milk-Share-Selector: Preset → Custom → Slider

**Was:** Custom-Tile lock, +/-1% Snap, Slider snapped nicht zurück auf
Preset-Row.

- 🟢 V Happy: Auf 100% (Preset „Only my milk"), tap Custom → Slider
  erscheint mit Wert 100, Custom-Row bleibt selected, Slider lässt sich
  verschieben
- 🟢 V Edge: Slider auf 70 ziehen → Custom bleibt selected (nicht
  zurück auf „Mostly your milk" springen)
- 🟢 V Edge: Slider auf 100 ziehen → Custom bleibt selected
- 🟢 V Edge: Custom → "Only my milk" antippen → Custom-Lock fällt,
  Slider verschwindet, „Only my milk" selected, Wert = 100
- 🟢 V Edge: Bei einem stored non-preset Wert (z.B. 75%) öffnen →
  Custom-Row direkt selected, Slider auf 75 sichtbar
- 🟦 C: Widget-Test (TODO falls Zeit) — preset → custom tap → setState
  emits sharePercent unchanged

---

## 3. Multi-Photo-Upload: Single-Day

**Was:** Mehrere Fotos die alle am gleichen Tag entstanden sind.

- 🟢 V Happy: 3 Fotos vom HEUTE Vormittag auswählen → Review-Screen
  zeigt 3 Items mit EXIF-Uhrzeit + EXIF-Hinweis im Banner → „Alle
  speichern" → Diary scrollt zum letzten Eintrag, Toast „Coach pausiert
  für nachträgliche Einträge"
- 🟢 V Edge: 3 Fotos von GESTERN → Review zeigt 3 Items → Save →
  Diary springt auf GESTERN, scrollt zum letzten Eintrag
- 🟢 V Edge: Multi-Photo Pick → Foto bearbeiten (Stift-Icon) →
  ConfirmScreen öffnet, Werte editieren → Speichern → Review-Liste
  zeigt die geänderten Werte
- 🟢 V Edge: Multi-Photo Pick → ein Item verwerfen (X) → Save Button
  zeigt richtige Anzahl, verworfener Item wird nicht gespeichert

---

## 4. Multi-Photo-Upload: Cross-Day (Mehrere Tage)

**Was:** Mehrere Fotos die über Tage verteilt sind (gestern + heute).

- 🟢 V Happy: 1 Foto gestern + 1 Foto heute → Review → Save → Toast
  „X Mahlzeiten über Y Tage gespeichert · Coach pausiert..." → Diary
  bleibt auf focused day, User muss manuell wechseln
- 🟢 V Edge: 1 Foto gestern + 1 Foto vorgestern → Toast zeigt 2 Tage,
  Diary bleibt auf heute (oder wo focused war)

---

## 5. Single-Photo-Upload Cross-Day

**Was:** Ein Foto von gestern hochladen.

- 🟢 V Happy: Bei „Heute" stehen → Foto-Icon → Single photo from
  library → Gestriges Foto wählen → ConfirmScreen öffnet mit
  Uhrzeit/Datum von GESTERN (EXIF) → Speichern → Diary wechselt
  automatisch auf gestern, scrollt zum neuen Eintrag, Toast „Eintrag
  gespeichert · Coach pausiert für vergangene Tage"
- 🟢 V Edge: Foto-Datum manuell auf heute setzen vor Save → kein
  Day-Switch, Coach fired (wenn nicht retro)
- 🟦 C Code: confirm_screen.dart Init-Logic für EXIF darf den focused
  day check NICHT mehr machen

---

## 6. Retro-Save Same-Day Scroll

**Was:** Heute 16 Uhr → loggen für heute 8 Uhr → Diary muss zum 8-Uhr-
Eintrag scrollen.

- 🟢 V Happy: Bei „Heute" stehen (16 Uhr) → Text-Input „Toast mit
  Marmelade" → Save → Uhrzeit-Pille auf 08:00 ändern → Speichern →
  Coach pausiert Toast + Diary scrollt zum 08:00 Eintrag (nicht zu den
  späteren Einträgen)
- 🟢 V Edge: Mit Foto + EXIF von 08:00 → Save → same behavior

---

## 7. Coach Retro-Pause

**Was:** Coach feuert nur für „live"-Mahlzeiten (mealTime > now -
60min).

- 🟢 V Happy: Mahlzeit JETZT loggen → Coach Bubble erscheint normal
- 🟢 V Edge: Mahlzeit für 30min zurück loggen → Coach feuert (innerhalb
  Schwelle)
- 🟢 V Edge: Mahlzeit für >60min zurück loggen → KEIN Coach, Toast
  „Coach pausiert für nachträgliche Einträge"
- 🟢 V Edge: Mahlzeit für gestern loggen → KEIN Coach, anderer Toast
  („Coach pausiert für vergangene Tage")
- 🟢 V Edge: Mahlzeit bearbeiten (Kalorien ändern) auf einem retro-
  Eintrag → keine Coach-Antwort regeneriert
- 🟦 C Done: 117 safety-rules Tests + 292 Gesamttests grün

---

## 8. Safety-Rules: Backcamembert

**Was:** Heat-Carve-Out feuert in Pregnancy UND Stillzeit.

- 🟢 V Happy: In Stillzeit „baked camembert" als Text → Reassurance-
  Message erscheint („Roh wäre Listerien-Sorge; durchgebacken sicher")
- 🟢 V Edge: In Pregnancy „Backcamembert" → gleiche Reassurance
- 🟢 V Edge: In Stillzeit raw „Camembert" (ohne heat marker) → KEINE
  Warnung (medizinisch korrekt für Stillzeit)
- 🟢 V Edge: In Pregnancy raw „Camembert" → Avoid-Warnung
- 🟦 C Done: 3 neue Unit-Tests in safety_rules_test.dart

---

## 9. Emergency-Bubble

**Was:** Schwere Symptome → rote Bubble mit tappable 112.

- 🟢 V Happy: Chat-Input „starke Blutung" → Bubble rot getönt, „112"
  als Hyperlink tappable → Tap öffnet Dialer mit 112
- 🟢 V Edge: EN App, „strong bleeding" → gleiche rote Bubble + Hyperlink
- 🟢 V Edge: EN App, „severe bleeding" → gleiche Behandlung
- 🟢 V Edge: „medikament" → ORANGE Escalation-Bubble (nicht rot), keine
  Notfallnummer
- 🟦 C Done: Worker version `fab90ee4` deployed mit neuen EN keywords

---

## 10. Privacy-Link Locale

**Was:** Link öffnet sprachpassende Datenschutzseite.

- 🟢 V Happy: Onboarding-Consent in DE → Tap „Datenschutzerklärung
  lesen" → öffnet `privacy.html`
- 🟢 V Edge: App auf EN gestellt → Onboarding-Consent → Tap „Read the
  privacy notice" → öffnet `privacy-en.html`

---

## 11. AppBar Order + Icon

**Was:** [Disclaimer · Filter · Settings], Disclaimer-Icon ist Schild
(nicht Warnsignal).

- 🟢 V Happy: Diary öffnen → ganz links Schild-Icon (shield_outlined),
  dann Filter (wenn relevant), dann Settings-Zahnrad
- 🟢 V Edge: Diary auf vergangenem Tag → „Heute"-Button erscheint vor
  Schild-Icon

---

## 12. Disclaimer Bottom Sheet

**Was:** Tap auf Schild → Bottom Sheet mit Disclaimer-Text.

- 🟢 V Happy: Tap Schild → Bottom Sheet öffnet mit Text „NourishMe ist
  kein medizinisches Hilfsmittel..."
- 🟢 V Edge: Schließen über X oder „Verstanden"-Button → kein Re-Prompt

---

## 13. Micronutrient-Sort im Trends-Tab

**Was:** Getrackte zuerst, dann hairline, dann Rest. Tiebreaker
alphabetisch.

- 🟢 V Happy: Trends-Tab → Mikronährstoff-Wochenkarte → Getrackte Mikros
  (z.B. Eisen, Jod, Cholin) oben mit ihren % → dünne Trennlinie →
  ungetrackte darunter
- 🟢 V Edge: Wenn alle Mikros getrackt sind → keine Trennlinie sichtbar

---

## 14. Cholin / Awareness-Mikros Schriftart

**Was:** Diary-Header zeigt Cholin in normaler Schriftart (nicht
italic / dashed).

- 🟢 V Happy: In Settings Cholin als Mikro auswählen → Diary-Header →
  Cholin-Zelle ist in normaler Schriftart wie Eisen/Jod, nur info-icon
  rechts neben dem Namen
- 🟢 V Edge: Awareness-Wert über Schwelle (z.B. 250 mg) → Cholin
  Farbe wechselt (immer noch normale Schriftart)

---

## 15. Per-Child Milk-Share (Mehrlinge)

**Was:** Bei numChildren > 1 erscheint 5. Szenario „Für jedes Kind
anders".

- 🟢 V Happy: Settings → Phase Stillzeit, 2 Kinder → MilkShareSelector
  → 5. Tile „Für jedes Kind anders" sichtbar → Tap → Modal mit 2
  Slidern → Werte einstellen (z.B. 100% + 70%) → „Speichern" → Modal
  zu, Summary „Kind 1: 100% · Kind 2: 70% · Ø 85%"
- 🟢 V Edge: Anzahl Kinder ändern von 2 → 3 → Modal beim nächsten
  Öffnen hat 3 Slider (alter Wert für Kind 3 = single sharePercent)
- 🟢 V Edge: Anzahl Kinder von 2 → 1 → per-child shares werden
  gecleared, single mode aktiv
- 🟢 V Edge: Tap auf normalen Preset (z.B. „Only my milk") aus
  per-child Mode → per-child shares gecleared
- 🟢 V Edge: Bei numChildren=1 → 5. Option ist NICHT sichtbar
- 🟦 C Done: model toJson/fromJson roundtrip persistiert
  perChildSharesPercent

---

## 16. Tips-Screen Discovery

**Was:** 7 Tipps inkl. neuer Settings-Discovery-Tipp.

- 🟢 V Happy: Settings → „Tipps erneut zeigen" → Deck mit 7 Pages →
  letzte ist „Anpassbar bis ins Detail"
- 🟢 V Edge: Tipps-Counter zeigt „1/7" → „7/7" → CTA wird zu „Fertig"
- 🟦 C Done: Pseudo-Illustration für tip7 ist tip2-Recycle bis Designer-
  Briefing liefert (siehe docs/briefings/tip-illustrations-3-6-7.md)

---

## 17. Photo-Picker Naming

**Was:** Konsistente Bezeichnungen Camera / Single photo / Multiple.

- 🟢 V Happy: Foto-Icon → Bottom Sheet zeigt 3 Optionen mit den neuen
  Namen
- 🟢 V Edge: EN App → „Camera", „Single photo from library", „Multiple
  photos from library"

---

## ⚠️ Known Issues / Deferred to Build +28

### A. Child-Age „required" Gate

**Was:** Bei Lactation-Phase ohne Birthdate UND ohne aktive Bucket-
Selection läuft die Volume-Schätzung auf Default 0-6mo, was bei einem
älteren Kind grob falsch ist.

**Status:** Deferred. Aktuell: Default-Bucket 0-6mo wird automatisch
verwendet. User-Discovery-Problem, keine Fehlfunktion.

**Geplant für Build +28:** Volume-Estimate zeigt „—" + Hint „Bitte
Alter zuerst angeben" wenn weder Birthdate noch aktive Picker-
Interaktion stattfand.

### B. Single-Photo Review Step Question

**Klärung:** Single-Photo nutzt heute KEINEN Review-Step. Das Foto
geht direkt in den ConfirmScreen (Bottom Sheet). Review-Step ist
ausschließlich für Multi-Photo. Falls das doch erscheint → Bug
reporten.

---

## Wie ich teste (🟦 C):

- Unit-Test-Coverage prüfen für die geänderten Module
- Code-Audit: sicherstellen dass die Bugs technisch geschlossen sind
- Worker-Deployment verifizieren (Version `fab90ee4`)

## Wie du testest (🟢 V):

- iPhone öffnen, Build +27 installiert
- Pro Test-Block aus der Liste oben kurz prüfen
- Edge-Cases gehen schnell durch tap-tap-tap
- Markiere was nicht funktioniert (Screenshot oder Text-Beschreibung)
- Was funktioniert: Häkchen oder ok

Bei jedem Fail: Notiere reproducible Schritte (welche Phase, welche
App-Sprache, welcher Tag im Diary, welche Eingabe). Reicht oft schon
„Settings → MilkShare → Custom-Tap landet zurück auf Preset 100%"
für mich zu reproduzieren.
