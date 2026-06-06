import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// UI-orchestration providers — pure presentation state that doesn't
// belong with the data/repository providers in meal_providers.dart.
// Split out per CODE_AUDIT.md section 3.4 #2: these serve a different
// layer than the data providers, and grouping them here makes the
// boundary explicit.
//
// What lives here: tab selection, theme, scroll requests, input focus,
// input prefill, and the chat-question loading flag — all reactive
// state that exists to drive widgets, not to model the domain.
//
// What does NOT live here: anything sourced from Hive (meals, profile,
// favorites, thread) or derived from it (today's meals, calorie target,
// micronutrient totals). Those stay in meal_providers.dart.

// Bottom-nav tab index, exposed so other screens can switch tabs
// programmatically.
final selectedTabProvider = StateProvider<int>((ref) => 0);

// App-wide theme mode (light/dark/system). Read once from settings on
// app start; updated via the settings screen.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// One-shot scroll request: set to a day to make the Tagebuch scroll to
// that day's header. Consumers must reset to null after handling.
final scrollToDayProvider = StateProvider<DateTime?>((ref) => null);

// Bumped whenever something elsewhere in the app has signaled that the
// user almost certainly wants to type into the meal input next: picking
// a photo, finishing onboarding, tapping a coach follow-up chip. The
// home input listens for changes and pulls focus + brings up the
// keyboard. Using an int counter (rather than a bool) so consecutive
// requests still trigger a notify even if the value doesn't flip.
final mealInputFocusRequestProvider = StateProvider<int>((ref) => 0);

// One-shot prefill payload for the home meal input. Other parts of the
// app (e.g. coach-response follow-up chips) push a question here and
// clear it to null after the input pulls the value. Bundles a payload
// + a version counter so a repeated tap with the same text still
// re-fires the prefill.
class MealInputPrefill {
  final String text;
  final int version;
  const MealInputPrefill({required this.text, required this.version});
}

final mealInputPrefillProvider =
    StateProvider<MealInputPrefill?>((ref) => null);

// True while a chat-question coach call is in flight; drives the
// CoachLoadingBanner above the input. Per-meal coach state is
// tracked separately on inFlightMealIds in CoachSessionManager — this
// provider is only for the chat path.
final insightLoadingProvider = StateProvider<bool>((ref) => false);
