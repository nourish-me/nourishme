# Briefing für Claude Code: Einwilligung im Onboarding (DSGVO Art. 9 + Analytics-Opt-in)

**Kontext:** Die App sendet Gesundheitsdaten (Schwangerschaft, Stillzeit,
Gewicht) an Anthropic (US-Sub-Verarbeiter). Das sind besondere Kategorien
nach Art. 9 DSGVO und brauchen eine **ausdrückliche** Einwilligung als
Rechtsgrundlage (Art. 9 Abs. 2 lit. a). Außerdem läuft Analytics aktuell als
**Opt-out** (PostHog standardmäßig an); EU-rechtlich ist für nicht-essenzielles
Tracking **Opt-in** nötig. Die Datenschutzerklärung (`docs/privacy.html` /
`privacy-en.html`) verweist bereits auf genau diese Einwilligung — Code und
Erklärung müssen zusammen live gehen.

## Aufgabe

### 1. Zwei getrennte Consent-Flags einführen (NICHT bündeln)
In `settings_repository.dart`, analog zu `disclaimerAcceptedAt`:
- `healthDataConsentAt` (DateTime?) — Einwilligung in die Verarbeitung der
  Gesundheits-/Profildaten durch Anthropic zur Coaching-Generierung.
- `analyticsConsentAt` (DateTime?) — separate, optionale Einwilligung in die
  anonyme PostHog-Statistik.
Getter/Setter + Persistenz (gleiches Muster wie der bestehende Disclaimer).

### 2. Analytics von Opt-out auf Opt-in umstellen
In `analytics_service.dart`:
- `_enabled` aktuell: `_apiKey.isNotEmpty && !_settings.getAnalyticsOptOut()`.
- Neu: `_apiKey.isNotEmpty && _settings.getAnalyticsConsentAt() != null`.
- Default = AUS, bis ausdrücklich zugestimmt. Den alten `analyticsOptOut`-Pfad
  migrieren/entfernen.

### 3. Consent-Schritt im Onboarding
In `onboarding_screen.dart`, an der Stelle, wo heute der Disclaimer akzeptiert
wird (vor dem ersten KI-Call):
- Eigener Schritt mit **zwei getrennten** Zustimmungen:
  1. Pflicht (sonst funktioniert das Coaching nicht): "Ich willige ein, dass
     meine Angaben zu Schwangerschaft/Stillzeit, Gewicht und Mahlzeiten zur
     Erstellung der Coaching-Antworten an Anthropic (USA) übermittelt und dort
     verarbeitet werden (Art. 9 Abs. 2 lit. a DSGVO)." + Link zur
     Datenschutzerklärung.
  2. Optional (vorab NICHT angehakt): "Anonyme Nutzungsstatistik erlauben
     (PostHog, EU), um die App zu verbessern."
- Erst nach Setzen von (1) darf es weitergehen; (2) ist frei wählbar.
- Beide Zeitstempel über die Setter aus Schritt 1 speichern.

### 4. Ersten KI-Call hart gaten
Kein Versand von Profil-/Gesundheitsdaten an Anthropic, solange
`healthDataConsentAt == null`. Sauberster Ort: am Aufruf in
`claude_client`-Call-Sites bzw. im Provider, der die Calls auslöst.

### 5. Widerruf in den Settings
- Analytics-Einwilligung jederzeit widerrufbar (Toggle, setzt
  `analyticsConsentAt` auf null → Tracking sofort aus).
- Hinweis-Text: Widerruf der Pflicht-Einwilligung bedeutet, dass das Coaching
  nicht mehr funktioniert (= "App zurücksetzen" / Profil leeren).

## Akzeptanzkriterien
- Frischer Start ohne Einwilligung → KEIN Netzwerk-Call an Anthropic, KEIN
  PostHog-Event.
- Nach Pflicht-Einwilligung → Coaching-Calls laufen; Analytics nur, wenn (2)
  ebenfalls gesetzt.
- Analytics-Widerruf in Settings → sofort keine Events mehr.
- Wo die Logik rein ist (z.B. "darf gesendet werden?"), ein Unit-Test nach dem
  Muster `safety_rules_test.dart` (Skill `test-critical-flows`).

## Wichtig
- Granular halten, nicht in eine Sammel-Checkbox bündeln (DSGVO-Anforderung).
- Vorab-Häkchen sind unzulässig — Opt-in muss aktives Setzen sein.
- Die konkreten Einwilligungs-Texte sollte vor Launch eine Datenschutz-
  Fachperson gegenlesen.
