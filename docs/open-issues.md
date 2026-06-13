# Offene Punkte & Befunde (NourishMe)

Gesammelte Lücken aus der Review-Session. Status: ✅ erledigt · ⬚ offen.
Pflege die Liste, wenn ein Punkt erledigt ist.

## Code-Bugs

| Schwere | Befund | Status |
|--------|--------|--------|
| Hoch | **Protein-Ziel bei Übergewicht** falsch im Coach-Pfad (naive Gewicht × 1,2, kein BMI-25-Cap, ignorierte Phase). Von Ernährungsberaterin gemeldet. | ✅ gefixt (`proteinTargetGrams`, eine Quelle der Wahrheit) + Tests |
| Hoch | **Micronutrient-Cast** `(v as num)` konnte den ganzen Mahlzeit-Save crashen, wenn das Modell einen String liefert. | ✅ gefixt (tolerantes `_parseMicronutrients`) + Tests |
| Mittel | **Mitternachts-Ordering-Bug**: Coach-Antwort eines spät abends geloggten Eintrags rutschte auf den Folgetag, ganz oben. | ✅ gefixt (`coachAnchorFor`) + Regressionstest |
| Mittel | **Kombucha** löste fälschlich die Algen-Regel aus (Teilstring „kombu"). | ✅ gefixt (Exklusion) + Test |
| Mittel | **Beta-Bug „bundled scan + text landet oben"** — gemeldet, aber nie reproduziert. Wir haben *einen* beweisbaren Ordering-Bug gefixt, wissen aber nicht, ob es der gemeldete war. | ⬚ offen: echte Repro nötig |
| Mittel | **`ThreadRepository.add()`** macht ungeschütztes read-modify-write auf den Tages-Key → potenzielle Race-Verdrehung bei schnellem Bündel-Speichern. | ⬚ offen, schwer deterministisch zu testen |

## Test-Lücken (kritische, ungetestete Flows)

| Flow | Status |
|------|--------|
| Paywall / Receipt-Quota (umsatzrelevant, reine Logik) | ⬚ offen |
| Tages-Aggregation in den Providern (die Zahlen, die die Nutzerin sieht) | ⬚ offen |
| Coach-Kombinier-Logik (`submitMeals`: Summen, Tages-Total-Anker) | ⬚ offen |
| Repository-CRUD (Meal/Favorite/Weight) per Hive-Harness | ⬚ offen |
| Onboarding-Logik (nur die reine Validierungs-/Datenlogik) | ⬚ offen |
| `_post`-Fehler-Mapping (Timeout/401/429/500) — braucht HTTP-Mock | ⬚ offen |

(Details + Priorisierung in `docs/test-roadmap.md`.)

## Safety-Regeln

| Befund | Status |
|--------|--------|
| Fachliche Abnahme der Regeln durch Ernährungsberaterin | ✅ erfolgt; Korrekturen eingebaut (Alkohol auch Stillzeit, Leber ganze Schwangerschaft, Energydrinks, neue Regeln Algen/Chinin/Wildschwein-Innereien) |
| Final-Sign-off der bewussten Grenzfälle (Salami inkludiert; Salbei/Pfefferminze nur weicher Hinweis) | ⬚ offen, vor Launch sinnvoll |
| **Freier Coach-Chat ist NICHT von den Safety-Regeln abgedeckt** — die Regeln greifen nur bei Lebensmittel-Prüfung (Scan + Logging), nicht bei beliebigen Chat-Aussagen des Modells. | ⬚ offen, eigener größerer Block |
| Energydrink-Keyword „effect" ist faktisch wirkungslos (greift nur, wenn vorher ein Koffein-Keyword matcht) | ⬚ kosmetisch |

## DSGVO / Security (aus dem Review)

| Schwere | Befund | Status |
|--------|--------|--------|
| Hoch | **Gesundheitsdaten (Art. 9 DSGVO)** — schwanger/Trimester/stillend + Profil gehen an Anthropic (US-Sub-Verarbeiter). Braucht ausdrückliche Einwilligung, Anthropic in der Datenschutzerklärung, AVV. | ⬚ offen (großteils Recht + etwas UI) |
| Mittel | **Analytics ist Opt-out**, nicht Opt-in. EU braucht für nicht-essenzielles Tracking meist Opt-in. | ⬚ offen |
| Offen | **Sentry**: PII-Scrubbing in Stacktraces/Breadcrumbs + Einwilligung nicht verifiziert. | ⬚ offen, prüfen |
| Offen | **Betroffenenrechte**: „alle Daten löschen" (Art. 17) / Export (Art. 20) — `clearAll()` existiert in den Repos, aber ob im UI erreichbar ist ungeprüft. | ⬚ offen, prüfen |
| Gut | Daten lokal (Hive), PostHog EU + anonym + kein PII, Anthropic-Key nur im Worker. | ✅ solide Ausgangslage |

(Wiederholbarer Ablauf im Skill `security-dsgvo-review`.)

## Geprüft, kein Problem

- **KI-Kosten / Marge**: Audit ergab gesunde Marge (große Prompts schon gecacht,
  ~0,3–0,6 € KI-Kosten pro intensiver Nutzerin/Monat, <10 % COGS). Kein Handlungsbedarf.

## Prozess-Hinweise

- Mehrfach lag Arbeit **uncommitted** herum (z.B. der ganze Safety-Layer). Vor
  Schluss immer `git status` prüfen.
- Claude Code arbeitet teils **parallel** am selben Repo → vor Commits prüfen,
  dass sich Änderungssätze nicht überschrieben haben.
