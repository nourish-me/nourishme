import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/favorite_meal.dart';
import '../models/meal_entry.dart';
import '../models/user_profile_settings.dart';
import '../services/calorie_target.dart';
import '../services/claude_client.dart';
import '../services/favorite_repository.dart';
import '../services/meal_repository.dart';
import '../services/settings_repository.dart';

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

final claudeClientProvider = Provider<ClaudeClient>((ref) => ClaudeClient());

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

final latestTipProvider = StateProvider<String?>((ref) => null);

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
