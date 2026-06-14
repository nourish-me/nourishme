---
name: appstore-release-readiness
description: >-
  Prüft NourishMe vor einem TestFlight-/App-Store-Submit auf die typischen
  Ablehnungsgründe für Health-/Schwangerschafts-Apps. Trigger bei "App-Store-
  Check", "Release-Readiness", "bereit für Submit?", "TestFlight vorbereiten",
  "warum wurde die App abgelehnt". Prüft Config (Info.plist, Permissions,
  Encryption), Store-Texte (keine medizinischen Claims), Privacy Nutrition
  Labels, Disclaimer, Consent-Gate (Art. 9 DSGVO) und Subscription-Compliance
  — NICHT eine generische Checkliste, sondern die echten Stolpersteine
  DIESER App.
---

# App-Store-Release-Readiness: NourishMe

Ziel: vor jedem Submit die Apple-Ablehnungsgründe abklopfen, die für eine
Schwangerschafts-/Ernährungs-App typisch sind. Apple ist bei Health-Apps
strenger (Guidelines 1.4.1 Health, 5.1.1/5.1.3 Privacy & Health-Daten,
3.1.1 In-App-Purchase). Zusätzlich für EU-Distribution: DSGVO Art. 9 muss
nicht nur in der Privacy Policy stehen, sondern auch technisch im Code
durchgesetzt sein, sonst Diskrepanz zwischen Erklärung und Realität.

## Flow (Schritt für Schritt)

1. **iOS-Config prüfen** (`ios/Runner/Info.plist`):
   - `ITSAppUsesNonExemptEncryption` gesetzt (sonst Export-Compliance-Frage
     bei jedem Build).
   - Für jede genutzte Berechtigung ein aussagekräftiger Usage-String
     (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`).
   - Version/Build über Flutter-Build-Variablen (pubspec.yaml `version:`).

2. **Medizinischer Disclaimer** (Onboarding + Store-Text): Apple verlangt
   einen Verweis auf ärztliche Beratung. Prüfen, dass die
   Disclaimer-Formulierung explizit „bei medizinischen Fragen Ärztin/Arzt/
   Hebamme konsultieren" enthält — nicht nur „kein Medizinprodukt".
   - DE-Key: `onboardingDisclaimerBody`
   - EN-Key: `onboardingDisclaimerBody`

3. **Keine medizinischen Claims** im Store-Text: kein „diagnostiziert",
   „behandelt", „heilt". Framing als Wellness-/Tracking-Tool. Keine
   Aussagen über Mess-Genauigkeit, die nicht belegt sind (Guideline 1.4.1).

4. **Methodik/Quellen kommunizieren**: bei Gesundheits-Werten muss
   erkennbar sein, woher sie kommen (DGE/EFSA/BfR). Steht in
   Datenschutzerklärung + Landing + sollte auch im App-Kontext sichtbar
   sein (InfoButton-Sheets mit Quellen-Footer).

5. **GDPR-Art.-9-Consent-Gate technisch verifizieren** (nicht nur in
   Privacy Policy). Auf einem frischen App-Start ohne Einwilligung darf
   KEIN Netzwerk-Call zu Anthropic rausgehen.
   - Pure-Helper geprüft: `lib/services/consent_gate.dart` mit Tests in
     `test/consent_gate_test.dart`
   - Gate aktiv: `ClaudeClient` ruft `_assertHealthDataConsent()` am
     Eingang jeder API-Methode (parseMeal / chat / parseSupplementLabel)
   - Analytics opt-in: `AnalyticsService._enabled` prüft
     `getAnalyticsConsentAt() != null`, NICHT mehr `!getAnalyticsOptOut()`
   - Onboarding hat eigenen Consent-Step mit zwei UNCHECKED Boxen (keine
     Vorab-Häkchen, keine Bündelung — Art. 7 DSGVO)

6. **App Privacy Nutrition Labels** (App Store Connect, nicht im Repo).
   Müssen mit der Datenschutzerklärung übereinstimmen. Konkrete Antworten
   für NourishMe:

   | Kategorie (ASC) | Datentyp | Verknüpft? | Tracking? | Zweck |
   |---|---|---|---|---|
   | Gesundheit und Fitness | Gesundheits- und Fitnessdaten | Nicht verknüpft | Nein | App-Funktionalität |
   | Identifikatoren | Geräte-ID (anonyme PostHog-ID) | Nicht verknüpft | Nein | Analytik |
   | Nutzungsdaten | Produktinteraktion | Nicht verknüpft | Nein | Analytik |
   | Diagnose | Crash-Daten, Leistungsdaten, Sonstige | Nicht verknüpft | Nein | App-Funktionalität / Analytik |

   NICHT ankreuzen: Kontaktdaten, Finanzdaten, Standort, Browserverlauf,
   Suchverlauf, Käufe, Kontakte — sammeln wir nicht.

7. **Privacy-Policy-URLs in ASC** für JEDE Locale separat:
   - DE: `https://nourish-me.github.io/nourishme/privacy.html`
   - EN: `https://nourish-me.github.io/nourishme/privacy-en.html`
   - Sprach-Switch in ASC oben rechts pro App-Datenschutz-Eintrag.

8. **Altersfreigabe-Fragebogen** in ASC. Für NourishMe ergibt sich:
   - Medizinische/Pharma-Info: Selten/Mild (Ernährungs-Tipps in
     Schwangerschaft/Stillzeit)
   - Alkohol/Drogen: Selten/Mild (Coach warnt vor Alkohol in
     Schwangerschaft/Stillzeit)
   - Alle anderen Kategorien: Keine
   - Erwartetes Resultat: 12+ / 13+ (international), nicht 4+

9. **App-Review-Notes** in ASC (DE + EN, oder zumindest EN — Apple-
   Reviewer lesen alle Englisch). Vorlage in
   `.claude/skills/appstore-release-readiness/review-notes-template.md`
   (oder hier inline): erklärt dem Reviewer in 5 Min was die App tut,
   dass kein Login nötig ist (direkt ins Onboarding), und dass Anthropic-
   Coaching mit explicit Art.-9-Consent läuft.

10. **Subscription-Compliance** (nur wenn Paywall live ist — aktuell
    NICHT der Fall, daher überspringen): echte In-App-Purchases,
    „Käufe wiederherstellen"-Button, Links zu Terms + Datenschutz auf
    der Paywall, Preise/Periode klar (Guideline 3.1.1 / 3.1.2).

11. **Befunde nach Blocker / Warnung / Hinweis sortiert ausgeben.**
    Blocker = würde wahrscheinlich Apple-Ablehnung oder DSGVO-Verstoß
    auslösen, Warnung = sollte gefixt aber nicht launch-blockierend,
    Hinweis = nice-to-have.

## Bekannte Befunde (Stand 2026-06-14, Build 1.0.0+24)

Alle Pflicht-Punkte aus dem Compliance-Walkthrough von #13 sind grün:

- ✅ `ITSAppUsesNonExemptEncryption=false` in Info.plist gesetzt
- ✅ `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` vorhanden
- ✅ Medizinischer Disclaimer im Onboarding enthält explizit Verweis auf
  Hebamme/Ärztin (DE: „Bei medizinischen Fragen sprich mit deiner Ärztin
  oder Hebamme", EN: „For medical questions, talk to your doctor or
  midwife")
- ✅ Consent-Gate technisch implementiert (#83): Onboarding-Step mit
  zwei separaten Checkboxen, ClaudeClient gated jede API, AnalyticsService
  opt-in, ConsentGate-Tests grün
- ✅ App Privacy Nutrition Labels in ASC (DE) ausgefüllt + veröffentlicht,
  inkl. Gesundheit-und-Fitness-Kategorie
- ✅ Privacy-Policy-URLs DE + EN gesetzt
- ✅ Altersfreigabe 13+ (international) / 12+ (Südkorea) / A14 (Brasilien)
  hinterlegt
- ✅ App-Review-Notes (EN-Version in beiden DE+EN-Feldern hinterlegt)
- ⬚ Subscription-Compliance: skip — keine Paywall im aktuellen Build
- ⬚ Store-Beschreibung auf medizinische Claims: noch nicht final
  geschrieben (Task #12 Listing-Assets), bei Erstellung beachten

## Anti-Pattern (bewusst NICHT)

- Keine generische 100-Punkte-Submission-Checkliste — nur die Stolpersteine
  die für DIESE App und Apples Health-Guidelines relevant sind.
- Nicht so tun, als ersetze der Skill das Apple-Review. Reduziert das
  Ablehnungsrisiko vorab, kein Ersatz für den eigentlichen Review.
- Health-Daten in den Nutrition Labels nicht kleinreden — Diskrepanz zur
  Datenschutzerklärung ist ein sicherer Ablehnungsgrund.
- Consent-Gate nicht nur in der Privacy Policy versprechen, sondern auch
  im Code durchsetzen — Apple liest die Policy nicht gegen den Code, aber
  EU-Behörden tun's bei Beschwerden.
- Bei Subscription-Compliance NICHT die deutsche Web-Compliance mit der
  Apple-IAP-Compliance verwechseln: Apple verlangt eigene Mechanismen
  (Restore Purchases, native IAP-Sheets), unabhängig von DSGVO-Texten.
