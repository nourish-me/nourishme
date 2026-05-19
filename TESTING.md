# NourishMe — Manuelle Test Cases

Stand: 2026-05-19. Alle Cases zum gemeinsamen Durchklicken auf dem iPhone.
"HP" = Happy Path, "EC" = Edge Case.

---

## 1. Onboarding (First Launch)

### HP1: Standard-Setup Stillzeit Zwillinge
1. Reset App über Settings.
2. Welcome-Screen: USP-Pitch + "Me" hervorgehoben sichtbar.
3. Weiter → Phase: "Milchproduzierend" ist selektiert.
4. Weiter → Basisdaten: Felder sind leer, Hinweis-Icon ⓘ neben "Deine Basisdaten" öffnet Erklärung.
5. Trage 34, 167, 56 ein. Aktivität: Mäßig.
6. Weiter → Details: 2 Kinder, 0–6 Mo, Anteil 100%, Volumen 1500 ml.
7. Weiter → Zusammenfassung: Tagesziel sollte ~2750 kcal sein. Hinweis-Text "Du kannst Werte später anpassen" direkt über "Loslegen"-Button.
8. Loslegen → landet im Tagebuch.

### HP2: Schwangerschaft
1. Reset → Welcome → Phase: "Schwanger".
2. Basisdaten ausfüllen.
3. Details: Trimester 2 wählen. Keine Stillzeit-Felder sichtbar.
4. Zusammenfassung: Aufschlag = +250 kcal.

### EC1: Phase wechseln im Onboarding
- Schritt 2 Phase wählen, weiter, dann zurück zu Schritt 2 und Phase umschalten. Die Detail-Felder im Schritt 4 reagieren entsprechend.

### EC2: Leere Pflichtfelder
- Basisdaten leer lassen → "Weiter"-Button ist disabled (`_canAdvance`).

### EC3: Back-Button auf Schritt 1
- Pfeil-Zurück im Progress-Header ist disabled wenn auf Step 0.

---

## 2. Mahlzeit per Text loggen

### HP1: Einfacher Eintrag
1. Tagebuch-Tab. Eingabe: "Müsli mit Joghurt, eine Schüssel". Send.
2. ConfirmScreen öffnet sich als Sheet mit erkannten Werten.
3. "Speichern" → Sheet schließt, Tastatur schließt, neuer Eintrag erscheint im Tagebuch oben sichtbar (alignment 0).
4. Coach-Antwort lädt darunter (Spinner) und erscheint nach ~3–5s.

### HP2: Mit Foto
1. Foto-Icon links neben Eingabefeld → Galerie oder Kamera → Foto wählen.
2. Foto erscheint als Preview oberhalb des Eingabefelds.
3. Optional Text dazu schreiben oder leer lassen.
4. Send → Claude parsed Foto + ggf. Text → ConfirmScreen.
5. Speichern.

### HP3: Über Favorit
1. Favorit-Chip oben tappen → ConfirmScreen mit vorgefüllten Werten.
2. Optional anpassen → Speichern.

### EC1: Eingabe ist keine Mahlzeit
- "asdfg" eintippen → Send. Claude erkennt nicht-Mahlzeit → behandelt als Frage, Coach antwortet entsprechend.

### EC2: Mahlzeit mit Safety Warning
- "Cappuccino, 300 ml" → ConfirmScreen zeigt Warnung (Koffein), Eintrag in Tagebuch hat Warning-Icon. Tap auf Warning-Icon → Sheet mit Erklärung.

### EC3: Lange Beschreibung
- Über Foto eine komplexe Mahlzeit erkennen. Beschreibung wraps auf bis zu 3 Zeilen statt abgeschnitten.

### EC4: Verwerfen
- ConfirmScreen → "Verwerfen" → Sheet schließt, kein Eintrag, Tastatur zu.

### EC5: Edit-Verwerfen-Prompt
- Existierenden Eintrag im Tagebuch via Slide-Edit öffnen, Wert ändern, Pfeil-Zurück oben → Dialog "Änderungen verwerfen?" mit Optionen Weiter bearbeiten / Verwerfen.

---

## 3. Coach-Frage

### HP1: Frage zu Daten die im Profil sind
1. Eingabe: "Wie viel Protein brauche ich?".
2. Coach antwortet mit konkretem Wert basierend auf Gewicht (1.2 g/kg × 56 kg = ~67 g). Fragt NICHT nach Daten die schon im Profil sind.

### HP2: Mahlzeitenidee
1. "Was kann ich als Mittagessen essen?" → Coach gibt 2-3 konkrete Vorschläge.

### EC1: Hydration nicht proaktiv
- Beim Loggen einer Mahlzeit erwähnt der Coach Wasser NICHT proaktiv.
- Bei Frage "Soll ich mehr trinken?" antwortet er konkret.

---

## 4. Eintrag bearbeiten

### HP1: Mahlzeit-Werte ändern
1. Slide auf einem Eintrag → Bearbeiten (Stift-Icon).
2. Werte ändern (z.B. Portion 60g → 80g).
3. Speichern → Eintrag wird aktualisiert.
4. Alte Coach-Antwort verschwindet, neue wird generiert.

### EC1: Edit ohne Änderung
- Edit-Screen öffnen, nichts ändern, "Speichern" → Eintrag bleibt gleich, Coach wird trotzdem neu generiert (heuristisch, falls erwünscht).

### EC2: Edit + Zurück ohne Speichern
- Werte ändern, Pfeil-Zurück → Dialog erscheint. "Verwerfen" → kein Update.

---

## 5. Eintrag löschen

### HP1: Mahlzeit + Coach-Antwort weg
1. Slide → Löschen (rotes Mülleimer-Icon).
2. Confirm-Dialog → "Löschen".
3. Eintrag und verlinkte Coach-Antwort verschwinden beide.

### EC1: Alte Mahlzeit ohne Link
- Eintrag aus Pre-Update-Zeit hatte keinen mealId-Link → Coach-Antwort bleibt orphan stehen. Bekannt, akzeptiert.

---

## 6. Tag-Navigation

### HP1: DatePicker
1. Tap auf "Heute ▾" im AppBar-Titel.
2. DatePicker öffnet, wähle einen Tag aus der Vergangenheit.
3. OK → Tagebuch lädt alle Tage von dem Tag bis heute und scrollt zum Tag-Header.

### HP2: Verlauf-Klick
1. Wechsle zu Verlauf-Tab.
2. Tap auf eine Tageskarte.
3. Wechselt zu Tagebuch-Tab und scrollt zum Tag-Header.

### HP3: Endless Scroll (Auto-Load)
1. Im Tagebuch ganz nach oben scrollen.
2. Innerhalb von 200px vom Top wird automatisch der vorherige Tag geladen.
3. Scroll-Position bleibt stabil (kein Sprung).

### HP4: Scroll-To-Bottom FAB
1. Im Tagebuch hochscrollen.
2. Pfeil-runter-Button erscheint unten rechts.
3. Tap → scrollt zum Ende (heute).

### EC1: Heute via DatePicker
- DatePicker → Heute wählen → kein Sprung nötig, bleibt sichtbar.

### EC2: Datum vor 1 Jahr
- DatePicker firstDate ist `now - 1 Jahr`. Älteres geht nicht.

---

## 7. Past-Day Eintrag

### HP1: + Eintrag auf leerem Tag
1. Im Tagebuch zu einem leeren vergangenen Tag scrollen.
2. Tap auf "Keine Einträge · + hinzufügen".
3. Sheet öffnet sich mit Eingabe und Datum-Titel "Eintrag für Dienstag, 13. Mai".
4. Eingeben → Weiter → ConfirmScreen mit Werten → Speichern.
5. Eintrag erscheint im richtigen Tag (createdAt = Tag um 12:00).

### EC1: Abbrechen
- Im Past-Day-Sheet "Abbrechen" → keine Mahlzeit, kein Parse-Aufruf.

### EC2: Leere Eingabe
- Leere Eingabe + Weiter → kein Parse, Sheet schließt.

---

## 8. Favoriten

### HP1: Speichern via Stern
1. ConfirmScreen einer Mahlzeit → Stern oben rechts tappen (wird gelb).
2. Speichern → Mahlzeit und Favorit gespeichert.
3. Favorit-Chip erscheint im Tagebuch-Input.

### HP2: Favorit nutzen
1. Tap auf Favorit-Chip → ConfirmScreen mit vorgefüllten Werten.
2. Optional anpassen → Speichern → neuer Eintrag.

### HP3: Favorit-Chip-Label
- Chip-Label zeigt "Müsli, 60g" wenn portionAmount > 0. Sonst nur "Müsli".

### HP4: Aus Favoriten entfernen
- X-Icon am Chip → Confirm-Dialog → Entfernen → Chip weg.

### HP5: Favorit in Settings bearbeiten
1. Settings → Favoriten verwalten → Liste tappen.
2. Edit-Sheet öffnet sich → Werte ändern → Speichern.
3. Favorit-Chip im Tagebuch zeigt die neue Beschreibung.

### EC1: Keine Favoriten
- Settings → Favoriten verwalten zeigt Hinweis-Text statt Liste.

---

## 9. Einstellungen

### HP1: Profil ändern
1. Settings → Gewicht 56 → 60.
2. Speichern → Tagesziel oben passt sich an.

### HP2: Phase wechseln
1. Settings → Phase: Milchproduzierend → Schwanger.
2. Stillzeit-Section verschwindet, Trimester-Picker erscheint.
3. Speichern → Tagesziel passt sich an.

### HP3: Theme wechseln
1. Settings → Design → Dunkel.
2. Sofortiges visuelles Update der ganzen App.
3. Setting persistiert beim Neustart.

### HP4: Makro-Override
1. Settings → Makro-Ziele → Protein-Feld zeigt "Auto: 67 g" als helperText.
2. Eigenen Wert eintragen (z.B. 90).
3. Speichern → Toolbar im Tagebuch zeigt jetzt 90g als Target.
4. Feld wieder leer lassen → Speichern → Auto-Default wieder aktiv.

### HP5: Reset
1. Settings → "App zurücksetzen" (rot) → Confirm-Dialog → Zurücksetzen.
2. Alle Einträge weg. Profil weg. Landet im Onboarding.

### EC1: Ungültige Eingabe
- Settings → Gewicht-Feld leer → Speichern fällt auf Default zurück (65 kg).

---

## 10. Color-Coding (Tagebuch-Toolbar)

### HP1: Unter Target
- Bei 0–79% des Tagesziels: neutrale Farbe.

### HP2: Sweet Spot
- Bei 80–100%: grün (shade600, gedämpft).

### HP3: Über Target
- Bei über 100% (z.B. 1900/1750): orange (shade700).

### EC1: Macros consistent
- Alle vier Metriken (Kcal, P, KH, F) nutzen die gleichen Schwellen.

---

## 11. Coach-Antwort-Format

### HP1: Multi-Komponenten-Mahlzeit
- Coach zeigt "Bestandteile"-Block mit Bullet-Liste pro Komponente.
- Keine "Gesamt"-Zeile (steht auf Karte).
- "Stark"/"Knapp" + "Was noch fehlt" + "Nächste Mahlzeit".

### HP2: Single-Komponenten-Mahlzeit
- Coach SKIPPED den "Bestandteile"-Block (eine Komponente = redundant zur Karte).
- Geht direkt zu "Stark"/"Knapp".

### EC1: Safety-Warning in Eintrag
- Coach erwähnt die Safety-Warning in der Antwort.
- Mahlzeit-Karte hat Warning-Icon, tap → Bottom-Sheet.

---

## 12. Quirks / Bekannte Limitierungen

- **iPhone Numpad-Tastatur** hat keine native "Done"-Taste; user dismissed via tap-outside oder Speichern-Button.
- **Provisioning** läuft alle 7 Tage ab (Apple Personal Team), Redeploy nötig.
- **Open Food Facts** noch nicht integriert → Claude-Schätzungen können bei gleicher Zutat leicht abweichen.
- **Past-Day-Eintrag** landet auf 12:00 Uhr des Tages, keine Uhrzeit-Auswahl im MVP.
- **Tandemstillen** (SS + Stillzeit) im Onboarding wählbar, in Settings nur eins aktiv (Radio).
