---
name: appstore-release-readiness
description: >-
  Prüft NourishMe vor einem TestFlight-/App-Store-Submit auf die typischen
  Ablehnungsgründe für Health-/Schwangerschafts-Apps. Trigger bei "App-Store-
  Check", "Release-Readiness", "bereit für Submit?", "TestFlight vorbereiten",
  "warum wurde die App abgelehnt". Prüft Config (Info.plist, Permissions,
  Encryption), Store-Texte (keine medizinischen Claims), Privacy Nutrition
  Labels, Disclaimer und Subscription-Compliance — NICHT eine generische
  Checkliste, sondern die echten Stolpersteine DIESER App.
---

# App-Store-Release-Readiness: NourishMe

Ziel: vor jedem Submit die Apple-Ablehnungsgründe abklopfen, die für eine
Schwangerschafts-/Ernährungs-App typisch sind. Apple ist bei Health-Apps
strenger (Guidelines 1.4.1 Health, 5.1.1/5.1.3 Privacy & Health-Daten,
3.1.1 In-App-Purchase).

## Flow (Schritt für Schritt)

1. **iOS-Config prüfen** (`ios/Runner/Info.plist`):
   - `ITSAppUsesNonExemptEncryption` gesetzt (sonst Export-Compliance-Frage
     bei jedem Build).
   - Für jede genutzte Berechtigung ein aussagekräftiger Usage-String
     (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`).
   - Version/Build über Flutter-Build-Variablen.
2. **Medizinischer Disclaimer** (Onboarding + Store-Text): Apple verlangt, dass
   die App daran erinnert, **vor medizinischen Entscheidungen eine Ärztin/einen
   Arzt zu konsultieren**. Prüfen, dass die Disclaimer-Formulierung das enthält,
   nicht nur "kein Medizinprodukt".
3. **Keine medizinischen Claims** im Store-Text: kein "diagnostiziert",
   "behandelt", "heilt". Framing als Wellness-/Tracking-Tool. Keine Aussagen
   über Mess-Genauigkeit, die nicht belegt sind (Guideline 1.4.1).
4. **Methodik/Quellen kommunizieren**: bei Gesundheits-Werten muss erkennbar
   sein, woher sie kommen (DGE/EFSA/BfR). Steht in Datenschutzerklärung +
   Landing — sicherstellen, dass es auch im App-Kontext sichtbar ist.
5. **App Privacy Nutrition Labels** (App Store Connect, nicht im Repo!):
   müssen mit der Datenschutzerklärung übereinstimmen. Deklarieren:
   Gesundheitsdaten (an Anthropic zur Coaching-Generierung), Nutzungsdaten
   (PostHog), Diagnose-/Crash-Daten (Sentry). Nichts verschweigen, nichts
   überdeklarieren.
6. **Privacy-Policy-URL** in App Store Connect gesetzt (`docs/privacy.html`).
7. **Subscription-Compliance** (falls Paywall live): echte In-App-Purchases,
   "Käufe wiederherstellen", Links zu Terms + Datenschutz auf dem Paywall,
   Preise/Periode klar. (Guideline 3.1.1 / 3.1.2)
8. **Altersfreigabe**-Fragebogen ausgefüllt.
9. **Befunde nach Blocker/Hinweis sortiert ausgeben.**

## Bekannte Befunde (Stand dieses Laufs — beim nächsten aktualisieren)

- ✅ `ITSAppUsesNonExemptEncryption=false` gesetzt.
- ✅ `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` vorhanden.
- ✅ Medizinischer Disclaimer im Onboarding vorhanden.
- ⬚ Disclaimer-Wortlaut: enthält er die "vor medizinischen Entscheidungen
  ärztlichen Rat einholen"-Erinnerung? (Apple-Pflicht) — verifizieren.
- ⬚ App Privacy Nutrition Labels in App Store Connect ausfüllen, deckungsgleich
  mit der Datenschutzerklärung (Health-Daten an Anthropic, PostHog, Sentry).
- ⬚ Store-Beschreibung auf medizinische Claims durchsehen.
- ⬚ Subscription-Compliance prüfen, sobald der Paywall live ist.
- ⬚ Privacy-Policy-URL + Altersfreigabe in App Store Connect.

## Anti-Pattern (bewusst NICHT)

- Keine generische 100-Punkte-Submission-Checkliste.
- Nicht so tun, als ersetze der Skill das Apple-Review. Er reduziert nur das
  Ablehnungsrisiko vorab.
- Health-Daten in den Nutrition Labels nicht kleinreden — Diskrepanz zur
  Datenschutzerklärung ist ein sicherer Ablehnungsgrund.
