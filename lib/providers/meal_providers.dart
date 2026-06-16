import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/favorite_meal.dart';
import '../models/meal_entry.dart';
import '../models/thread_item.dart';
import '../models/user_profile_settings.dart';
import '../models/weight_entry.dart';
import '../services/analytics_service.dart';
import '../services/calorie_target.dart';
import '../services/claude_client.dart';
import '../services/meal_aggregation.dart';
import '../services/micronutrient_targets.dart';
import 'ui_providers.dart';
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

// UI-orchestration state (selectedTab, theme, scrollToDay, input focus,
// input prefill, chat-loading) lives in providers/ui_providers.dart.

final claudeClientProvider = Provider<ClaudeClient>((ref) {
  // Inject the consent resolver so the client can short-circuit any
  // network call when the user hasn't ticked the mandatory Art. 9
  // health-data consent in onboarding. The resolver reads the
  // SettingsRepository on every call (no cached value) - that way a
  // mid-session revocation via Settings takes effect immediately
  // without a provider rebuild.
  final settings = ref.read(settingsRepositoryProvider);
  return ClaudeClient(
    healthDataConsentAtResolver: settings.getHealthDataConsentAt,
    // Same anonymous install-id the analytics service uses (#9). The
    // Worker pseudonymises it with APP_SECRET before logging - the raw
    // id never leaves the device's network surface beyond the headers,
    // and is never persisted in any audit log line.
    installIdResolver: settings.getOrCreateAnalyticsId,
  );
});

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
  return mealsForDay(all, DateTime.now());
});

final yesterdayMealsProvider = Provider<List<MealEntry>>((ref) {
  final all = ref.watch(mealsProvider).valueOrNull ?? const [];
  return mealsForDay(all, DateTime.now().subtract(const Duration(days: 1)));
});

// Meals belonging to the day the diary is currently focused on. Equivalent
// to todayMealsProvider when focusedDay == today, but rebinds to any
// other selected day so the NutritionHeader and thread show that day's
// values instead. Use this anywhere the diary view needs "the meals for
// the day the user is looking at", not "today specifically".
final focusedDayMealsProvider = Provider<List<MealEntry>>((ref) {
  final all = ref.watch(mealsProvider).valueOrNull ?? const [];
  final day = ref.watch(focusedDayProvider);
  return mealsForDay(all, day);
});

// Thread items for the focused day. Streams from the thread repository on
// every change; recomputes the bucket when the focused day flips.
final focusedDayThreadProvider = StreamProvider<List<ThreadItem>>((ref) {
  final repo = ref.watch(threadRepositoryProvider);
  final day = ref.watch(focusedDayProvider);
  return repo.watchForDate(day);
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

// Micronutrient totals for the focused day. Same shape as
// todayMicronutrientsProvider but rebinds to the day the user is viewing.
// Supplement contribution still applies on past days (we don't time-shift
// the supplement intake - it's a daily recurring stack).
final focusedDayMicronutrientsProvider =
    Provider<Map<String, double>>((ref) {
  final meals = ref.watch(focusedDayMealsProvider);
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
// Recent meals from the user's last 30 days within +/- 2h of the current
// wall-clock time. Used as a parseMeal hint when the input is photo-only
// (no typed text to substring-match against), so the parser gets a
// "this user often eats X at this time of day" vocabulary. Helps with
// the Pflaumen-vs-Heidelbeeren color-ambiguity class of vision errors:
// if the user has logged Heidelbeeren+Joghurt 20 mornings in a row,
// the parser should not flip to Pflaumen+Sahne on the 21st.
//
// Returns up to 5 distinct summaries, most-recent occurrence wins per
// summary. Empty if no history yet.
final mealHistoryByTimeOfDayProvider = Provider<List<MealEntry>>((ref) {
  final all = ref.watch(mealsProvider).valueOrNull ?? const [];
  if (all.isEmpty) return const [];
  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(days: 30));
  final currentHour = now.hour;
  final matches = <MealEntry>[];
  final seen = <String>{};
  for (final m in all) {
    if (m.createdAt.isBefore(cutoff)) continue;
    // Wrap-around aware window: 23:00 logged meal is relevant to a 01:00
    // photo, and vice versa.
    final hourDelta = (m.createdAt.hour - currentHour).abs();
    final delta = hourDelta > 12 ? 24 - hourDelta : hourDelta;
    if (delta > 2) continue;
    final key = m.summary.toLowerCase();
    if (!seen.add(key)) continue;
    matches.add(m);
    if (matches.length >= 5) break;
  }
  return matches;
});

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
  return groupMealsByDay(all);
});
