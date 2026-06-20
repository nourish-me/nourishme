---
description: Flutter-Code-Review der Aenderung, ruft test-critical-flows (Auto-Tests) und manual-test-plan (Geraete-Checkliste) auf. Optional i18n + dsgvo.
---

# /review — Code-Review plus Tests plus Testplan

Aufgabe: die gerade gebaute Aenderung pruefen. Gegenstand ist der git diff seit dem
letzten Commit bzw. die im Plan geaenderten Dateien.

## 1. Code-Review (Flutter/Dart, NICHT generisches TypeScript)
Pruefe gezielt:
- Async/Lifecycle: vergessenes dispose() auf Controllern/Streams,
  use_build_context_synchronously (BuildContext ueber async-Grenzen), unnoetige
  Rebuilds.
- KI-Call-Pfad (claude_client.dart): Fehlerbehandlung/Timeout bei Netzfehler,
  Rate-Limit, malformed Response; sichere Casts (kein roher `v as num`); Verhalten
  bei leerer/teilweiser Modell-Antwort.
- Paywall/Quota: Receipt-Validierungs-Fehler, Restore, Quota-Raender (0, negativ,
  off-by-one).
- Nebenlaeufigkeit: Races bei schnellem mehrfachem Speichern.
- Keine hardcoded Secrets/API-Keys.
- DOMAENEN-REGEL, hoechste Stufe: alles, was eine FALSCHE Naehrwert-, Kalorien- oder
  Sicherheitsangabe erzeugen koennte, ist CRITICAL, nicht UX.
Severity: CRITICAL / HIGH / MEDIUM / LOW. Pro Befund: [Severity] Datei:Zeile,
Beschreibung, konkreter Fix-Vorschlag. Jeden Befund gegen den echten Code pruefen,
nichts blind uebernehmen.

## 2. Automatisierte Tests
Ruf den Skill test-critical-flows auf, um die kritischen Flows der Aenderung
abzudecken. Der echte Gruen/Rot-Lauf ist flutter test lokal.

## 3. Manueller Testplan
Ruf den Skill manual-test-plan auf, um eine Geraete-Checkliste fuer meinen manuellen
Test zu erzeugen.

## 4. Optional
Beruehrt die Aenderung Strings/Uebersetzung: i18n-strings-audit. Beruehrt sie
Datenfluesse/Permissions: security-dsgvo-review.

[PEER-REVIEW-PLATZHALTER: hier kaeme ein Review durch ein zweites Modell hin. Aktuell
keins installiert, Schritt vorerst auslassen, im Plan vermerken dass er ausstand.]

Board: Karte nach "Review & Test" schieben. Danach teste ICH manuell.
