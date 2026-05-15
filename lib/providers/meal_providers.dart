import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal_entry.dart';
import '../services/claude_client.dart';
import '../services/meal_repository.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  throw UnimplementedError('Override in main() with the opened box');
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
