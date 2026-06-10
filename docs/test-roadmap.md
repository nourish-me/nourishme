# Test-Roadmap (NourishMe)

Priorisierung der offenen kritischen Pfade nach **Risiko x Testbarkeit**.
Faustregel: hohes Risiko + reine, isolierbare Logik zuerst. UI und
netzgekoppeltes (braucht Mocks) zuletzt. Kein 100%-Coverage-Ziel.

Stand: Juni 2026. Pflege diese Datei, wenn ein Punkt erledigt ist.

## Schon abgesichert

- Kalorien-/Makro-Mathematik (`calorie_target_test.dart`)
- Micronutrient-Targets + Aggregation (`micronutrient_targets_test.dart`)
- Coach-Profilzeile `describeProfile` (`claude_client_describe_profile_test.dart`)
- KI-Antwort-Parsing `fromModelText`: kaputtes JSON, fehlende Felder,
  crash-sichere Micronutrients (`claude_client_parse_meal_test.dart`)
- Thread-Ordering + Mitternachts-Anker `coachAnchorFor` (`thread_ordering_test.dart`)
- **Deterministische Safety-Regeln** (`safety_rules.dart`, `safety_rules_test.dart`):
  6 belegte Regeln (Koffein, Alkohol, rohe Tierprodukte, Quecksilberfisch,
  Leber/Vitamin A, Kräuter), phasen-/trimester-genau, Falschtreffer-Schutz.
  Verdrahtet als deterministischer Boden in `safetyCheck` UND `parseMeal`
  (`allWarnings` + `mergeWarnings`). Grundlage: `docs/safety-rules-reference.md`.

## Tier 1 — offene Safety-Schritte

- **Fachliche Abnahme (KEIN Code, höchste Priorität vor Launch).** Eine Hebamme
  oder Ernährungsfachkraft prüft die 6 Regeln in `docs/safety-rules-reference.md`,
  besonders die bewussten Grenzfälle (Salami inkludiert; Salbei/Pfefferminze nur
  weicher Hinweis). Asynchron, parallel anstoßen.
- ~~**Parse-Prompt-Dedup.**~~ Erledigt: `parse_de.dart` und `parse_en.dart`
  bekommen jetzt dieselbe "Standard-Risiken werden separat geprüft, nicht
  wiederholen"-Anweisung wie `safetyCheck`. Die 6 expliziten Schwellen-Bullets
  sind weg; SafetyRules-Floor + Merge in `parseMeal` setzt sie deterministisch.
- **Bewusst NICHT abgedeckt:** der freie Coach-Chat. Die Regeln greifen nur bei
  der Lebensmittel-Prüfung (Scan + Logging), nicht bei beliebigen Chat-Aussagen
  des Modells. Falls gewünscht, eigener, größerer Schritt.

## Tier 2 — hoher Wert, gut testbar

- **Paywall / Receipt-Quota.** Umsatzrelevant. Quota-Mathematik und
  Receipt-Hash sind reine Logik, gut zu pinnen. (Wartet auf Task #34
  Pricing-Implementierung; aktuell kein Code dafür.)
- ~~**Tages-Aggregation (Provider).**~~ Erledigt: `dayTotal`,
  `groupMealsByDay`, `mealsForDay` in `lib/services/meal_aggregation.dart`
  rausgezogen, Provider + history/trends-Screens umgestellt. Tests in
  `meal_aggregation_test.dart` lockern Mitternachts-Edge-Cases (inkl.
  Regression: `isAfter(startOfDay)` schloss 00:00-Saves stillschweigend
  aus, neu: inklusive untere Grenze).

## Tier 3 — solide Mittelschicht

- **Coach-Kombinier-Logik (`submitMeals`).** Summen, kombinierter Text,
  Tages-Total-Anker. Als reine Funktion rausziehen, dann testen (Muster wie
  `fromModelText`).
- **Repository-CRUD (Meal/Favorite/Weight).** Per Hive-Harness, billig,
  Muster aus `thread_ordering_test.dart`.

## Tier 4 — später oder blockiert

- **Bundle-Bug + read-modify-write-Race in `ThreadRepository.add`.** Braucht
  erst eine echte Repro bzw. schwer deterministisch zu testen.
- **Onboarding-Logik.** Mittel, eher UI-gekoppelt; nur die reine
  Validierungs-/Datenlogik testen.
- **`_post`-Fehler-Mapping** (Timeout/401/429/500). Braucht HTTP-Mock.

## Bewusst NICHT

Widgets, Notifications, Analytics. Niedriges Risiko, hoher Aufwand.

## Wie abarbeiten

Pro Punkt, von oben nach unten, in Claude Code:

1. Skill `test-critical-flows` auslösen (automatisch beim Beschreiben der
   Aufgabe, oder `/test-critical-flows`).
2. Der Skill fährt den bewährten Flow: bestehende Tests als Stil-Vorlage lesen,
   reine von netzgekoppelter Logik trennen, bei Bedarf eine reine Helfer-Methode
   rausziehen (wie bei `fromModelText` / `coachAnchorFor`), Test schreiben,
   Erwartungswerte unabhängig verifizieren.
3. Den `test-runner`-Subagenten `flutter test` laufen lassen + Failures triagieren.
4. Diff reviewen, bei grün committen. Ein Punkt pro Durchgang.
