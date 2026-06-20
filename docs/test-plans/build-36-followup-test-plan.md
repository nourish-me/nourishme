# Build +36 Follow-ups Test Plan (T40 / T41 / T42)

After main +36 (commit f2520da) was tested in two rounds (see `build-36-test-plan.md` and `build-36-rework-test-plan.md`), this plan covers the three follow-up tasks committed in e1ea786. Re-test on a fresh local build (`flutter clean && flutter run -d <iphone>` or release build).

Per feature: smoke + happy + edge + counter. Marked as **🟢 V** (Vanessa tests on device) or **🟦 C** (Claude tests via code audit).

**What's new vs the +36 you already tested:**

- **T40** Coach prompt rule: daily target framed as weekly average when evening kcal below target (Eva)
- **T41** Favourites discovery SnackBar: one-time tip after first meal save points at the star icon (Eva + Svenja + Corina)
- **T42** Day-switch scroll: scroll position resets to 0 (top) on past-day navigation when no preferredMealId is set (Isabella, partial fix)

---

## 0. Smoke Test

- 🟢 V: Cold-launch the app. Expected: opens to diary, profile preserved, recent meals visible.
- 🟢 V: Log a small text meal (e.g. „Apfel"). Expected: saves, kcal+macros render, coach reply within ~5s.
- 🟢 V: Navigate via header arrow to yesterday. Expected: lands on past day with „VERGANGENER TAG" eyebrow + „Heute" button in actions.
- 🟢 V: Return to today via „Heute" button. Expected: today's diary, lock-icon visible, no leftover past-day eyebrow.

---

## 1. T40 - Coach Tagesziel-Guardrail

**Goal:** Coach must NOT push „iss mehr" when evening kcal is below daily target. Should frame the daily target as a weekly average instead, so Eva does not feel guilt-tripped.

### Happy
- 🟢 V: Profil mit z.B. ~2400 kcal Tagesziel. Den ganzen Tag nur 1-2 kleine Mahlzeiten loggen (z.B. ~600 kcal total). Abends ab ~19h eine weitere Mahlzeit loggen. Coach-Antwort lesen.
  - **Expected:** keine Aufforderung „du musst noch X kcal essen", kein expliziter Snack-Vorschlag zur Auffüllung. Stattdessen Hinweis-Tonfall „Tagesziel ist ein Wochen-Richtwert, kleine Lücken sind ok" (oder ähnlich).

### Edge
- 🟢 V: Bei vollem Tagesziel (z.B. nachmittags bereits 2400 von 2400 kcal erreicht), abends noch eine Mahlzeit loggen. Coach soll nicht verwirrend „Wochen-Richtwert" erwähnen, sondern normal antworten (Über-Tagesziel ist ok, kein Vorwurf).

### Counter
- 🟢 V: Morgens um ~8h eine Mahlzeit loggen, vorher 0 kcal. Coach soll NICHT „Tagesziel als Wochen-Richtwert" thematisieren - es ist noch viel zu früh, das wäre off-topic.

### Code audit
- 🟦 C: `per_meal_de.dart` + `per_meal_en.dart` enthalten den „TAGESZIEL ALS WOCHENRICHTWERT"-Block; Wording ist konditioniert an „wenn am Abend unter Tagesziel", nicht trigger-happy.

---

## 2. T41 - Favoriten-Discovery-SnackBar

**Goal:** First meal save shows a one-time SnackBar pointing at the star icon (favourites feature), once and only once.

### Happy
- 🟢 V: Fresh install (oder via Settings → Reset Hive falls vorhanden, sonst app uninstall + reinstall). Erste Mahlzeit über das Save-Sheet abspeichern OHNE den Stern selbst zu drücken.
  - **Expected:** Nach Save-Pop erscheint kurz eine SnackBar mit einem Hinweis auf den Stern oben rechts beim Speichern. Wording sollte in DE etwas wie „Tipp: Tap den Stern beim Speichern, um Mahlzeiten als Favoriten zu sichern" sagen (Wording siehe `app_de.arb` → `favoritesTipMessage`).

### Edge
- 🟢 V: Direkt zweite Mahlzeit speichern. **Expected:** KEINE SnackBar mehr - Flag wurde mit der ersten Save-Aktion gesetzt und persistiert.
- 🟢 V: Bei der ersten Mahlzeit den Stern selbst aktiv setzen („Save as favourite") bevor Save. **Expected:** KEINE SnackBar - die Funktion wurde ja gerade aktiv verwendet, Tip wäre redundant.

### Counter
- 🟢 V: App schließen + neu öffnen nach erster SnackBar-Anzeige. Mahlzeit speichern. **Expected:** Tip kommt NICHT wieder - Flag persistiert über App-Restart.

### Code audit
- 🟦 C: `settings_repository.dart` hat `hasSeenFavoritesTip()` + `setFavoritesTipSeen()` mit Hive-Persistierung. `confirm_screen.dart` zeigt SnackBar nur wenn `!hasSeenFavoritesTip()` UND `!_saveAsFavorite`.

---

## 3. T42 - Day-Switch Scroll-to-Top

**Goal:** Past-day navigation jumps to position 0 (top of day) instead of landing mid-scroll. Specifically the case where no specific meal is being targeted.

### Happy
- 🟢 V: Heute 3-5 Mahlzeiten loggen, im Diary kräftig nach unten scrollen. Via Header-Arrow auf gestern (vergangener Tag mit Mahlzeiten falls vorhanden, sonst auf einen anderen vergangenen Tag) wechseln.
  - **Expected:** Scroll landet ganz oben - „VERGANGENER TAG"-Eyebrow + Datums-Header sind sofort sichtbar, NICHT mitten im Scroll-Verlauf.

### Edge
- 🟢 V: Auf vergangenem Tag mit nur 1 Mahlzeit, dann via „Heute"-Button zurück. **Expected:** Sauberer Übergang, kein flicker.
- 🟢 V: Mehrfacher Day-Switch hin und her (heute → gestern → vorgestern → heute). **Expected:** Jeder Wechsel landet beim erwarteten Scroll-Punkt, kein hängenbleiben.

### Counter
- 🟢 V (optional, schwer zu reproduzieren): Wenn von einer Push-Notification zu einer spezifischen Mahlzeit navigiert würde (mit `preferredMealId`), soll Scroll NICHT zu position 0 springen, sondern zur Mahlzeit. Ohne Push-Setup nicht direkt testbar - siehe Code-Audit.

### Code audit
- 🟦 C: `home_screen.dart` `scrollToDayProvider` handler: wenn `preferredMealId == null`, jump to position 0; wenn gesetzt, jump to meal. Debounce über `_lastScrollDispatchAt` mit 300ms cooldown verhindert mehrfache animation collisions.

---

## 4. Light regression checks

Diese sollten durch die Follow-ups NICHT betroffen sein, aber kurz verifizieren:

- 🟢 V: P0 Safety-Phase - mit Stillzeit-Profil eine Mozzarella-/Räucherlachs-Mahlzeit loggen. Erwartung: KEINE Schwangerschafts-Listerien-Warnung.
- 🟢 V: Onboarding-Schritt 5 + Schritt 7 zeigen ComputedCard mit „BERECHNET FÜR DICH"-Eyebrow korrekt an.
- 🟢 V: Tagebuch-Header zeigt Datum als Titel mit Arrow, Verlauf-Tab zeigt 3 NutrientCells pro Tag mit single-accent Farben.

---

## Post-Test Checklist

- [ ] Alle Smoke-Tests laufen durch (4 Items in §0)
- [ ] T40 happy + edge + counter passen
- [ ] T41 happy + 2 edges + counter passen
- [ ] T42 happy + 2 edges passen (counter via Code-Audit ok)
- [ ] Light regression checks ohne Auffälligkeiten
- [ ] Bei Findings: in `docs/beta-feedback-log.md` ergänzen und ggf. Build-Number-Plan aktualisieren

→ Wenn alle ✅: TestFlight-Upload via Xcode (Archive → Distribute App → App Store Connect).
