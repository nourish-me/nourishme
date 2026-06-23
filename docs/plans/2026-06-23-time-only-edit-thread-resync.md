# Plan: Zeit-Edit Thread-Resync (13:36-Ordering-Bug, Fix A)

**Fortschritt:** `100%`

## TLDR
Ein reiner Zeit-Edit einer bestehenden Mahlzeit (Werte unverändert) aktualisiert
heute `MealEntry.createdAt`, aber nicht den Sortier-`timestamp` des ThreadItems,
weil der Early-Return in `_appendToThread` nur Werte-Änderungen erkennt. Folge: der
Chip zeigt die neue Zeit (13:36), der Eintrag sortiert aber auf der alten Position
(Tagesende). Fix: die Resync-Entscheidung als pure Funktion herausziehen und das Gate
darauf umstellen, sodass auch ein Zeit-Edit den bereits existierenden
`updateMealItemTime`-Pfad erreicht.

## Critical Decisions
- **Gewählt: Fix (A), das Gate auf eine pure Funktion umstellen.** Der Resync-Code
  (`updateMealItemTime`, confirm_screen.dart:631-634) existiert bereits und ist
  korrekt. Der einzige Defekt ist, dass der Early-Return bei `_appendToThread`
  (Zeile 517, `isEdit && !_mealValuesChanged`) ihn für einen reinen Zeit-Edit nie
  erreicht. Kleinster wirksamer Eingriff.
- **Pure Funktion `mealEditNeedsThreadResync({oldCreatedAt, newCreatedAt, valuesChanged})
  -> valuesChanged || oldCreatedAt != newCreatedAt`, top-level in
  `thread_repository.dart`.** Begründung: `thread_repository` besitzt die
  Resync-Semantik (`updateMealItemTime`) und ist das Test-Ziel von Test 2, ein
  gemeinsames Test-File bleibt kohärent. `confirm_screen.dart` importiert
  `thread_repository` ohnehin schon.
- **`_mealValuesChanged` bleibt erhalten, wird NICHT aufgelöst.** Es ist zwar nur an
  Zeile 517 benutzt, wird aber durch den Fix nicht überflüssig: es liefert künftig
  den `valuesChanged`-Input der puren Funktion. Eine klar benannte Werte-Delta-Prüfung
  ist sauberer als die Logik in die pure Funktion zu inlinen.
- **Sortier-Resync und Coach-Regen werden ENTKOPPELT (Vanessa, 2026-06-23).** Ein
  reiner Zeit-Edit (`valuesChanged == false`) löst NUR den Sortier-Resync aus und
  NIE einen neuen Coach-Call, egal welche Zeit gesetzt wird. Begründung: eine
  verschobene Uhrzeit ist keine inhaltliche Änderung, der Coach-Regen reagiert auf
  Inhalt. Konkret: nach dem Resync in `_appendToThread` bei `valuesChanged == false`
  früh raus, BEVOR `removeCoachResponseForMeal`/Regen laufen. Die bestehende
  Coach-Antwort wandert über `updateMealItemTime` mit der Mahlzeit mit, bleibt also
  korrekt verankert. Damit entfällt auch der enge Fall „Zeit auf ~jetzt, gleicher
  Tag, <60 min, Werte gleich", der sonst einen Extra-Call ausgelöst hätte.
- **Die Coach-Regen-Entscheidung wird ebenfalls als pure Funktion herausgezogen:
  `CoachSessionManager.shouldRegenCoachOnEdit({valuesChanged, isPastDayEdit, isRetroEdit})
  -> valuesChanged && !isPastDayEdit && !isRetroEdit`.** So ist die Trennung
  testbar und nicht wieder an dieselbe Bedingung wie der Resync geklebt. Heimat
  `CoachSessionManager`, weil dort schon `isRetroactiveMeal` lebt (konzeptionelles
  Paar). Bei `valuesChanged == false` liefert sie `false` (Test 3). Bei einem
  Werte-Edit bleibt das alte Verhalten exakt erhalten (Regen außer bei retro/past-day,
  wo die stale Antwort entfernt und keine neue erzeugt wird).
- **Verworfen (jetzt): Fix (B), die Doppelquelle beseitigen.** Würde die getestete
  Sortier-Schicht in `thread_repository` anfassen (Sortier-Key zur Laufzeit aus dem
  lebenden `MealEntry.createdAt` ableiten). Tötet die ganze Drift-Klasse, ist aber
  größer und braucht einen eigenen Plan. Als eigenes Board-Item angelegt.

Kein Nährwert-/Kalorien-/Sicherheits-WERT wird verändert, nur die Tagesreihenfolge
eines Eintrags. Daher nicht CRITICAL im Nährwert-Sinn; Verifikation trotzdem über die
zwei puren Tests plus ein manueller Geräte-Test.

## Rollback
Unkritisch, einzelner Commit. Revert stellt den alten Early-Return und das alte
Verhalten wieder her. Keine Datenmigration, kein Persistenz-Schema berührt.

## Schritte
- [x] 🟩 **Phase 1: Pure Funktionen + Gate-Umstellung + Entkopplung**
  - [x] 🟩 `mealEditNeedsThreadResync({DateTime? oldCreatedAt, required DateTime newCreatedAt, required bool valuesChanged})` als top-level Funktion in `lib/services/thread_repository.dart` (Doc-Kommentar)
  - [x] 🟩 `shouldRegenCoachOnEdit({required bool valuesChanged, required bool isPastDayEdit, required bool isRetroEdit})` als static auf `CoachSessionManager` (Doc-Kommentar)
  - [x] 🟩 In `confirm_screen.dart` `_appendToThread`: Gate auf `mealEditNeedsThreadResync(...)` umgestellt; nach dem Resync bei `valuesChanged == false` früh raus (kein Remove/Regen); Regen-Gate auf `!shouldRegenCoachOnEdit(...)` umgestellt
  - [x] 🟩 `flutter analyze` sauber (No issues found)
- [x] 🟩 **Phase 2: Pure Unit-Tests (lokal, ohne Netz/Gerät)**
  - [x] 🟩 Test 1 `test/meal_edit_resync_test.dart` (4 Fälle): Zeit-Edit -> true; Werte-Edit -> true; nichts -> false; `oldCreatedAt == null` -> false
  - [x] 🟩 Test 2 `test/repositories_test.dart` (2 Fälle): `updateMealItemTime` zieht den Sortier-`timestamp` auf `newAt`, same-day UND cross-day
  - [x] 🟩 Test 3 `test/coach_session_manager_test.dart` (4 Fälle): `shouldRegenCoachOnEdit` Zeit-Edit -> false; Werte-Edit live -> true; Werte-Edit past-day -> false; Werte-Edit retro -> false
  - [x] 🟩 `flutter test` grün: 389 (vorher 379, +10)
- [x] 🟩 **Phase 3: Board-Item für Fix (B)** im Backlog angelegt (`Zeit-Doppelquelle beseitigen`)

## Manueller Geräte-Test (nach dem Bau, durch Vanessa)
1. Eine Mahlzeit LIVE loggen (Zeit = jetzt), dann den Eintrag bearbeiten und NUR die
   Uhrzeit auf einen früheren Slot heute setzen (Beschreibung/Werte nicht ändern),
   speichern. Erwartung: der Eintrag rutscht an die der neuen Uhrzeit entsprechende
   Position (nicht ans Tagesende), Chip-Zeit und Position stimmen überein.
2. Zweiter Check: derselbe reine Zeit-Edit erzeugt KEINE neue Coach-Antwort (die
   bestehende Blase wandert mit, es kommt keine zweite dazu).
