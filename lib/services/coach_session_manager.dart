import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal_entry.dart';
import '../models/thread_item.dart';
import '../providers/meal_providers.dart';
import '../utils/weight_trend.dart';
import 'claude_client.dart';

// Tracks which meal IDs currently have a coach call in flight. Most calls
// are single-meal (text, photo, single barcode), but the barcode flow can
// hand in a bundle when the user chained several scans via "+ Noch einen
// scannen" and only finally tapped Speichern. In a bundle, only the LAST
// meal's ID lands in the in-flight set — the thinking bubble appears
// inline after that meal and represents the whole bundle's call.
class CoachSessionManager extends StateNotifier<Set<String>> {
  CoachSessionManager(this._ref) : super(const {});

  final Ref _ref;

  // Single-meal convenience wrapper. Used by text + photo + standalone
  // barcode saves where there's nothing to bundle.
  void submitMeal(MealEntry meal, String locale) {
    submitMeals([meal], locale);
  }

  // Bundle entry point. Used by the barcode flow when the user chained
  // multiple scans into one meal-session.
  void submitMeals(List<MealEntry> meals, String locale) {
    if (meals.isEmpty) return;
    state = {...state, meals.last.id};
    unawaited(_runCallFor(meals, locale));
  }

  // Edit-path entry point. Regenerates the per-meal coach reply for one
  // already-logged meal whose values just changed. Routes through the
  // same in-flight / thinking-bubble mechanism as live saves so the user
  // sees the in-thread bubble next to the meal instead of a detached
  // banner above the input. Caller is responsible for removing the old
  // coach response from the thread before invoking this (so a brief
  // moment of "no bubble + thinking-bubble" is the only visible flicker).
  void regenerateForMeal(
      MealEntry meal, String locale, String fallbackMessage) {
    state = {...state, meal.id};
    unawaited(_runCallFor(
      [meal],
      locale,
      requestFollowUps: false,
      fallbackMessage: fallbackMessage,
    ));
  }

  Future<void> _runCallFor(
    List<MealEntry> meals,
    String locale, {
    // Override for the follow-up-chips heuristic. Live saves let the
    // every-3rd-meal rule decide; edits force false because edits reuse
    // the existing conversation rhythm and shouldn't surface new chips.
    bool? requestFollowUps,
    // Optional caller-supplied (typically localized) fallback when the
    // coach call fails. Defaults to the legacy English string.
    String? fallbackMessage,
  }) async {
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

    final last = meals.last;
    // Combined fields for the bundled call. For a single meal the
    // joins/folds collapse to that meal's own values.
    final combinedRawText = meals
        .map((m) => m.rawText)
        .where((s) => s.isNotEmpty)
        .join(', ');
    final combinedSummary = meals.map((m) => m.summary).join(', ');
    final sumKcal = meals.fold<int>(0, (s, m) => s + m.kcal);
    final sumProtein = meals.fold<double>(0, (s, m) => s + m.proteinG);
    final sumCarbs = meals.fold<double>(0, (s, m) => s + m.carbsG);
    final sumFat = meals.fold<double>(0, (s, m) => s + m.fatG);
    final unionWarnings =
        meals.expand((m) => m.safetyWarnings).toSet().toList();

    // Day totals anchored to the most recent meal's day so retro-logged
    // past-day meals still reason against that day's running total.
    final mealDayKey =
        DateTime(last.createdAt.year, last.createdAt.month, last.createdAt.day);
    final sameDay = byDay[mealDayKey] ?? const <MealEntry>[];
    final extras = meals
        .where((m) => !sameDay.any((s) => s.id == m.id))
        .toList(growable: false);
    final mealsForTotal = [...sameDay, ...extras];
    final totalKcal = mealsForTotal.fold<int>(0, (s, m) => s + m.kcal);
    final totalProtein =
        mealsForTotal.fold<double>(0, (s, m) => s + m.proteinG);

    final proteinTargetG =
        profile != null ? (profile.weightKg * 1.2).round() : 80;

    try {
      final response = await client.generatePerMealResponse(
        mealRawText: combinedRawText,
        mealSummary: combinedSummary,
        mealKcal: sumKcal,
        mealProteinG: sumProtein,
        mealCarbsG: sumCarbs,
        mealFatG: sumFat,
        safetyWarnings: unionWarnings,
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
        loggedAt: last.createdAt,
        requestFollowUps:
            requestFollowUps ?? mealsForTotal.length % 3 == 0,
        weightTrend: notableTrend,
      );
      final coachAt = last.createdAt.add(const Duration(minutes: 1));
      await threadRepo.add(ThreadItem.coachResponse(
        mealId: last.id,
        text: response.trim(),
        at: coachAt,
      ));
      analytics.capture('coach_reply',
          properties: {'kind': 'per_meal', 'ok': true});
      if (meals.length > 1) {
        analytics.capture('coach_session_fired',
            properties: {'item_count': meals.length});
      }
    } catch (e, stack) {
      debugPrint('Coach call failed for ${meals.length} meal(s): $e\n$stack');
      final message = e is CoachApiException
          ? e.userMessage
          : (fallbackMessage ?? 'Coach reply unavailable. Try again later.');
      final coachAt = last.createdAt.add(const Duration(minutes: 1));
      await threadRepo.add(ThreadItem.coachResponse(
        mealId: last.id,
        text: message,
        at: coachAt,
      ));
      analytics.capture('coach_reply',
          properties: {'kind': 'per_meal', 'ok': false});
    } finally {
      final next = Set<String>.from(state)..remove(last.id);
      state = next;
    }
  }
}

final coachSessionProvider =
    StateNotifierProvider<CoachSessionManager, Set<String>>(
  (ref) => CoachSessionManager(ref),
);
