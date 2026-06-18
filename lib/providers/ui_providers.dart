import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// UI-orchestration providers - pure presentation state that doesn't
// belong with the data/repository providers in meal_providers.dart.
// Split out per CODE_AUDIT.md section 3.4 #2: these serve a different
// layer than the data providers, and grouping them here makes the
// boundary explicit.
//
// What lives here: tab selection, theme, scroll requests, input focus,
// input prefill, and the chat-question loading flag - all reactive
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

// One-shot "scroll to a specific meal" request. confirm_screen sets this
// after a retroactive save so the diary scrolls to the new entry even
// when the stored mealTime is far in the past (the autoscroll's "60s old"
// heuristic would skip a meal logged for 08:00 at 16:00 otherwise).
// Same-day and past-day both supported. Consumers reset to null after
// scrolling so a repeat save with the same id still fires.
final scrollToMealIdProvider = StateProvider<String?>((ref) => null);

// Build +35 follow-up: after a past-day save the scroll-to-meal request
// pairs with a 1.5 s highlight pulse on the target meal card. The pulse
// gives the user a clear visual anchor ("here's the thing you just
// logged") even when Scrollable.ensureVisible doesn't move the viewport
// as expected on iOS. Cleared automatically after the highlight runs.
final highlightedMealIdProvider = StateProvider<String?>((ref) => null);

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

// One-shot "fire this coach question NOW" payload. Pushed by the coach
// follow-up chip (Task A1, Build +34) so a tap sends the question
// immediately instead of pasting it into the input. HomeInput listens
// for changes and routes the text into `_askAsQuestion`. Same versioned-
// payload shape as the prefill so a repeat tap re-fires.
class CoachSubmitRequest {
  final String text;
  final int version;
  const CoachSubmitRequest({required this.text, required this.version});
}

final coachSubmitRequestProvider =
    StateProvider<CoachSubmitRequest?>((ref) => null);

// True while a chat-question coach call is in flight; drives the
// CoachLoadingBanner above the input. Per-meal coach state is
// tracked separately on inFlightMealIds in CoachSessionManager - this
// provider is only for the chat path.
final insightLoadingProvider = StateProvider<bool>((ref) => false);

// The day the diary is currently focused on. Drives the AppBar title, the
// NutritionHeader values, and (after the Single-Day-View refactor) the
// thread body. Default: today, normalized to local midnight. Setting this
// to a different day jumps the whole diary to that day - no scrolling,
// no per-day cards: one diary view = one day.
//
// Bounds: callers must not set this to a future day (UI guards on the
// picker side: future days are not selectable).
final focusedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// One-shot bump that signals the diary to scroll to the bottom of today
// (most recent item) regardless of the user's current scroll position.
// Used when an action the user actively initiated would otherwise leave
// their reply off-screen: typing a chat question while scrolled into
// yesterday's entries should still surface the reply when it lands.
// The auto-scroll dispatcher's "only follow if near bottom" heuristic
// is the right default for ambient updates but the wrong call for
// explicit user actions.
final scrollToBottomRequestProvider = StateProvider<int>((ref) => 0);
