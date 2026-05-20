// NourishMe / NurtureTrack — Field Manual palette.
// Source of truth: handoff/nourishme_logo_bowl/brand-tokens.dart.
// Mirrored in docs/style.css :root so app and landing stay in sync.
// Do NOT regenerate via ColorScheme.fromSeed.

import 'package:flutter/material.dart';

class NMColors {
  // Surfaces
  static const paper      = Color(0xFFF4EFE6);
  static const paperHi    = Color(0xFFFBF7EF);
  static const paperLo    = Color(0xFFEAE2D2);
  static const paperDeep  = Color(0xFFDDD3BD);

  // Text
  static const ink        = Color(0xFF1F1B16);
  static const inkSoft    = Color(0xFF4F4A41);
  static const inkMute    = Color(0xFF847E72);

  // Brand
  static const pine       = Color(0xFF1E4A45);
  static const pineDeep   = Color(0xFF0F2D2A);
  static const amber      = Color(0xFFC8884A);
  static const amberWarm  = Color(0xFFD89A5B);

  // Functional
  static const rust       = Color(0xFF9C4623);
  static const moss       = Color(0xFF4B5A47);
  static const plum       = Color(0xFF6B4554);

  // Lines
  static const rule       = Color(0xFFD5CEC0);
}

// Legacy aliases — kept so existing callsites keep working.
// Prefer NMColors.* in new code.
const nmMoss      = NMColors.moss;
const nmAmberWarm = NMColors.amber;
const nmPaper     = NMColors.paper;
const nmInkSoft   = NMColors.inkSoft;

const _light = ColorScheme(
  brightness: Brightness.light,
  primary:                NMColors.pine,
  onPrimary:              Color(0xFFFFFFFF),
  primaryContainer:       Color(0xFFC6E2DC), // pine-soft / user bubble
  onPrimaryContainer:     Color(0xFF04201D),
  secondary:              NMColors.amber,
  onSecondary:            Color(0xFFFFFFFF),
  secondaryContainer:     Color(0xFFFFE0B8), // coach bubble
  onSecondaryContainer:   Color(0xFF2A1900),
  tertiary:               NMColors.plum, // caution / safety warning icons
  onTertiary:             Color(0xFFFFFFFF),
  tertiaryContainer:      Color(0xFFF4D9E3), // safety warning surface
  onTertiaryContainer:    Color(0xFF2A0D1A),
  error:                  Color(0xFFB3261E),
  onError:                Color(0xFFFFFFFF),
  errorContainer:         Color(0xFFF9DEDC),
  onErrorContainer:       Color(0xFF410E0B),
  surface:                NMColors.paperHi,
  onSurface:              NMColors.ink,
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow:    Color(0xFFF2ECDE), // meal card / day card
  surfaceContainer:       Color(0xFFEDE6D7), // input bar
  surfaceContainerHigh:   Color(0xFFE6DECC),
  surfaceContainerHighest:NMColors.paperDeep, // progress track
  onSurfaceVariant:       NMColors.inkSoft,
  outline:                NMColors.inkMute,
  outlineVariant:         NMColors.rule,
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
      scaffoldBackgroundColor: NMColors.paper,
    );

ThemeData buildDarkTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: _dark,
      scaffoldBackgroundColor: const Color(0xFF15110B),
    );
