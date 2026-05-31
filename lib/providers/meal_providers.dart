import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/favorite_meal.dart';
import '../models/meal_entry.dart';
import '../models/thread_item.dart';
import '../models/user_profile_settings.dart';
import '../models/weight_entry.dart';
import '../services/analytics_service.dart';
import '../services/calorie_target.dart';
import '../services/claude_client.dart';
import '../services/open_food_facts_client.dart';
import '../services/favorite_repository.dart';
import '../services/meal_repository.dart';
import '../services/settings_repository.dart';
import '../services/thread_repository.dart';
import '../services/weight_repository.dart';
import '../utils/weight_trend.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  throw UnimplementedError('Override in main() with the opened box');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('Override in main() with the opened box');
});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  throw UnimplementedError('Override in main() with the opened box');
});

final favoritesProvider = StreamProvider<List<FavoriteMeal>>((ref) {
  return ref.watch(favoriteRepositoryProvider).watch();
});

final threadRepositoryProvider = Provider<ThreadRepository>((ref) {
  throw UnimplementedError('Override in main() with the opened box');
});

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  throw UnimplementedError('Override in main() with the opened box');
});

// Stream of all weight entries the user has recorded, sorted by date
// ascending so the Trends chart reads left-to-right time-naturally.
final weightHistoryProvider = StreamProvider<List<WeightEntry>>((ref) {
  return ref.watch(weightRepositoryProvider).watch();
});

// Recent weight trajectory fed to the coach so it can judge whether loss/gain
// is in a safe range while producing milk. Null until there's enough history.
final weightTrendProvider = Provider<WeightTrend?>((ref) {
  final entries = ref.watch(weightHistoryProvider).valueOrNull ?? const [];
  return computeWeightTrend(entries);
});

final todayThreadProvider = StreamProvider<List<ThreadItem>>((ref) {
  return ref.watch(threadRepositoryProvider).watchToday();
});

// Days currently loaded into the Tagebuch endless-scroll thread. Always
// contains today; older days get prepended as the user scrolls up or jumps
// to a specific date.
final loadedDaysProvider = StateProvider<List<DateTime>>((ref) {
  final now = DateTime.now();
  return [DateTime(now.year, now.month, now.day)];
});

// Bottom-nav tab index, exposed so other screens can switch tabs programmatically.
final selectedTabProvider = StateProvider<int>((ref) => 0);

// App-wide theme mode (light/dark/system). Read once from settings on app
// start; updated via the settings screen.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// One-shot scroll request: set to a day to make the Tagebuch scroll to that
// day's header. Consumers must reset to null after handling.
final scrollToDayProvider = StateProvider<DateTime?>((ref) => null);

// Emits a map of day -> thread items for every loaded day, refreshed whenever
// the underlying box changes (any thread add/remove anywhere).
final loadedThreadProvider =
    StreamProvider<Map<DateTime, List<ThreadItem>>>((ref) async* {
  final repo = ref.watch(threadRepositoryProvider);
  final days = ref.watch(loadedDaysProvider);
  await for (final _ in repo.watchAllChanges()) {
    final map = <DateTime, List<ThreadItem>>{};
    for (final day in days) {
      map[day] = repo.getForDate(day);
    }
    yield map;
  }
});

final claudeClientProvider = Provider<ClaudeClient>((ref) => ClaudeClient());

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.watch(settingsRepositoryProvider));
});

final openFoodFactsClientProvider =
    Provider<OpenFoodFactsClient>((ref) => OpenFoodFactsClient());

final mealsProvider = StreamProvider<List<MealEntry>>((ref) {
  final repo = ref.watch(mealRepositoryProvider);
  return repo.watch();
});

final todayMealsProvider = Provider<List<MealEntry>>((ref) {
  final all = ref.watch(mealsProvider).valueOrNull ?? const [];
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  return all.where((m) => m.createdAt.isAfter(startOfDay)).toList();
});

final yesterdayMealsProvider = Provider<List<MealEntry>>((ref) {
  final all = ref.watch(mealsProvider).valueOrNull ?? const [];
  final now = DateTime.now();
  final startOfYesterday = DateTime(now.year, now.month, now.day - 1);
  final startOfToday = DateTime(now.year, now.month, now.day);
  return all
      .where((m) =>
          m.createdAt.isAfter(startOfYesterday) &&
          m.createdAt.isBefore(startOfToday))
      .toList();
});

final userProfileProvider = StreamProvider<UserProfileSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).watchProfile();
});

final calorieTargetProvider = Provider<int>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull ??
      UserProfileSettings.defaults();
  return calculateDailyCalorieTarget(profile);
});

final macroTargetsProvider = Provider<MacroTargets>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull ??
      UserProfileSettings.defaults();
  final kcal = ref.watch(calorieTargetProvider);
  return calculateMacroTargets(profile, kcal);
});

final insightLoadingProvider = StateProvider<bool>((ref) => false);

// Meals saved in the current scan-session that are NOT yet handed to the
// coach. The barcode flow appends here when the user taps "+ Noch einen
// scannen" and drains the list when the user finally taps "Speichern" — at
// that point all queued meals plus the current one go to the coach as a
// single bundled call. Other flows (text, photo) leave this empty.
final pendingScanBundleProvider =
    StateProvider<List<MealEntry>>((ref) => const []);

// Up to 3 distinct meals from the user's last 30 days whose summary contains
// every token of [query] (case-insensitive substring match). Deduped by
// lowercased summary, most-recent occurrence wins. Empty until the query has
// at least 2 characters, so the suggestions don't flicker on every keystroke.
//
// Intent: nutrition trackers see the same products over and over (a specific
// brand of skyr, a specific cereal). Surfacing those as one-tap chips skips
// a parseMeal call and keeps brand-accurate macros instead of a generic
// estimate.
final mealHistorySuggestionsProvider =
    Provider.family<List<MealEntry>, String>((ref, query) {
  final trimmed = query.trim();
  if (trimmed.length < 2) return const [];
  final all = ref.watch(mealsProvider).valueOrNull ?? const [];
  final tokens =
      trimmed.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
  final cutoff = DateTime.now().subtract(const Duration(days: 30));
  final matches = <MealEntry>[];
  final seen = <String>{};
  // mealsProvider yields newest first.
  for (final m in all) {
    if (m.createdAt.isBefore(cutoff)) continue;
    final summaryLower = m.summary.toLowerCase();
    if (!tokens.every(summaryLower.contains)) continue;
    if (!seen.add(summaryLower)) continue;
    matches.add(m);
    if (matches.length >= 3) break;
  }
  return matches;
});

// Bumped whenever something elsewhere in the app has signaled that the
// user almost certainly wants to type into the meal input next: tapping
// a meal-reminder notification, picking a photo, finishing onboarding.
// The home input listens for changes and pulls focus + brings up the
// keyboard. Using an int counter (rather than a bool) so consecutive
// requests still trigger a notify even if the value doesn't flip.
final mealInputFocusRequestProvider = StateProvider<int>((ref) => 0);

// One-shot prefill payload for the home meal input. Other parts of the app
// (e.g. coach-response follow-up chips) push a question here and clear it
// to null after the input pulls the value. Bundles a payload + a version
// counter so a repeated tap with the same text still re-fires the prefill.
class MealInputPrefill {
  final String text;
  final int version;
  const MealInputPrefill({required this.text, required this.version});
}

final mealInputPrefillProvider =
    StateProvider<MealInputPrefill?>((ref) => null);

final mealsByDayProvider = Provider<Map<DateTime, List<MealEntry>>>((ref) {
  final all = ref.watch(mealsProvider).valueOrNull ?? const [];
  final grouped = <DateTime, List<MealEntry>>{};
  for (final meal in all) {
    final day = DateTime(
      meal.createdAt.year,
      meal.createdAt.month,
      meal.createdAt.day,
    );
    grouped.putIfAbsent(day, () => []).add(meal);
  }
  return grouped;
});
