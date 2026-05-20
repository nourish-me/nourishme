// NourishMe / NurtureTrack — Field Manual palette.
// Hand-tuned. Do NOT regenerate from ColorScheme.fromSeed —
// auto-generation produces generic M3 pastels that flatten the brand.
//
// Drop this file into lib/theme/ and import from main.dart:
//   import 'theme/nourishme_colors.dart';
//   ...
//   theme:     buildLightTheme(),
//   darkTheme: buildDarkTheme(),

import 'package:flutter/material.dart';

// Custom semantic colors beyond the M3 scheme.
// Used by KcalSummary for the sweet-spot / over-target rule.
const nmMoss      = Color(0xFF4B5A47); // sweet spot (80–100% target)
const nmAmberWarm = Color(0xFFC8884A); // over target
const nmPaper     = Color(0xFFF4EFE6); // warm background
const nmInkSoft   = Color(0xFF4F4A41);

const _light = ColorScheme(
  brightness: Brightness.light,
  primary:                Color(0xFF1E4A45), // pine
  onPrimary:              Color(0xFFFFFFFF),
  primaryContainer:       Color(0xFFC6E2DC), // pine-soft / user bubble
  onPrimaryContainer:     Color(0xFF04201D),
  secondary:              Color(0xFFC8884A), // amber / warmth carrier
  onSecondary:            Color(0xFFFFFFFF),
  secondaryContainer:     Color(0xFFFFE0B8), // coach bubble (after token swap)
  onSecondaryContainer:   Color(0xFF2A1900),
  tertiary:               Color(0xFF6B4554), // plum / caution
  onTertiary:             Color(0xFFFFFFFF),
  tertiaryContainer:      Color(0xFFF4D9E3), // safety warnings stay here
  onTertiaryContainer:    Color(0xFF2A0D1A),
  error:                  Color(0xFFB3261E),
  onError:                Color(0xFFFFFFFF),
  errorContainer:         Color(0xFFF9DEDC),
  onErrorContainer:       Color(0xFF410E0B),
  surface:                Color(0xFFFBF7EF), // paper-hi
  onSurface:              Color(0xFF1F1B16),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow:    Color(0xFFF2ECDE), // meal card / day card
  surfaceContainer:       Color(0xFFEDE6D7), // input bar
  surfaceContainerHigh:   Color(0xFFE6DECC),
  surfaceContainerHighest:Color(0xFFDDD3BD), // progress track
  onSurfaceVariant:       Color(0xFF4F4A41),
  outline:                Color(0xFF847E72),
  outlineVariant:         Color(0xFFD5CEC0),
);

const _dark = ColorScheme(
  brightness: Brightness.dark,
  primary:                Color(0xFFA6CCC4),
  onPrimary:              Color(0xFF03332F),
  primaryContainer:       Color(0xFF235650),
  onPrimaryContainer:     Color(0xFFC2E8E1),
  secondary:              Color(0xFFFFC07A),
  onSecondary:            Color(0xFF482A00),
  secondaryContainer:     Color(0xFF6B4F1E),
  onSecondaryContainer:   Color(0xFFFFE0B8),
  tertiary:               Color(0xFFE5B5C5),
  onTertiary:             Color(0xFF3E2030),
  tertiaryContainer:      Color(0xFF502736),
  onTertiaryContainer:    Color(0xFFF4D9E3),
  error:                  Color(0xFFF2B8B5),
  onError:                Color(0xFF601410),
  errorContainer:         Color(0xFF8C1D18),
  onErrorContainer:       Color(0xFFF9DEDC),
  surface:                Color(0xFF1B1812),
  onSurface:              Color(0xFFE8E2D4),
  surfaceContainerLowest: Color(0xFF15110B),
  surfaceContainerLow:    Color(0xFF221E17),
  surfaceContainer:       Color(0xFF28241D),
  surfaceContainerHigh:   Color(0xFF332E25),
  surfaceContainerHighest:Color(0xFF3D3829),
  onSurfaceVariant:       Color(0xFFC8C0AE),
  outline:                Color(0xFF9C9587),
  outlineVariant:         Color(0xFF4B4639),
);

ThemeData buildLightTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: _light,
      scaffoldBackgroundColor: nmPaper,
      // Editorial italic for AppBar titles.
      // Requires google_fonts in pubspec.yaml.
      // appBarTheme: AppBarTheme(
      //   titleTextStyle: GoogleFonts.newsreader(
      //     fontStyle: FontStyle.italic, fontWeight: FontWeight.w700,
      //     fontSize: 24, color: _light.onSurface,
      //   ),
      // ),
    );

ThemeData buildDarkTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: _dark,
      scaffoldBackgroundColor: const Color(0xFF15110B),
    );
