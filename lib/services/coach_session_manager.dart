import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/meal_entry.dart';
import '../models/thread_item.dart';
import '../providers/meal_providers.dart';
import '../utils/weight_trend.dart';
import 'claude_client.dart';

// Bundles rapid-fire meal logs (typically barcode sessions or item-by-item
// text entries) into a single coach call. Without bundling, three scans in a
// row produce three coach bubbles for what was conceptually one meal, plus
// three Anthropic calls.
//
// State transitions:
//   idle (state == null)
//     ──submitMeal──> bundling(1 item, timer 45s)
//   bundling(N, timer)
//     ──submitMeal within 45s──> bundling(N+1, timer reset to 45s)
//     ──timer fires──> calling(N items) → API call → idle (coach reply added)
//
// If the app is killed while bundling, the timer is cancelled and the bundle
// is lost — acceptable for v1: the meals themselves are already persisted,
// only the coach reply is missing and the user can ask in chat instead.

enum SessionPhase { bundling, calling }

@immutable
class CoachSession {
  final List<MealEntry> items;
  final SessionPhase phase;
  // Timestamp of the most recent meal in the bundle. Used by the diary to
  // position the thinking bubble directly after that meal in the thread.
  final DateTime lastMealAt;

  const CoachSession({
    required this.items,
    required this.phase,
    required this.lastMealAt,
  });

  CoachSession copyWith({
    List<MealEntry>? items,
    SessionPhase? phase,
    DateTime? lastMealAt,
  }) =>
      CoachSession(
        items: items ?? this.items,
        phase: phase ?? this.phase,
        lastMealAt: lastMealAt ?? this.lastMealAt,
      );
}

class CoachSessionManager extends StateNotifier<CoachSession?> {
  CoachSessionManager(this._ref) : super(null);

  final Ref _ref;
  Timer? _timer;
  String _locale = 'en';
  // Tuned down from 45s after live testing — the longer window made the
  // solo-log case feel sluggish without meaningfully improving bundling
  // success (typical barcode-scan sequences finish well within 25s).
  static const _debounceSeconds = 25;

  // Called by ConfirmScreen after a NEW meal is persisted. Edits bypass this
  // path and regenerate their coach reply directly — the bundle concept only
  // applies to "I'm eating right now" sessions.
  void submitMeal(MealEntry meal, String locale) {
    _locale = locale;
    final current = state;
    if (current == null) {
      state = CoachSession(
        items: [meal],
        phase: SessionPhase.bundling,
        lastMealAt: meal.createdAt,
      );
    } else {
      state = current.copyWith(
        items: [...current.items, meal],
        lastMealAt: meal.createdAt,
      );
    }
    _resetTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: _debounceSeconds), _fireNow);
  }

  // Public escape hatch — user taps the thinking bubble to say "I'm done
  // logging, send the coach reply now". No-op while a call is already in
  // flight or when nothing is bundling.
  void fireNow() {
    final current = state;
    if (current == null || current.phase == SessionPhase.calling) return;
    _timer?.cancel();
    unawaited(_fireNow());
  }

  Future<void> _fireNow() async {
    final current = state;
    if (current == null) return;
    state = current.copyWith(phase: SessionPhase.calling);

    final threadRepo = _ref.read(threadRepositoryProvider);
    final client = _ref.read(claudeClientProvider);
    final target = _ref.read(calorieTargetProvider);
    final byDay = _ref.read(mealsByDayProvider);
    final profile = _ref.read(userProfileProvider).valueOrNull;
    final trend = _ref.read(weightTrendProvider);
    final analytics = _ref.read(analyticsServiceProvider);

    final items = current.items;
    final isDe = _locale.toLowerCase().startsWith('de');
    final notableTrend = (trend != null && trend.isNotable)
        ? formatWeightTrendForCoach(trend, isDe: isDe)
        : null;

    // Bundle the items into a single coach call. The existing per-meal prompt
    // already handles multi-component descriptions naturally (it's the same
    // shape parseMeal produces from a photo of a multi-item plate), so no
    // change to claude_client.dart is needed.
    final combinedRawText = items
        .map((m) => m.rawText)
        .where((s) => s.isNotEmpty)
        .join(', ');
    final combinedSummary = items.map((m) => m.summary).join(', ');
    final sumKcal = items.fold<int>(0, (s, m) => s + m.kcal);
    final sumProtein = items.fold<double>(0, (s, m) => s + m.proteinG);
    final sumCarbs = items.fold<double>(0, (s, m) => s + m.carbsG);
    final sumFat = items.fold<double>(0, (s, m) => s + m.fatG);
    final unionWarnings =
        items.expand((m) => m.safetyWarnings).toSet().toList();

    // Day totals anchored to the most recent meal's day, so a retro-logged
    // past-day meal counts against that day rather than today.
    final last = items.last;
    final mealDayKey =
        DateTime(last.createdAt.year, last.createdAt.month, last.createdAt.day);
    final sameDay = byDay[mealDayKey] ?? const <MealEntry>[];
    final extras = items
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
        locale: _locale,
        loggedAt: last.createdAt,
        // Same cadence rule as the un-bundled path: every 3rd logged meal of
        // the day surfaces follow-up chips. Counts the total in the day, not
        // the bundle, so the cadence stays user-facing-consistent.
        requestFollowUps: mealsForTotal.length % 3 == 0,
        weightTrend: notableTrend,
      );
      // Link the coach reply to the last meal in the bundle so deleting that
      // meal also clears the reply (no orphaned advice). Anchor +1 min after
      // the meal so chronological sort places it right after.
      final coachAt = last.createdAt.add(const Duration(minutes: 1));
      await threadRepo.add(ThreadItem.coachResponse(
        mealId: last.id,
        text: response.trim(),
        at: coachAt,
      ));
      analytics.capture('coach_reply',
          properties: {'kind': 'per_meal', 'ok': true});
      analytics.capture('coach_session_fired', properties: {
        'item_count': items.length,
      });
      // One-shot educational toast the first time bundling actually
      // happens. Teaches the concept in the moment it occurs, more
      // memorable than a tip card seen in isolation.
      if (items.length > 1) {
        final settings = _ref.read(settingsRepositoryProvider);
        if (!settings.hasSeenBundlingToast()) {
          await settings.setBundlingToastSeen();
          final messenger = rootScaffoldMessengerKey.currentState;
          final messengerCtx = rootScaffoldMessengerKey.currentContext;
          if (messenger != null && messengerCtx != null) {
            // Global-key context: safe to read sync after the await because
            // the linter rule targets per-State contexts that can be disposed.
            // ignore: use_build_context_synchronously
            final l10n = AppLocalizations.of(messengerCtx);
            messenger.showSnackBar(SnackBar(
              content: Text(l10n.bundlingToast),
              duration: const Duration(seconds: 7),
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
      }
    } catch (e, stack) {
      debugPrint('Coach session call failed: $e\n$stack');
      final message = e is CoachApiException
          ? e.userMessage
          : 'Coach reply unavailable. Try again later.';
      final coachAt = last.createdAt.add(const Duration(minutes: 1));
      await threadRepo.add(ThreadItem.coachResponse(
        mealId: last.id,
        text: message,
        at: coachAt,
      ));
      analytics.capture('coach_reply',
          properties: {'kind': 'per_meal', 'ok': false});
    } finally {
      state = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final coachSessionProvider =
    StateNotifierProvider<CoachSessionManager, CoachSession?>(
  (ref) => CoachSessionManager(ref),
);
