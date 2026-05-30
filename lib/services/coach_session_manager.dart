import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal_entry.dart';
import '../models/thread_item.dart';
import '../providers/meal_providers.dart';
import '../utils/weight_trend.dart';
import 'claude_client.dart';

// Tracks which meal IDs currently have a coach call in flight. Each saved
// meal fires its own coach call immediately — no debounce, no bundling.
//
// History: an earlier version of this file tried to bundle rapid-fire logs
// into one call via a 25-second timer. Live testing showed the wait felt
// sluggish even for the dominant single-item case, and the bundling logic
// had a subtle race where a save arriving during the calling phase would
// be lost. Reverted to per-meal fire-and-forget: simpler, instant feedback,
// each meal gets its own bubble + reply. The extra cost is marginal at
// beta volume and the bundling concept can be revisited later if usage
// patterns make it worthwhile (with a route-stack-driven trigger instead
// of a timer).
class CoachSessionManager extends StateNotifier<Set<String>> {
  CoachSessionManager(this._ref) : super(const {});

  final Ref _ref;

  // Fired by ConfirmScreen after a new meal is persisted. Edits bypass this
  // path; they re-generate their coach reply via the legacy direct call so
  // the existing insight-loading banner UX is preserved.
  void submitMeal(MealEntry meal, String locale) {
    state = {...state, meal.id};
    unawaited(_runCallFor(meal, locale));
  }

  Future<void> _runCallFor(MealEntry meal, String locale) async {
    final threadRepo = _ref.read(threadRepositoryProvider);
    final client = _ref.read(claudeClientProvider);
    final target = _ref.read(calorieTargetProvider);
    final byDay = _ref.read(mealsByDayProvider);
    final profile = _ref.read(userProfileProvider).valueOrNull;
    final trend = _ref.read(weightTrendProvider);
    final analytics = _ref.read(analyticsServiceProvider);

    final isDe = locale.toLowerCase().startsWith('de');
    final notableTrend = (trend != null && trend.isNotable)
        ? formatWeightTrendForCoach(trend, isDe: isDe)
        : null;

    // Day totals anchored to the meal's own day so retro-logged past-day
    // meals still reason against that day's running total.
    final mealDayKey =
        DateTime(meal.createdAt.year, meal.createdAt.month, meal.createdAt.day);
    final sameDay = byDay[mealDayKey] ?? const <MealEntry>[];
    final included = sameDay.any((m) => m.id == meal.id);
    final mealsForTotal = included ? sameDay : [...sameDay, meal];
    final totalKcal = mealsForTotal.fold<int>(0, (s, m) => s + m.kcal);
    final totalProtein =
        mealsForTotal.fold<double>(0, (s, m) => s + m.proteinG);

    final proteinTargetG =
        profile != null ? (profile.weightKg * 1.2).round() : 80;

    try {
      final response = await client.generatePerMealResponse(
        mealRawText: meal.rawText,
        mealSummary: meal.summary,
        mealKcal: meal.kcal,
        mealProteinG: meal.proteinG,
        mealCarbsG: meal.carbsG,
        mealFatG: meal.fatG,
        safetyWarnings: meal.safetyWarnings,
        totalKcalToday: totalKcal,
        targetKcal: target,
        totalProteinToday: totalProtein,
        proteinTargetG: proteinTargetG,
        numChildrenNursing: profile?.numChildrenNursing ?? 0,
        milkSharePercent: profile?.milkSharePercent ?? 0,
        weightKg: profile?.weightKg ?? 0,
        heightCm: profile?.heightCm ?? 0,
        ageYears: profile?.ageYears ?? 0,
        activityFactor: profile?.activityFactor ?? 1.375,
        isPregnant: profile?.isPregnant ?? false,
        trimester: profile?.trimester,
        dailyMilkVolumeMl: profile?.dailyMilkVolumeMl ?? 0,
        dietStyle: profile?.dietStyle ?? 'omnivore',
        restrictions: profile?.restrictions ?? const {},
        dietaryNotes: profile?.dietaryNotes ?? '',
        locale: locale,
        loggedAt: meal.createdAt,
        requestFollowUps: mealsForTotal.length % 3 == 0,
        weightTrend: notableTrend,
      );
      final coachAt = meal.createdAt.add(const Duration(minutes: 1));
      await threadRepo.add(ThreadItem.coachResponse(
        mealId: meal.id,
        text: response.trim(),
        at: coachAt,
      ));
      analytics.capture('coach_reply',
          properties: {'kind': 'per_meal', 'ok': true});
    } catch (e, stack) {
      debugPrint('Coach call failed for meal ${meal.id}: $e\n$stack');
      final message = e is CoachApiException
          ? e.userMessage
          : 'Coach reply unavailable. Try again later.';
      final coachAt = meal.createdAt.add(const Duration(minutes: 1));
      await threadRepo.add(ThreadItem.coachResponse(
        mealId: meal.id,
        text: message,
        at: coachAt,
      ));
      analytics.capture('coach_reply',
          properties: {'kind': 'per_meal', 'ok': false});
    } finally {
      final next = Set<String>.from(state)..remove(meal.id);
      state = next;
    }
  }
}

final coachSessionProvider =
    StateNotifierProvider<CoachSessionManager, Set<String>>(
  (ref) => CoachSessionManager(ref),
);
