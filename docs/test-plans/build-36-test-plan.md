# Build +36 Test Plan

Per feature: one happy path + 2-5 edge cases. Marked as **🟢 V** (Vanessa tests on device) or **🟦 C** (Claude tests via unit test or code audit). Each item states the expected behaviour.

Bundled fixes in +36:

1. P0 Safety-Phase: lactation profile doesn't get pregnancy warnings (Isabella + Julia)
2. kcal calibration for single foods (Henrike)
3. Diary header date as prominent pill (retro-logging discovery cluster: Eva + Svenja + Isabella)
4. Onboarding daily-volume slider as "calculated card" (Isabella)
5. History tiles show top-3 micros with status icons (Isabella + Sarah + Corina)

Test on the local +36 install (Installation `93FC1A1B`). If all green: commit, push, upload to TestFlight.

---

## 0. Smoke Test (run first)

**What:** App starts cleanly with existing profile + data intact, basic flow works end-to-end. Catches regressions before diving into fix-specific tests.

- 🟢 V: Cold-launch app. Expected: opens to diary without crash, profile preserved, recent meals visible.
- 🟢 V: Log one text meal („Joghurt mit Banane"). Expected: meal saves, kcal+macros shown, coach reply arrives within ~5s.
- 🟢 V: Open Verlauf tab. Expected: list of recent days renders.
- 🟢 V: Open Settings → Profil. Expected: phase, weight, dietary style, allergies all match pre-+36 state.

---

## 1. P0 Safety-Phase: lactation profile doesn't get pregnancy warnings

**What:** New filter `filterPregnancyWarningsIfLactationOnly()` in `safety_rules.dart` plus "PHASE-DISZIPLIN" block in `parse_de.dart` + `parse_en.dart`. Lactation-only profile must not see pregnancy-specific warnings (raw-milk cheese, raw fish listeria, etc.).

- 🟢 V Happy: Profile = lactation only (not pregnant). Log „Mozzarella Carpaccio". Expected: NO „in Schwangerschaft meiden"-wording. Either no warning or a lactation-appropriate hint.
- 🟢 V Edge: Profile = pregnant. Log „Mozzarella Carpaccio". Expected: pregnancy raw-milk-cheese warning STILL appears.
- 🟢 V Edge: Profile = lactation only. Log „Räucherlachs auf Pfannkuchen". Expected: NO pregnancy listeria warning.
- 🟢 V Edge: Profile = pregnant AND lactating (tandem). Log „Mozzarella Carpaccio". Expected: pregnancy warning appears (because user IS pregnant).
- 🟢 V Counter: Profile = lactation only. Log „1 Glas Wein". Expected: alcohol warning STILL appears (not pregnancy-specific, applies to lactation too).
- 🟢 V Counter: Profile = lactation only. Log „Thunfisch-Sushi". Expected: appropriate mercury/raw-fish warning if any, but NOT "in Schwangerschaft meiden" wording.
- 🟦 C: Unit tests in `test/safety_rules_test.dart` cover `filterPregnancyWarningsIfLactationOnly` (322 tests green).

---

## 2. kcal calibration for single foods

**What:** Single-food kcal anchors injected into parse prompt: „Ei gekocht 1 Stück (M, 58g) ≈ 78 kcal; 1 großes Ei (63g) ≈ 90 kcal. NIE über 100 kcal pro Stück." Prevents the Henrike-pattern where a single egg got 155 kcal.

- 🟢 V Happy: Log via text „1 gekochtes Ei". Expected: kcal between 70-95, NOT 155.
- 🟢 V Edge: Log via text „2 Spiegeleier mit Butter und Schinken". Expected: reasonable composite ~250-350 kcal (2 eggs ~160-180 + butter + ham).
- 🟢 V Edge: Take photo of a single hard-boiled egg on a plate. Expected: kcal between 70-95.
- 🟢 V Edge: Log via text „1 Banane". Expected: ~90-110 kcal (not 200+).
- 🟢 V Edge: Log via text „1 Apfel mittel". Expected: ~70-100 kcal.
- 🟢 V Counter (Simone-pattern, still open): Log via text „Hühnersuppe mit Conchigliette, 380g Portion". Expected: kcal closer to ~555. NOTE: if still too low (e.g. 320), that's the open Simone-retest; would inform a main-dish anchor for a later build, NOT a +36 blocker.

---

## 3. Diary header date pill (retro-logging discovery)

**What:** Diary header date is now an outlined pill with calendar icon + arrow_drop_down. Uses `secondaryContainer` tint when not on today (visual cue: you're looking at a past day).

- 🟢 V Happy: Open Tagebuch on today's date. Expected: header shows pill with calendar icon + „Heute" or date + drop-down arrow, outlined with neutral tint.
- 🟢 V Happy: Tap the pill. Expected: date picker opens.
- 🟢 V Edge: Pick „gestern" in the date picker. Expected: pill now tinted with `secondaryContainer` (visual cue: not on today). Diary body shows yesterday's meals.
- 🟢 V Edge: Switch back to today (via pill tap → today). Expected: tint reverts to neutral. Diary body shows today's meals.
- 🟢 V Edge: Empty diary (e.g. no meals yet today). Expected: pill still visible and tappable.
- 🟢 V Counter: Verify the pill works on a fresh onboarding too (in case profile state matters): complete onboarding → land on diary → pill visible.

---

## 4. Onboarding daily-volume slider as "calculated card"

**What:** Tagesvolumen-Slider wrapped in a `primaryContainer.withValues(alpha: 0.35)` container with ✨ icon (`Icons.auto_awesome_outlined`), „Schätzung"-Badge, and helper text „Nur anpassen wenn du dein Volumen genauer kennst.". New ARB keys: `onboardingVolumeEstimateBadge`, `onboardingVolumeEstimateHint`.

- 🟢 V Happy: Start new onboarding flow, step through until daily-volume slider. Expected: slider is wrapped in a tinted card with ✨ icon on the left, „Schätzung"-Badge near the top, helper text underneath.
- 🟢 V Happy: Slider's initial value = the calculated estimate from prior questions (number of children + exclusive vs. partial breastfeeding).
- 🟢 V Edge: Adjust the slider manually. Expected: value updates, card framing stays consistent.
- 🟢 V Edge: Switch app to EN locale, redo onboarding. Expected: badge + helper text appear in English (new ARB strings are present and used).
- 🟢 V Edge: Complete onboarding → diary loads → open Settings → Profil → daily-volume value matches what onboarding stored.
- 🟢 V Counter: Helper text actually reads as helpful framing (not duplicating the badge). Visual hierarchy works (icon + badge stand out, helper is subordinate).

---

## 5. History tiles top-3 micros with status icons

**What:** `_MicroPillChip` enhanced in `lib/screens/history_screen.dart`: 12px font, status icons (`Icons.south_rounded` for <50%, `Icons.check_rounded` for ≥100%), `errorContainer` / `primaryContainer` / `secondaryContainer` colouring based on % achievement.

- 🟢 V Happy: Day with mixed micros, e.g. Iodine 30%, Calcium 75%, DHA 110%. Expected: Iodine pill = errorContainer + ↓ icon, Calcium pill = primaryContainer (no icon), DHA pill = secondaryContainer + ✓ icon.
- 🟢 V Edge: Day where all 3 micros < 50%. Expected: all pills errorContainer + ↓.
- 🟢 V Edge: Day where all 3 micros ≥ 100%. Expected: all pills secondaryContainer + ✓.
- 🟢 V Edge: Day with a long-named micro (e.g. „Vitamin B12 110%"). Expected: pill doesn't overflow; text legible at 12px.
- 🟢 V Edge: Day with 0 meals. Expected: no pills (or empty section), no crash.
- 🟢 V Edge: Verify exactly which 3 micros are shown matches `profile.selectedMicronutrients` (or defaults for the profile).
- 🟢 V Counter: Open same day on multiple devices / re-open the app: pills render consistently (no random colouring).

---

## Post-Test Checklist

If all 🟢 V tests are green:

- [ ] Commit `+36` changes with reference to fixed beta-feedback items
- [ ] `git push` to main
- [ ] Upload to TestFlight (Fastlane or Xcode)
- [ ] Update beta tester messages with new build number
- [ ] Mark Task #29 (`+36-6: Build, install, commit`) as completed

If any 🟢 V test fails:

- [ ] Document failure in `docs/beta-feedback-log.md` under "Open Items"
- [ ] Decide: blocking fix → patch in +36, OR defer → ship +36, fix in +37
