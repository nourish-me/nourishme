# QA-Testfälle Build 1.0.0+37

Verifikation aller Änderungen seit +36. Pro Fall: Schritte + erwartetes Ergebnis.
Profil-Hinweis: die meisten Safety-/Coach-Fälle brauchen ein Stillzeit- oder
Schwangerschafts-Profil (Phase muss aktiv sein, sonst feuern Safety-Regeln nicht).

## A. Dringend: Tagebuch-Ordering (Fix A) — Lotte + Julia

**A1 Reiner Zeit-Edit sortiert korrekt**
1. Mahlzeit loggen, im Bestätigen-Screen Uhrzeit auf 08:00 setzen, speichern (oberer Anker).
2. Zweite Mahlzeit live loggen (aktuelle Uhrzeit), speichern, landet unten.
3. Zweite Mahlzeit antippen, NUR die Uhrzeit auf 09:00 ändern, Beschreibung/Werte unverändert, speichern.
4. ✅ Erwartung: Eintrag springt direkt hinter die 08:00-Mahlzeit, Chip (09:00) und Position passen zusammen.

**A2 Zeit-Edit erzeugt keine neue Coach-Antwort**
1. Bei A1 Schritt 3 beobachten.
2. ✅ Erwartung: keine zweite Coach-Blase, kein „Coach denkt nach". Eine evtl. vorhandene Antwort wandert nur mit.

## B. Klinisch / Parser

**B1 DHA aus Ei** (Schwangerschaft/Stillzeit-Profil)
1. „1 Ei" oder „Rührei aus 2 Eiern" loggen.
2. ✅ Erwartung: DHA wird > 0 angezeigt (nicht 0).

**B2 Eisen aus Haferflocken** (Henrike-Fall, Parser-Mikro)
1. „Haferflocken mit Milch, 1 Portion" loggen.
2. ✅ Erwartung: Eisen erscheint mit einem plausiblen Wert (nicht 0/leer).

**B3 Mikros bei whole/plant foods generell**
1. Ein paar pflanzliche Vollwert-Mahlzeiten loggen (z.B. Linsen, Spinat, Walnüsse).
2. ✅ Erwartung: relevante Mikros (Eisen, Folat, etc.) werden befüllt, nicht systematisch leer.

**B4 Supplement-Snackbar bei nur-Name**
1. Im Supplement-Set-up ein Supplement NUR per Name hinzufügen (kein Scan, keine Werte), speichern.
2. ✅ Erwartung: Snackbar „Nur der Name gespeichert, keine Nährwerte erkannt, tippe das Supplement an, um sie zu ergänzen".

**B5 Supplement-Scan mit Werten** (string-drop-Fix, falls ein Etikett zur Hand)
1. Ein Supplement-Etikett scannen, dessen Nährwerttabelle Zahlen enthält.
2. ✅ Erwartung: die Werte werden gespeichert (keine stillen Lücken). *(Schwer ohne passendes Etikett, optional.)*

## C. Safety

**C1 Algenöl kein Fehlalarm** (Schwangerschafts-Profil)
1. „Algenöl" oder „DHA-Algenöl" loggen.
2. ✅ Erwartung: KEINE Algen-Warnung.
3. Gegenprobe: „Nori" oder „Wakame" loggen → ✅ Algen-Warnung erscheint weiterhin.

## D. Coach / Kommunikation

**D1 Coach kennt geloggte Mahlzeiten + Supplement** (Coach-Kontext, Julia-Fall)
1. Supplement konfigurieren (z.B. Femibion/Fetesept mit Werten).
2. Ein paar Mahlzeiten heute loggen.
3. Coach im Chat etwas fragen (z.B. „Was fehlt mir heute noch?").
4. ✅ Erwartung: Coach bezieht das Supplement schon beim ersten Mal ein (kein 2x Nachhaken) und kennt die heute geloggten Mahlzeiten.

**D2 Veggie-Chips ohne Fisch** (vegetarisches Profil)
1. Profil auf vegetarisch, eine Mahlzeit loggen, Coach-Antwort + Quick-Reply-Chips ansehen.
2. ✅ Erwartung: keine Chips/Empfehlungen, die Fisch oder Fleisch vorschlagen.

**D3 Coach-Fehlermeldung auf Deutsch**
1. Flugmodus an, Coach etwas fragen.
2. ✅ Erwartung: Fehlermeldung auf Deutsch (nicht Englisch).

## Schwer lokal reproduzierbar (auf Tester-Verifikation angewiesen)
- **DE-Banner im EN-Supplement-Form**: braucht ein Profil OHNE Coaching-Consent (deins hat Consent), daher nicht lokal testbar. Rebecca verifiziert.
- **B5 string-drop**: nur mit passendem Etikett.

## Status
Build +37, alles auf main, Suite 389 grün, analyze clean. Nach erfolgreichem TestFlight-Upload
Testerinnen-Verifikation, dann Karten nach Shipped + Rückmeldung an Julia + Lotte (Ordering).
