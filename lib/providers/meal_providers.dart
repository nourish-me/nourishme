import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/favorite_meal.dart';
import '../models/meal_entry.dart';
import '../models/thread_item.dart';
import '../models/user_profile_settings.dart';
import '../models/weight_entry.dart';
import '../services/analytics_service.dart';
import '../services/calorie_target.dart';
import '../services/claude_client.dart';
import '../services/micronutrient_targets.dart';
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

// In-thread "anything to use up today?" state shared between the
// CoachSessionManager (which writes when it asks) and CoachBubble
// (which reads to decide whether to render the inline reply input).
class CoachAskState {
  final String? askedMealId;
  final String? ingredients;
  const CoachAskState({this.askedMealId, this.ingredients});

  factory CoachAskState.from(SettingsRepository repo) => CoachAskState(
        askedMealId: repo.getCoachLastAskedAtMealId(),
        ingredients: repo.getCoachTodaysIngredients(),
      );
}

class CoachAskNotifier extends StateNotifier<CoachAskState> {
  CoachAskNotifier(this._repo) : super(CoachAskState.from(_repo));
  final SettingsRepository _repo;

  void reload() => state = CoachAskState.from(_repo);

  Future<void> submitIngredients(String text) async {
    await _repo.setCoachTodaysIngredients(text);
    reload();
  }
}

final coachAskStateProvider =
    StateNotifierProvider<CoachAskNotifier, CoachAskState>(
  (ref) => CoachAskNotifier(ref.read(settingsRepositoryProvider)),
);

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

// UI-orchestration state (selectedTab, theme, scrollToDay, input focus,
// input prefill, chat-loading) lives in providers/ui_providers.dart.

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

// Today's micronutrient running totals, keyed by MicronutrientKey.
// Sums the per-meal estimates the parser stored on each MealEntry plus
// the active daily supplement (if configured). Only non-zero keys
// appear in the map (the donut UI iterates this directly).
//
// The detail-modal UI re-computes the food vs. supplement split itself
// from these two sources - they're aggregated here only because the
// donut just needs the total.
final todayMicronutrientsProvider = Provider<Map<String, double>>((ref) {
  final meals = ref.watch(todayMealsProvider);
  final totals = sumMicronutrientsFor(meals);
  final supplements =
      ref.watch(userProfileProvider).valueOrNull?.activeSupplements ??
          const [];
  for (final s in supplements) {
    for (final entry in s.values.entries) {
      totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
    }
  }
  return totals;
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

// Meals saved in the current scan-session that are NOT yet handed to the
// coach. The barcode flow appends here when the user taps "+ Noch einen
// scannen" and drains the list when the user finally taps "Speichern" - at
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
