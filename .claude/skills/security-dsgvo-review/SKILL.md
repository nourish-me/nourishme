---
name: security-dsgvo-review
description: >-
  Führt einen fokussierten Security- und DSGVO-Review der NourishMe-App durch.
  Trigger bei "Security-Review", "DSGVO-Check", "Datenschutz prüfen", "privacy
  review", "was geht an Dritte raus", oder vor einem Launch / App-Store-Submit.
  Prüft gezielt den Datenfluss (was verlässt das Gerät, wohin, mit welcher
  Einwilligung), Secret-Handling und Lösch-/Auskunftsrechte — NICHT eine
  generische 100-Punkte-Checkliste, sondern die echten Risikostellen DIESER App.
---

# Security- & DSGVO-Review: NourishMe

Ziel: pro Lauf die *echten* Risikostellen finden, nach Schadenshöhe sortiert.
NourishMes Ausgangslage ist gut (Daten lokal auf dem Gerät, kein Backend,
Anthropic-Key nur im Cloudflare Worker). Der Review konzentriert sich deshalb
auf die wenigen Stellen, an denen Daten das Gerät verlassen.

## Prinzip

Datenschutz-Risiko = (was für Daten) × (wohin) × (mit welcher Rechtsgrundlage).
Höchste Priorität haben besondere Kategorien nach Art. 9 DSGVO
(Gesundheitsdaten: Schwangerschaft, Stillen, Gewicht/BMI).

## Flow (bewährt, Schritt für Schritt)

1. **Egress-Punkte finden.** Alle Stellen, die das Gerät verlassen:
   `grep -rln "http.post\|http.get\|Uri.parse" lib`. Aktuell: `claude_client.dart`
   (Anthropic via Worker), `analytics_service.dart` (PostHog), Sentry (main.dart),
   `open_food_facts_client.dart` (Barcode-Lookups).
2. **Pro Egress: welche Daten?** Genau auflisten, was im Request-Body steht.
   Besonders: gehen Gesundheitsdaten (isPregnant, trimester, isLactating,
   weightKg) mit? → Art. 9, höchste Stufe.
3. **Pro Egress: Rechtsgrundlage + Transparenz.** Ist der Empfänger als
   Sub-Auftragsverarbeiter in der Datenschutzerklärung genannt? Gibt es eine
   ausdrückliche Einwilligung? AVV vorhanden?
4. **Consent-Modell prüfen.** Opt-in vs Opt-out. Nicht-essenzielles Tracking
   braucht in der EU i.d.R. Opt-in. Prüfen: `getAnalyticsOptOut()` und ob beim
   Onboarding eine echte Einwilligung eingeholt wird.
5. **Betroffenenrechte.** Gibt es "alle meine Daten löschen" (Art. 17) und
   Export (Art. 20)? `clearAll()` existiert in den Repos — ist es im UI
   erreichbar?
6. **Secrets.** Keine Keys im Bundle (Anthropic-Key nur im Worker, APP_SECRET
   rotierbar). `.env` nicht im Git? `grep` nach hartkodierten Keys.
7. **Befunde nach Schadenshöhe sortiert ausgeben**, mit konkretem nächsten
   Schritt je Punkt. Keine generische Liste.

## Bekannte Befunde (Stand dieses Laufs — beim nächsten Lauf aktualisieren)

- **HOCH:** Gesundheitsphase (schwanger/Trimester/stillend) + Profil gehen an
  Anthropic (US-Sub-Verarbeiter). Art. 9. Braucht: ausdrückliche Einwilligung,
  Anthropic in der Datenschutzerklärung, AVV.
- **MITTEL:** Analytics ist Opt-out, nicht Opt-in. EU braucht meist Opt-in.
- **OFFEN:** Sentry-PII-Scrubbing + Einwilligung noch nicht verifiziert.
- **GUT:** Daten lokal (Hive), PostHog EU + anonym + kein PII, Key nur im Worker.

## Anti-Pattern (bewusst NICHT)

- Keine generische OWASP-/100-Punkte-Checkliste abarbeiten.
- Keine Rechtsberatung vortäuschen: Befunde benennen, für die Umsetzung
  (Datenschutzerklärung, AVV) auf eine Fachperson verweisen.
- Nichts an Produktions-Keys oder Live-Daten anfassen.
