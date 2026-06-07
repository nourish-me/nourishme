---
name: test-critical-flows
description: >-
  Schreibt fokussierte Unit-Tests für die kritischen Flows der NourishMe-App
  (KI-Call-Pfad in claude_client.dart, Onboarding, Paywall/Receipt-Quota).
  Trigger bei "Tests für X schreiben", "kritische Flows testen", "Test-Coverage
  für claude_client / Onboarding / Paywall", "deck den AI-Call-Pfad mit Tests
  ab", oder wenn neue Logik in einem dieser Flows landet. Fokussiert bewusst
  auf reine, verzweigte Logik mit hohem Fehlerpreis — NICHT auf triviale
  Widgets oder 100%-Coverage.
---

# Test-Skill: Kritische Flows von NourishMe

Ziel: pro Lauf **wenige, hochwertige Tests** für genau die Logik, deren Bruch
teuer ist (falsche Coach-Antworten, kaputtes Onboarding, verschenkte API-Calls).
Kein Coverage-Theater an trivialen Widgets.

## Prinzip

Bezahl mit Testaufwand nur dort, wo der Fehlerpreis hoch ist. Reihenfolge der
Ziele nach Wert: KI-Call-Pfad (`lib/services/claude_client.dart`) > Quota/Receipt
> Onboarding > Rest.

## Flow (bewährt, Schritt für Schritt)

1. **Test-Setup spiegeln.** Lies `pubspec.yaml` (Test-Deps) und ein bis zwei
   bestehende Tests in `test/` (z.B. `calorie_target_test.dart`). Übernimm
   deren Stil: Kopf-Kommentar, der erklärt *was* der Test festnagelt und *warum*
   ein Bruch schadet; `group(...)` pro Sprache/Verzweigung.

2. **Testbare Oberfläche von netzgekoppelter trennen.** Suche zuerst nach
   reinen/statischen Funktionen mit Verzweigungslogik — die sind sofort testbar.
   Beispiel-Fund: `ClaudeClient.describeProfile()` (statisch, pur, Schwellen bei
   25/50/75/100 %). Logik, die in `_post()` (HTTP) hängt (z.B. die
   JSON-Robustheit in `parseMeal`), ist NICHT direkt testbar.

3. **Schwellen/Grenzen einzeln pinnen.** Bei Schwellen-Logik je einen Test exakt
   AUF jeder Grenze (25, 50, 75, 100), plus einen darunter. So geht ein
   `>` vs `>=`-Fehler garantiert rot.

4. **Erwartungswerte aus dem Code ableiten, nicht raten.** String-genaue
   Erwartungen aus der Quelle übernehmen (die Coach-Prompt-Zeilen müssen exakt
   stimmen).

5. **Erwartungswerte verifizieren, bevor sie eingefroren werden.** Im
   Cowork-Sandbox gibt es KEIN Dart/Flutter (`flutter test` läuft hier nicht).
   Deshalb: Verzweigungslogik kurz unabhängig nachbauen (z.B. Python-Reimpl) und
   die erwarteten Strings dagegen prüfen. Verhindert, dass falsche Erwartungen
   eingefroren werden.

6. **Test im Projektstil schreiben** nach `test/<feature>_<aspekt>_test.dart`.

7. **Authoritativer Lauf auf dem Mac.** Der echte Grün/Rot-Lauf ist
   `flutter test test/<datei>.dart` lokal in Claude Code, nicht im Sandbox.
   Wenn der Test-Triage-Subagent verfügbar ist, dort delegieren.

## Wenn Logik netzgekoppelt ist (parseMeal/_post)

Nicht erzwingen. Empfehlung notieren: die reine Transformation
(Modell-Text → `MealParseResult`, inkl. JSON-Extraktion und Fallback auf
`MealParseResult.nonMeal()`) in eine statische Helfer-Methode rausziehen, dann
ist sie ohne Netzwerk testbar. Erst nach Freigabe refactoren.

## Anti-Pattern (bewusst NICHT tun)

- Keine Tests für triviale Widgets/Getter nur für die Coverage-Zahl.
- Keine Netzwerk-/Integrationstests gegen den echten Cloudflare-Worker.
- Keine erfundenen Erwartungswerte ohne Schritt 5.
