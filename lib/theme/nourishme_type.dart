// NourishMe type system - iOS-native scale on Material 3 slots.
// SF Pro = system default (fontFamily left null on iOS).
// Newsreader italic = brand accent only. JetBrains Mono = eyebrow.
// Sizes are BASE at standard Dynamic Type; TextScaler handles scaling.
//
// Source of truth: design_handoff_type_system handoff from Cloud Design,
// see docs/ for the full README. Seven tokens, mapped to Material 3 slots.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme appTextTheme(ColorScheme scheme) {
  final ink = scheme.onSurface;
  final inkSoft = scheme.onSurfaceVariant;

  return TextTheme(
    // display - brand / hero moments only. Newsreader italic.
    displaySmall: GoogleFonts.newsreader(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
      height: 1.12,
      letterSpacing: -0.5,
      color: ink,
    ),
    // titleLarge - the one big AppBar title per screen.
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.20,
      letterSpacing: -0.3,
      color: ink,
    ),
    // titleMedium - card & section titles. Weight, not size, = hierarchy.
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.29,
      letterSpacing: -0.2,
      color: ink,
    ),
    // bodyLarge - primary reading text + coach bubble body.
    bodyLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: -0.2,
      color: ink,
    ),
    // bodyMedium - secondary text, subtitles, metadata.
    bodyMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.40,
      letterSpacing: -0.1,
      color: inkSoft,
    ),
    // bodySmall - caption: values, timestamps, helper text.
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.35,
      letterSpacing: 0,
      color: inkSoft,
    ),
    // labelSmall - mono eyebrow. Uppercase the STRING at call site.
    labelSmall: GoogleFonts.jetBrainsMono(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.20,
      letterSpacing: 0.9,
      color: inkSoft,
    ),
  );
}
