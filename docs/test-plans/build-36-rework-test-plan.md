# Build +36 Re-Test Plan (Post-Rework)

After Claude Design's UI rework, the kcal Suppen-Anker patch, and the Tandem-Settings fix. Re-test on a fresh local build (`flutter run -d <iphone>` after `flutter clean`).

Per feature: one happy path + 2-4 edge cases. Marked as **🟢 V** (Vanessa tests on device) or **🟦 C** (Claude tests via unit test or code audit).

What's new vs the +36 you tested in Round 1 (see `Build +36 Test-Plan.md` for original findings):

- 2 shared widgets (`NutrientCell`, `ComputedCard`) replace 3 separate +36 attempts
- Diary header: date IS the title, no pill. Past-day eyebrow + "Heute" reset chip
- Onboarding Schritt 5 + Schritt 7 use the same `ComputedCard` (no green tint / no sparkle)
- Verlauf: row of 3 NutrientCells with single-accent (amber / pine / plum / outline), one line each
- Trends: red gone, same single-accent as Tagebuch + Verlauf
- kcal: new Suppen-Anker for soups with a starchy component (anti-regression for Simone's Conchigliette)
- Settings: 4th Phase option for Tandem (Schwanger + milchproduzierend)
- FAQ landing-page entry "Was macht NourishMe und was bewusst nicht?" (goes live after `git push`, not testable on device)

---

## 0. Smoke Test

- 🟢 V: Cold-launch app. Expected: opens to diary, profile preserved, recent meals visible.
- 🟢 V: Log "Joghurt mit Banane" via text. Expected: saves, kcal+macros shown, coach reply ~5s.
- 🟢 V: Open Verlauf tab. Expected: list of days renders, each tile has kcal bar + (new) NutrientCell row.
- 🟢 V: Open Settings → Profil. Expected: phase + weight + diet style match pre-test state.

---

## 1. P0 Safety Phase (regression check)

Filter still works after the Settings refactor.

- 🟢 V: Profile = lactation only. Log "Mozzarella Carpaccio". Expected: no pregnancy warning.
- 🟢 V: Profile = pregnant only. Log "Mozzarella Carpaccio". Expected: pregnancy warning.
- 🟢 V Edge (now testable thanks to Tandem fix): Profile = "Schwanger + milchproduzierend". Log "Mozzarella Carpaccio". Expected: pregnancy warning STILL appears (user IS pregnant).
- 🟢 V Counter: Profile = lactation only. Log "1 Glas Wein". Expected: alcohol warning still appears (not pregnancy-specific).

---

## 2. kcal calibration (Suppen-Anker re-test)

Single-food anchors plus new Suppen-Anker for complex dishes.

- 🟢 V: Log "1 gekochtes Ei" → kcal 70-95.
- 🟢 V Counter (Simone-pattern, was 285 last time): Log "Hühnersuppe mit Conchigliette, 380g Portion". Expected: kcal in 380-570 range (Suppen-Anker 100-150 kcal/100g × 380g).
- 🟢 V Edge: Log "Frühstücks-Bowl mit Joghurt, Beeren, Müsli, Honig, 300g". Expected: composite reasonable (~350-500), no single-item-anchor pulldown.
- 🟢 V Edge: Log "1 Banane" → kcal 90-110. (single-item anchor not affected by the Suppen-Anker addition.)

---

## 3. Diary Header (date as title, past-day eyebrow + Heute chip)

- 🟢 V Happy: Open Tagebuch on today. Expected: title = "Heute" + small `arrow_drop_down`, NO pill/outline around it, no calendar icon.
- 🟢 V Edge: Tap the title. Expected: date picker opens (existing `showDatePicker` flow).
- 🟢 V Edge: Pick yesterday in the date picker. Expected: title becomes "Gestern" (or weekday + date), a Mono-Eyebrow "VERGANGENER TAG" appears above in amber (`secondary`), and a primaryContainer "Heute"-Chip sits to the right of the date.
- 🟢 V Edge: Tap the "Heute"-Chip while on past day. Expected: snaps back to today, eyebrow + chip disappear, title goes back to "Heute".
- 🟢 V Edge: Past day → the Lock/Schloss icon (Disclaimer) in the actions is **hidden**. Settings + Filter (if applicable) are still visible.
- 🟢 V Edge: Today → Lock icon visible again.

---

## 4. Onboarding ComputedCard (Schritt 5 + Schritt 7)

- 🟢 V Happy: Start a new onboarding flow. At Schritt 5 (Tagesvolumen). Expected: `surfaceContainerLow` card with hairline border, Mono-Eyebrow "BERECHNET FÜR DICH" preceded by a calculate-icon, `titleMedium` "Muttermilch pro Tag", primary-tinted kcal/ml line + info-button, hint, slider, age-hint at bottom. **No green tint, no ✨, no "Schätzung"-badge.**
- 🟢 V Happy: At Schritt 7 (Tagesziel). Expected: same card style (surfaceContainerLow, hairline, Mono-Eyebrow "BERECHNET FÜR DICH"), big Newsreader italic hero kcal in primary, lede line, divider, macro table.
- 🟢 V Edge: Place Schritt 5 + Schritt 7 cards visually side by side (mentally). Same surface, same border, same eyebrow font and color.
- 🟢 V Edge: Switch app to EN locale, redo onboarding. Both cards say "CALCULATED FOR YOU".
- 🟢 V Edge: Adjust the slider in Schritt 5. Card framing stays consistent; only the kcal/ml line updates live.

---

## 5. Verlauf NutrientCell (single-accent, one line)

- 🟢 V Happy: Day with mixed micros (Jod 30%, Calcium 75%, DHA 110%). Expected: row of 3 cells, each one line: name (ellipsis-capable) + right-aligned percent + thin (2.5px) bar below. Jod = amber bar 30%, Calcium = amber bar 75%, DHA = pine bar capped at 100%. **NO icons (no ↓, no ✓).**
- 🟢 V Edge: Day with extreme value (DHA 3250%). Expected: pine bar fully filled (capped), percent text "3250%" still legible.
- 🟢 V Edge: Day where all micros are < 50%. Expected: all amber, NO red anywhere.
- 🟢 V Edge: Day with a long-named micro. Expected: name ellipsises, percent stays visible, no two-line wrap.
- 🟢 V Edge: Day with 0 meals. Expected: no pills, no crash, no empty row.

---

## 6. Trends single-accent (no more red for under-target)

- 🟢 V Happy: Open Trends tab. Look at any micronutrient bar. Expected: under-target = amber (was red), met = pine (was green). NO red anywhere except possibly for actual error / safety states (none expected here).
- 🟢 V Edge: A micronutrient at e.g. 30% across multiple days. Expected: amber bars, not red.
- 🟢 V Edge: A micronutrient at 100%+. Expected: pine bar.

---

## 7. Tandem Settings (new 4th option)

- 🟢 V Happy: Open Settings → Profil → Phase. Expected: 4 tiles - Milchproduzierend / Schwanger / Schwanger + milchproduzierend / Weder noch.
- 🟢 V Edge: Tap "Schwanger + milchproduzierend". Expected: tile selects, trimester picker appears below (because the user is also pregnant).
- 🟢 V Edge: Set both, save profile. Close + reopen Settings. Expected: state persists, "Schwanger + milchproduzierend" still selected, trimester preserved.
- 🟢 V Edge: With Tandem active, the kcal target should include BOTH the pregnancy supplement AND the lactation supplement. Verify via Settings → Tagesziel or via the Tagebuch header kcal number.

---

## 8. Cross-Screen Mikro-Konsistenz (the big consistency check)

Final sanity check: visit Tagebuch (top strip), Verlauf (day tiles), Trends tab in one session.

- 🟢 V: For a nutrient at e.g. 60% today: Tagebuch strip + Verlauf tile + Trends bar all show the SAME amber color.
- 🟢 V: For a nutrient at e.g. 110% today: all three surfaces show pine (no green-shade variation, no red anywhere).
- 🟢 V: Specifically check Trends - confirm no `Colors.green.shade600`, `Colors.amber.shade700`, or red bars remain.

---

## Post-Test Checklist

If all 🟢 V green:

- [ ] Mark Task #29 (`+36-6: Build, install, commit`) → completed
- [ ] Commit all uncommitted changes (~22 files) with reference to fixed beta-feedback items
- [ ] `git push` to main (this also makes the FAQ landing-page entry live after GitHub Pages rebuild)
- [ ] Upload to TestFlight (Fastlane or Xcode)
- [ ] Tell me "ist auf TestFlight" so I can flip the relevant items in `docs/beta-feedback-log.md` from 🟡 → ✅ per the cadence memory
- [ ] Send the six open Tester-Rückfragen (Sender-Texte sind im Chat-Verlauf)

If any 🟢 V fails:

- [ ] Document failure here with ❌ + italic note
- [ ] Decide: patch in +36 (small change), or push to +37 (bigger work)
- [ ] Update `docs/beta-feedback-log.md` accordingly
