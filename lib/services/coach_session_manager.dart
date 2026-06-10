import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal_entry.dart';
import '../models/thread_item.dart';
import '../models/user_profile_settings.dart';
import '../providers/meal_providers.dart';
import '../utils/weight_trend.dart';
import 'calorie_target.dart';
import 'claude_client.dart';
import 'coach_meal_bundle.dart';
import 'micronutrient_targets.dart';

// Tracks which meal IDs currently have a coach call in flight. Most calls
// are single-meal (text, photo, single barcode), but the barcode flow can
// hand in a bundle when the user chained several scans via "+ Noch einen
// scannen" and only finally tapped Speichern. In a bundle, only the LAST
// meal's ID lands in the in-flight set - the thinking bubble appears
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

  // The coach reply must live on the SAME calendar day as its meal. It is
  // stored under a date-only key (ThreadRepository._keyFor) and the thread
  // re-anchors it directly beneath its meal at sort time. A naive +1min tips
  // a late-night meal (e.g. logged at 23:59) into the next day, where its
  // meal isn't found - so the reply sorts to the very top of tomorrow's
  // thread instead of under its meal. Clamp the +1min nudge to end-of-day so
  // it can never cross midnight.
  // Builds the "low micro" nudge line for the per-meal coach call. Only
  // fires when (a) it's at least 14:00 local on the meal's day, and (b) at
  // least one active micronutrient is under 70% of its day target. Returns
  // null otherwise - the coach prompt suppresses micro talk without a
  // nudge so we don't get noise on every breakfast.
  //
  // "Active" follows the same source the header uses: user-picked list
  // first, phase/diet default second.
  static String? _microNudgeFor(
    UserProfileSettings profile,
    List<MealEntry> mealsForTotal,
    MealEntry last, {
    required bool isDe,
  }) {
    if (last.createdAt.hour < 14) return null;
    final keys = profile.selectedMicronutrients ??
        MicronutrientDefaults.forProfile(profile);
    if (keys.isEmpty) return null;
    final lowParts = <String>[];
    for (final key in keys) {
      final target = MicronutrientTargets.forKey(key, profile);
      final display = MicronutrientDisplay.forKey(key);
      if (target == null || display == null || target.value <= 0) continue;
      final intake = dailyIntakeFor(key, mealsForTotal, profile);
      final pct = (intake / target.value * 100).round();
      if (pct < 70) {
        final name =
            isDe ? display.shortNameDe : display.shortNameEn;
        lowParts.add(
            '$name $pct% (${_fmtVal(intake)}/${_fmtVal(target.value)} ${target.unitLabel})');
      }
    }
    if (lowParts.isEmpty) return null;
    if (isDe) {
      return 'Mikronährstoff-Lücke heute (nach 14 Uhr): ${lowParts.join(", ")}. '
          'Falls die aktuelle Mahlzeit dazu passt, erwähne ein konkretes Lebensmittel für die nächste Mahlzeit; sonst kein Hinweis.';
    }
    return 'Micronutrient gap today (after 2pm): ${lowParts.join(", ")}. '
        'If the current meal fits, name one specific food for the next meal; otherwise skip it.';
  }

  // Returns the validated body-composition guardrail block to attach to
  // the per-meal prompt, or null when guardrails should NOT fire:
  //   - goal == nutrients (user didn't opt in)
  //   - pregnancy (no deficit recommendation in pregnancy at all, per
  //     zahlen_review Vorab-Unterscheidung)
  //   - lactating but <6 weeks postpartum (need to recover + establish
  //     supply before any deficit talk)
  //   - phase is neither pregnant nor lactating (post-weaning is fine,
  //     full guardrail block still applies)
  //
  // All numeric values are the fachlich bestätigten 2026-06-09 figures.
  static String? _goalGuardrailsFor(
    UserProfileSettings profile, {
    required bool isDe,
  }) {
    if (profile.goal == CoachGoal.nutrients) return null;
    if (profile.isPregnant) return null;
    final isLactating = profile.numChildrenNursing > 0;
    // Neither pregnant nor lactating: deficit talk is unrestricted ("Stillzeit
    // und danach" - the "danach" case is free of supply guardrails). Skip the
    // lactation-specific block so the coach doesn't talk about milk to
    // someone who has weaned.
    if (!isLactating) return null;
    if (profile.youngestChildBirthdate != null) {
      final daysPostpartum =
          DateTime.now().difference(profile.youngestChildBirthdate!).inDays;
      if (daysPostpartum < 42) return null; // <6 weeks
    }
    if (isDe) {
      return 'Ziel der Nutzerin: ${profile.goal}. '
          'Bei Körperkomposition/Gewicht:\n'
          '- nur MODERATER Kalorienrahmen.\n'
          '- Stillzeit: nie unter 1800 kcal/Tag, Defizit max. ~300-500 kcal '
          '(stärkere Defizite können die Milchproduktion beeinträchtigen).\n'
          '- Frühestens 6-8 Wochen postpartum aktiv Defizit, vorher nur '
          'Erholung und Milchaufbau.\n'
          '- Protein und Mikronährstoffe (Eisen, Calcium, Jod, DHA) immer '
          'auf Soll halten, auch im Defizit.\n'
          '- An Sport-Tagen Protein erhöhen statt Defizit vergrößern.\n'
          '- Einmal kurz auf Absprache mit Hebamme/Ärztin hinweisen.';
    }
    return 'User goal: ${profile.goal}. '
        'For body composition / weight:\n'
        '- only a MODERATE calorie frame.\n'
        '- Lactation: never below 1800 kcal/day, deficit max ~300-500 kcal '
        '(larger deficits can affect milk supply).\n'
        '- Active deficit only from 6-8 weeks postpartum onward; before '
        'that, focus on recovery and establishing milk supply.\n'
        '- Keep protein and micronutrients (iron, calcium, iodine, DHA) '
        'on target even during a deficit.\n'
        '- On workout days raise protein instead of widening the deficit.\n'
        '- Once, briefly note to coordinate with midwife/doctor.';
  }

  static String _fmtVal(double v) {
    if (v >= 50) return v.round().toString();
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  static DateTime coachAnchorFor(DateTime mealAt) {
    final plusOne = mealAt.add(const Duration(minutes: 1));
    final endOfDay =
        DateTime(mealAt.year, mealAt.month, mealAt.day, 23, 59, 59, 999);
    return plusOne.isAfter(endOfDay) ? endOfDay : plusOne;
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
    // Bundle + day totals via the pure helpers in coach_meal_bundle.dart so
    // the joining / summing / safety-warning-dedupe / stream-race-defensive
    // day merge can be unit-tested without this whole async stack.
    final bundle = combineMealsForCoach(meals);
    final totals = dayTotalsForCoach(byDay: byDay, bundle: meals);
    // mealsForTotal is still needed downstream for the micro-nudge call,
    // which inspects each meal's per-meal micronutrient estimate. Same
    // shape as inside dayTotalsForCoach.
    final mealDayKey =
        DateTime(last.createdAt.year, last.createdAt.month, last.createdAt.day);
    final sameDay = byDay[mealDayKey] ?? const <MealEntry>[];
    final extras = meals
        .where((m) => !sameDay.any((s) => s.id == m.id))
        .toList(growable: false);
    final mealsForTotal = [...sameDay, ...extras];

    // Single source of truth (calorie_target.dart): DGE g/kg for the phase +
    // goal on the BMI-25-capped reference weight. Replaces the old naive
    // weight × 1.2, which ignored the cap and the phase and over-targeted
    // protein for overweight users.
    final proteinTargetG = profile != null ? proteinTargetGrams(profile) : 80;

    // Build the optional micronutrient-nudge for the coach: list active
    // micros that are still under 70% of target AFTER 14:00 local time of
    // the meal. Empty list (or before 14:00) → no nudge field is sent, and
    // the coach won't mention micros proactively.
    final microNudge = profile != null
        ? _microNudgeFor(profile, mealsForTotal, last, isDe: isDe)
        : null;

    // "What do you want to use up today?" - coach asks at most once a day,
    // and skips the ask entirely when ingredients are already stored. The
    // ask flips on only for live saves (not for edit-regenerates) so the
    // regen path doesn't double-prompt.
    final settingsRepo = _ref.read(settingsRepositoryProvider);
    final ingredients = settingsRepo.getCoachTodaysIngredients();
    final askedToday = settingsRepo.wasCoachAskedToday();
    final askForIngredients = requestFollowUps != false &&
        !askedToday &&
        ingredients == null;

    // Body-composition guardrails from the briefing
    // coach_zutaten_ziel_logik (Abschnitt 3) + zahlen_review (all 7 values
    // confirmed 2026-06-09). Only attached when the user opted into the
    // body or both goal AND it is actually safe in the current phase.
    final goalGuardrails =
        profile != null ? _goalGuardrailsFor(profile, isDe: isDe) : null;

    try {
      final response = await client.generatePerMealResponse(
        mealRawText: bundle.rawText,
        mealSummary: bundle.summary,
        mealKcal: bundle.kcal,
        mealProteinG: bundle.proteinG,
        mealCarbsG: bundle.carbsG,
        mealFatG: bundle.fatG,
        safetyWarnings: bundle.safetyWarnings,
        totalKcalToday: totals.kcal,
        targetKcal: target,
        totalProteinToday: totals.proteinG,
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
        microNudge: microNudge,
        ingredients: ingredients,
        askForIngredients: askForIngredients,
        goalGuardrails: goalGuardrails,
      );
      final coachAt = coachAnchorFor(last.createdAt);
      // Safety net for the em-dash habit: even with the explicit prompt
      // instruction, the model still sneaks them in sometimes. Replace
      // before persisting so they never make it to the diary.
      final cleaned = response.trim().replaceAll('—', '-');
      await threadRepo.add(ThreadItem.coachResponse(
        mealId: last.id,
        text: cleaned,
        at: coachAt,
      ));
      analytics.capture('coach_reply',
          properties: {'kind': 'per_meal', 'ok': true});
      if (meals.length > 1) {
        analytics.capture('coach_session_fired',
            properties: {'item_count': meals.length});
      }
      // The "anything to use up?" question counts as asked even if the
      // user doesn't answer in this turn - prevents nagging. Anchor the
      // ask to this meal's id so the diary can render the reply input
      // right under THIS coach bubble (not under every later one too).
      if (askForIngredients) {
        await settingsRepo.markCoachAskedToday();
        await settingsRepo.setCoachLastAskedAtMealId(last.id);
        _ref.read(coachAskStateProvider.notifier).reload();
      }
    } catch (e, stack) {
      debugPrint('Coach call failed for ${meals.length} meal(s): $e\n$stack');
      final message = e is CoachApiException
          ? e.userMessage
          : (fallbackMessage ?? 'Coach reply unavailable. Try again later.');
      final coachAt = coachAnchorFor(last.createdAt);
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
