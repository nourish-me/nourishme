# Prompt for Claude Code

Copy everything below the `---` into a new Claude Code chat in your NourishMe Flutter repo, with this folder attached as context.

---

I'm attaching a design hand-off bundle from our design pass for TestFlight 1.1 (`design_handoff/testflight_1_1/`). It contains:

- `README.md` — full spec for 5 onboarding screens, 4 empty states, and 8 custom icons.
- `icons/svg/` — 8 SVG icon sources at 24 px base.
- `brand-tokens.dart` / `brand-tokens.css` — Field Manual palette.
- `mockup/NourishMe TestFlight 1.1.html` — visual reference (open in a browser).

**Task.** Implement these screens in our existing Flutter app, replacing the current Material 3 default visuals. Specifically:

1. **Set up theme.** Make sure `lib/theme/nourishme_colors.dart` matches the token list in `README.md`. Wire `ThemeData` to use the Field Manual palette as the M3 ColorScheme (`primary: pine`, `secondary: amber`, `tertiary: plum`, `surface: paperHi`, `background: paper`, etc.). Add `Newsreader`, `Inter`, and `JetBrains Mono` to `pubspec.yaml` and set the `textTheme` so `displayLarge` / `headlineMedium` use Newsreader italic, `bodyMedium` uses Inter, and `labelSmall` uses JetBrains Mono.

2. **Drop the icons.** Copy all 8 SVGs into `assets/icons/`, register them in `pubspec.yaml`, and add a small `NMIcons` wrapper that returns `SvgPicture.asset(...)` for each one with a sensible default size.

3. **Build onboarding.** Create `lib/screens/onboarding/` with one file per screen:
   - `welcome_screen.dart`
   - `phase_screen.dart` (multi-select; remember the multi-state case: schwanger + stillend can both be true)
   - `stats_screen.dart` (height + weight steppers, activity segmented)
   - `children_screen.dart` (conditional blocks — trimester picker only if pregnant, milk-volume slider only if nursing/pumping)
   - `confirm_screen.dart` (big kcal number, pull quote, nutrient breakdown rows)

   Wire them with a simple state holder (Provider / Riverpod — whatever's already in the project) called `OnboardingState` holding `{ phases: Set<Phase>, height, weight, activityLevel, childrenCount, trimester, dailyMilkMl }`. Final screen feeds into the existing `BMRCalculator` to compute the kcal target.

4. **Build empty states.** Create `lib/widgets/empty/`:
   - `empty_today.dart`
   - `empty_history.dart`
   - `empty_favorites.dart`
   - `empty_safety.dart`

   Wire them into the existing `home_screen.dart` / history / favorites views as the rendered widget when the relevant data list is empty.

5. **Match spacing and typography precisely.** Use the values in `README.md` literally — 22 pt gutters, 16 pt card radius, exact font sizes. The HTML in `mockup/` is a visual reference; open it in a browser if you need to verify spacing or color before guessing.

**Constraints:**
- Don't port the React. The HTML uses React because it was made in a design tool. Port the **design**, using our existing Flutter widgets, Material 3 components where they fit (e.g. `SegmentedButton`, `ListTile`), and `flutter_svg` for icons.
- Use **token IDs** in code, never hex (`NMColors.pine`, not `Color(0xFF1E4A45)`).
- Stay strictly within the screens listed above. Settings, detail views, chat, and search remain on Material 3 defaults per the design brief.
- All copy is in German and matches the strings in `README.md` exactly — they were tone-tested.

Start by reading `README.md` end-to-end, then propose a file plan before writing code so I can confirm it matches our repo conventions.
