import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../main.dart'
    show rootScaffoldMessengerKey, snackbarDismissOnNavObserver;

import '../models/favorite_meal.dart';
import '../models/meal_entry.dart';
import '../models/meal_entry_source.dart';
import '../models/thread_item.dart';
import '../providers/meal_providers.dart';
import '../providers/ui_providers.dart';
import '../services/claude_client.dart';
import '../services/safety_rules.dart';
import '../utils/important_snack.dart';
import '../services/coach_session_manager.dart';
import '../services/notification_scheduler.dart';
import '../widgets/edit_hint_icon.dart';

// Payload the sheet pops with in editOnly mode (#112). Carries the user-
// edited parse result + meal-time without touching the meal repo. Callers
// (e.g. MultiPhotoReviewScreen) collect drafts in memory and persist them
// on their own "Save all" action.
class ConfirmScreenDraft {
  final MealParseResult parsed;
  final DateTime mealTime;
  const ConfirmScreenDraft({required this.parsed, required this.mealTime});
}

class ConfirmScreen extends ConsumerStatefulWidget {
  final String rawText;
  final MealParseResult parsed;
  final Uint8List? imageBytes;
  final String? existingMealId;
  final DateTime? existingCreatedAt;
  // Soft default for fresh saves (Task #98 - typically the photo's EXIF
  // DateTimeOriginal). Only consulted when existingCreatedAt is null
  // (i.e. NOT an edit) and the focused diary day matches the suggested
  // timestamp's day. User can still override in the time picker.
  final DateTime? suggestedCreatedAt;
  // Edit-only mode (#112): the save button DOES NOT persist to the meal
  // repo or fire the coach. Instead it pops the sheet with a
  // ConfirmScreenDraft carrying the edited parsed result + meal time.
  // Used by the multi-photo review flow so the user can fine-tune each
  // item before the bulk persist. Hides the favourite toggle and the
  // scan-another button.
  final bool editOnly;
  final bool asSheet;
  // How this entry reached the confirm sheet. The analytics layer reads
  // [source.analyticsLabel] to populate the meal_logged.method dimension
  // that PostHog dashboards already filter on - see MealEntrySource for
  // the wire-format guarantees when adding a new source.
  final MealEntrySource source;
  // When true (used by the barcode flow), the sheet shows a "+ Noch einen
  // scannen" secondary button. Tapping it pops the sheet with the value
  // true so the caller can chain another scan; tapping the regular
  // Speichern pops with null. Both paths persist this meal first.
  final bool allowScanAnother;

  const ConfirmScreen({
    super.key,
    required this.rawText,
    required this.parsed,
    this.imageBytes,
    this.existingMealId,
    this.existingCreatedAt,
    this.suggestedCreatedAt,
    this.editOnly = false,
    this.asSheet = false,
    this.source = MealEntrySource.text,
    this.allowScanAnother = false,
  });

  @override
  ConsumerState<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends ConsumerState<ConfirmScreen> {
  late final TextEditingController _summary;
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late final TextEditingController _portion;

  // Numeric baseline used by the portion scaler. Updated when the user
  // re-parses the description (see _reparseFromSummary), so portion changes
  // after a re-parse scale off the new values.
  late int _origKcal;
  late double _origProtein;
  late double _origCarbs;
  late double _origFat;
  late double _origPortion;
  // The current summary text we treat as the "canonical" parse. Used to
  // decide when to show the re-parse affordance. Starts as the value
  // Claude returned, gets bumped after a successful re-parse.
  late String _origSummary;
  // Portion alias is free text Claude returns ("1 mittlere Schüssel") that
  // can't be scaled arithmetically, so we hide it once the user changes the
  // amount and restore it if they return to the parsed value. _origAlias is
  // the alias for _origPortion; _currentAlias is what we display/save now.
  late String? _origAlias;
  String? _currentAlias;
  // Mutable copy of the parsed safety warnings. _reparseFromSummary
  // overwrites this with the freshly parsed list - otherwise a stale
  // alcohol warning persists when the user edits the description from
  // "Glas Wein und Brot" to "Kaffee und Brot" (Build +34 tester report).
  late List<String> _currentSafetyWarnings;
  // Mirror for the parsed micronutrients map (re-parse must replace the
  // stale numbers too, otherwise the "Auch erkannt" hint card and the
  // persisted MealEntry.micronutrients keep the old reading).
  Map<String, double>? _currentMicronutrients;
  bool _scaling = false;
  bool _saveAsFavorite = false;
  // When this meal is logged. Defaults to the existing time (edit / past-day)
  // or now (fresh entry). Editable here via a time chip, which replaces the
  // old time-override that cluttered the home input row.
  late DateTime _mealTime;
  // Makros (P/KH/F) are hidden by default; user taps Details to reveal them.
  bool _showDetails = false;
  bool _userTouched = false; // set when the user edits any field
  bool _reparsing = false; // true while a re-parse Claude call is in flight

  @override
  void initState() {
    super.initState();
    _origKcal = widget.parsed.kcal;
    _origProtein = widget.parsed.proteinG;
    _origCarbs = widget.parsed.carbsG;
    _origFat = widget.parsed.fatG;
    _origPortion = widget.parsed.portionAmount;
    _origSummary = widget.parsed.summary;
    _origAlias = widget.parsed.portionAlias;
    _currentAlias = _origAlias;
    _currentSafetyWarnings = List<String>.from(widget.parsed.safetyWarnings);
    _currentMicronutrients = widget.parsed.micronutrients == null
        ? null
        : Map<String, double>.from(widget.parsed.micronutrients!);
    // Default date+time: edits keep the meal's original timestamp.
    // Fresh saves anchor to the day the user is CURRENTLY viewing in
    // the diary - that's what they expect when they tap "log" on a
    // past day. Time defaults to wall-clock "now" for today (so the
    // entry lands at the end of the running day) and to noon for past
    // days (no implicit "now" makes sense on a day that's already over,
    // and noon is a neutral middle-of-day anchor). The session-memory
    // hack that carried the last-picked day across sheets was dropped
    // here - it confused the standard case (one entry on today after
    // one retro-entry would silently default to yesterday again).
    final nowInit = DateTime.now();
    final today = DateTime(nowInit.year, nowInit.month, nowInit.day);
    final focused = ref.read(focusedDayProvider);
    if (widget.existingCreatedAt != null) {
      _mealTime = widget.existingCreatedAt!;
    } else if (widget.suggestedCreatedAt != null) {
      // Photo EXIF timestamp from #98. Trust the EXIF as authoritative -
      // if the photo was taken yesterday the meal IS from yesterday, even
      // if the user is currently viewing today. The downstream save path
      // detects that mealDay != today and switches the diary to the meal's
      // day (so the user lands on the entry they just added). User can
      // still edit the time before saving.
      _mealTime = widget.suggestedCreatedAt!;
    } else if (_sameDay(focused, today)) {
      _mealTime = nowInit;
    } else {
      _mealTime = DateTime(focused.year, focused.month, focused.day, 12, 0);
    }

    _summary = TextEditingController(text: widget.parsed.summary);
    _kcal = TextEditingController(text: _origKcal.toString());
    _protein = TextEditingController(text: _origProtein.toStringAsFixed(1));
    _carbs = TextEditingController(text: _origCarbs.toStringAsFixed(1));
    _fat = TextEditingController(text: _origFat.toStringAsFixed(1));
    _portion = TextEditingController(
        text: _origPortion > 0 ? _origPortion.toStringAsFixed(0) : '');
    _portion.addListener(_onPortionChanged);
    // Re-parse button visibility flips when the summary diverges from the
    // last parsed value, so rebuild on every keystroke in that field.
    _summary.addListener(() => setState(() {}));
    // Track any change so back-navigation can warn about unsaved edits.
    for (final c in [_summary, _kcal, _protein, _carbs, _fat, _portion]) {
      c.addListener(() {
        if (!_userTouched) _userTouched = true;
      });
    }
  }

  // Calls Claude with the (edited) summary text and replaces the numeric
  // fields with the fresh estimate. Triggered by the "re-estimate" button
  // next to the description field, which only appears when the user has
  // changed the text from what Claude originally returned.
  Future<void> _reparseFromSummary() async {
    final newText = _summary.text.trim();
    if (newText.isEmpty || newText == _origSummary || _reparsing) return;
    setState(() => _reparsing = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      // Edit-and-reparse is the user's correction loop: she fixes a wrong
      // summary, the parser should see her prior loggings of that summary
      // (top 3 substring matches from the last 30 days) and anchor on
      // those values instead of re-estimating from scratch.
      final historyHints =
          ref.read(mealHistorySuggestionsProvider(newText));
      final parsed = await ref.read(claudeClientProvider).parseMeal(
            newText,
            locale: Localizations.localeOf(context).languageCode,
            isPregnant: profile?.isPregnant ?? false,
            trimester: profile?.trimester,
            isLactating: (profile?.numChildrenNursing ?? 0) > 0,
            brandHistoryHints: historyHints,
          );
      if (!mounted) return;
      if (!parsed.isMeal) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(parsed.rejectionReason ??
                AppLocalizations.of(context).commonGenericError),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
      setState(() {
        _origKcal = parsed.kcal;
        _origProtein = parsed.proteinG;
        _origCarbs = parsed.carbsG;
        _origFat = parsed.fatG;
        _origPortion = parsed.portionAmount;
        _origSummary = parsed.summary;
        _origAlias = parsed.portionAlias;
        _currentAlias = parsed.portionAlias;
        // Build +34 fix: also replace warnings + micros so a stale
        // alcohol/quecksilber warning from the previous parse doesn't
        // ride along with a now-harmless description.
        _currentSafetyWarnings = List<String>.from(parsed.safetyWarnings);
        _currentMicronutrients = parsed.micronutrients == null
            ? null
            : Map<String, double>.from(parsed.micronutrients!);
        _summary.text = parsed.summary;
        _kcal.text = parsed.kcal.toString();
        _protein.text = parsed.proteinG.toStringAsFixed(1);
        _carbs.text = parsed.carbsG.toStringAsFixed(1);
        _fat.text = parsed.fatG.toStringAsFixed(1);
        _portion.text = parsed.portionAmount > 0
            ? parsed.portionAmount.toStringAsFixed(0)
            : '';
      });
    } on CoachApiException catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.userMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).commonGenericError),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _reparsing = false);
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_userTouched) return true;
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDiscardTitle),
        content: Text(l10n.confirmDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.confirmDiscardAbort),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.confirmDiscardConfirm),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  void dispose() {
    _summary.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _portion.dispose();
    super.dispose();
  }

  double _parseDouble(String s, double fallback) =>
      double.tryParse(s.replaceAll(',', '.')) ?? fallback;

  void _onPortionChanged() {
    if (_scaling || _origPortion <= 0) return;
    final newPortion = _parseDouble(_portion.text, 0);
    if (newPortion <= 0) return;
    final scale = newPortion / _origPortion;
    _scaling = true;
    _kcal.text = (_origKcal * scale).round().toString();
    _protein.text = (_origProtein * scale).toStringAsFixed(1);
    _carbs.text = (_origCarbs * scale).toStringAsFixed(1);
    _fat.text = (_origFat * scale).toStringAsFixed(1);
    _scaling = false;
    // The alias is free text that can't be scaled arithmetically, and a stale
    // reference misleads about magnitude. So hide it once the amount diverges
    // from the parsed value, and restore it if the amount returns.
    final alias = (newPortion - _origPortion).abs() < 0.5 ? _origAlias : null;
    if (alias != _currentAlias) {
      setState(() => _currentAlias = alias);
    }
  }

  // [fireCoach] false defers the coach call to the next save in the same
  // scan-session: the meal lands in the diary + the pending bundle, but no
  // coach call goes out. The eventual "Speichern" tap drains the bundle
  // and fires one call for all of them.
  // [popValue] lets the caller signal something back to the modal-sheet
  // host (e.g. `true` means "chain another scan").
  Future<void> _save({bool fireCoach = true, Object? popValue}) async {
    final summary = _summary.text.trim().isEmpty
        ? widget.parsed.summary
        : _summary.text.trim();
    final kcal = int.tryParse(_kcal.text) ?? widget.parsed.kcal;
    final proteinG = _parseDouble(_protein.text, widget.parsed.proteinG);
    final carbsG = _parseDouble(_carbs.text, widget.parsed.carbsG);
    final fatG = _parseDouble(_fat.text, widget.parsed.fatG);
    final portion = _parseDouble(_portion.text, widget.parsed.portionAmount);

    // Edit-only mode (#112): build the draft from the edited fields and
    // pop with it - no Hive write, no analytics fire, no reminder skip,
    // no coach call. Caller (multi-photo review) handles bulk persistence.
    if (widget.editOnly) {
      final draft = ConfirmScreenDraft(
        parsed: MealParseResult(
          isMeal: true,
          rejectionReason: null,
          summary: summary,
          kcal: kcal,
          proteinG: proteinG,
          carbsG: carbsG,
          fatG: fatG,
          portionAmount: portion,
          portionUnit: widget.parsed.portionUnit,
          portionAlias: _currentAlias,
          safetyWarnings: _currentSafetyWarnings,
          micronutrients: _currentMicronutrients,
        ),
        mealTime: _mealTime,
      );
      if (mounted) Navigator.of(context).pop(draft);
      return;
    }

    // Capture context-bound values up front so the post-save reminder skip
    // and other async-after-pop logic can run safely without touching a
    // disposed BuildContext.
    final reminderSettings =
        ref.read(settingsRepositoryProvider).getReminders();
    final reminderL10n = AppLocalizations.of(context);

    final meal = MealEntry(
      id: widget.existingMealId ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: _mealTime,
      rawText: widget.rawText,
      summary: summary,
      kcal: kcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      portionAmount: portion,
      portionUnit: widget.parsed.portionUnit,
      portionAlias: _currentAlias,
      safetyWarnings: _currentSafetyWarnings,
      // Carry the parser's per-meal micronutrient estimates through to
      // storage. The daily-aggregation provider sums these across the
      // day's meals; absent on legacy entries or meals where the parser
      // judged all nutrients negligible.
      micronutrients: _currentMicronutrients,
    );
    await ref.read(mealRepositoryProvider).save(meal);
    final analytics = ref.read(analyticsServiceProvider);
    analytics.capture('meal_logged', properties: {
      'method': widget.source.analyticsLabel,
      'edited': widget.existingMealId != null,
    });
    // Build +35 robustness: recompute the WHOLE today-skip set against
    // every meal currently logged today. The old single-meal skip
    // (skipCoveredReminder) sometimes lost the cancel call when the
    // app was backgrounded mid-save, so the recurring reminder still
    // fired ~1 h after the user logged - tester report. The bulk
    // version converges: even if one save's call drops, the next save
    // catches up.
    final todayMeals = ref.read(todayMealsProvider);
    final todayMealTimes = [
      ...todayMeals.map((m) => m.createdAt),
      meal.createdAt,
    ];
    NotificationScheduler.recomputeSkipsForToday(
      todayMealTimes: todayMealTimes,
      settings: reminderSettings,
      l10n: reminderL10n,
    ).catchError((Object e, StackTrace _) {
      debugPrint('recomputeSkipsForToday failed: $e');
    });
    // Track how often the food-safety feature actually surfaces a warning, so
    // we can tell whether it earns its keep.
    if (meal.safetyWarnings.isNotEmpty) {
      analytics.capture('safety_warning_shown',
          properties: {'count': meal.safetyWarnings.length});
    }

    if (_saveAsFavorite) {
      // Dedupe by trimmed lowercase summary: if a favorite with the same
      // description already exists, update it in place (same ID) instead of
      // creating a duplicate chip.
      final existing = ref.read(favoritesProvider).valueOrNull ?? const [];
      final normalized = summary.trim().toLowerCase();
      final match = existing
          .where((f) => f.summary.trim().toLowerCase() == normalized)
          .toList();
      final favoriteId = match.isNotEmpty
          ? match.first.id
          : 'fav-${DateTime.now().microsecondsSinceEpoch}';
      final favorite = FavoriteMeal(
        id: favoriteId,
        summary: summary,
        kcal: kcal,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        portionAmount: portion,
        portionUnit: widget.parsed.portionUnit,
        safetyWarnings: _currentSafetyWarnings,
        micronutrients: _currentMicronutrients,
      );
      await ref.read(favoriteRepositoryProvider).save(favorite);
    }

    if (!mounted) return;
    // Dismiss keyboard before popping so the next screen doesn't render with
    // half its height eaten by the keyboard.
    FocusScope.of(context).unfocus();
    final navigator = Navigator.of(context);
    final asSheet = widget.asSheet;
    await _appendToThread(meal, fireCoach: fireCoach);
    if (!mounted) return;
    if (asSheet) {
      navigator.pop(popValue ?? meal);
    } else {
      navigator.popUntil((r) => r.isFirst);
    }
  }

  // True if the edited meal differs from the original values (i.e. user
  // actually changed something). Used to skip the Coach regeneration on a
  // no-op edit.
  bool _mealValuesChanged(MealEntry meal) {
    if (widget.existingMealId == null) return true; // new meal, always
    final orig = widget.parsed;
    return meal.summary != orig.summary ||
        meal.kcal != orig.kcal ||
        (meal.proteinG - orig.proteinG).abs() > 0.05 ||
        (meal.carbsG - orig.carbsG).abs() > 0.05 ||
        (meal.fatG - orig.fatG).abs() > 0.05;
  }

  Future<void> _appendToThread(MealEntry meal,
      {bool fireCoach = true}) async {
    final isEdit = widget.existingMealId != null;
    if (isEdit && !_mealValuesChanged(meal)) {
      // No actual changes, keep the existing coach response, don't spend a
      // Claude call on a no-op.
      return;
    }
    final threadRepo = ref.read(threadRepositoryProvider);
    final locale = Localizations.localeOf(context).languageCode;
    // Capture context-bound strings up front so the post-await snack
    // calls don't have to touch a possibly-disposed BuildContext.
    final pastDaySavedToast =
        AppLocalizations.of(context).confirmPastDaySavedToast;
    final coachRetroPausedToast =
        AppLocalizations.of(context).confirmCoachRetroPausedToast;
    final snackDismissLabel = importantSnackLabel(context);

    if (!isEdit) {
      // New meal: persist it so it shows up in the diary right away. The
      // coach call is either fired now (with any pending bundle) or
      // deferred (added to the bundle for the next save to fire).
      await threadRepo.add(
          ThreadItem.meal(mealId: meal.id, at: meal.createdAt));
      final bundleNotifier =
          ref.read(pendingScanBundleProvider.notifier);
      // Retro-logs (any meal whose stored time is more than the
      // CoachSessionManager.retroactiveThreshold in the past) skip the
      // auto coach entirely. Beta feedback (Vanessa 2026-06-16): "for a
      // yesterday entry the coach shouldn't run; the live-coach should
      // only fire for things logged for NOW." The user can still ask the
      // coach proactively via the chat input. Past-day saves get the
      // existing "Logged for [date]" toast; same-day backfills get the
      // new "coach paused" toast.
      final now = DateTime.now();
      final todayKey = DateTime(now.year, now.month, now.day);
      final mealDay = DateTime(
          meal.createdAt.year, meal.createdAt.month, meal.createdAt.day);
      final isPastDaySave = mealDay.isBefore(todayKey);
      final isRetro =
          CoachSessionManager.isRetroactiveMeal(meal.createdAt);
      if (isPastDaySave || isRetro) {
        // Drain any pending bundle without firing - retro-saves
        // shouldn't carry today's queued meals into a coach call later.
        bundleNotifier.state = const [];
        // Tell the global nav observer to skip the next auto-dismiss
        // so the snack survives the pop that follows this save (Build
        // +35 follow-up: the snack used to vanish the moment the
        // confirm sheet popped).
        snackbarDismissOnNavObserver.markPersistent();
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          importantSnack(
            message:
                isPastDaySave ? pastDaySavedToast : coachRetroPausedToast,
            dismissLabel: snackDismissLabel,
          ),
        );
        scheduleImportantSnackForceDismiss();
        // Same-day retro saves stay on the current focusedDay, so the
        // scrollToDayProvider (which switches days) isn't enough. Push
        // the meal-id directly so the diary scrolls to the new entry
        // even though its stored mealTime is in the past. Past-day saves
        // already pick the right meal via scrollToDayProvider's
        // preferred-meal logic below; setting this provider too is
        // belt-and-suspenders in case the day switch is slow.
        ref.read(scrollToMealIdProvider.notifier).state = meal.id;
      } else if (fireCoach) {
        // Drain any in-progress scan bundle and fire one coach call for
        // everything together (or just this meal when no bundle exists).
        final pending = ref.read(pendingScanBundleProvider);
        bundleNotifier.state = const [];
        final all = [...pending, meal];
        ref.read(coachSessionProvider.notifier).submitMeals(all, locale);
        // Push the meal id so the diary scrolls to the new entry even when
        // the user backdated the meal-time (e.g. "logged 20 min ago"). The
        // autoscroll's 60s-recent heuristic uses createdAt, so a back-
        // dated meal would otherwise be skipped and the user sees nothing
        // change. Vanessa Build+28 bug: "Hühnchen 20min zurückgestellt
        // → Mahlzeit wird nicht gezeigt".
        ref.read(scrollToMealIdProvider.notifier).state = meal.id;
      } else {
        // Append to the bundle without firing - used by the barcode
        // "+ Noch einen scannen" path.
        bundleNotifier.state = [...bundleNotifier.state, meal];
      }
      // Day-switch logic: jump the diary to the meal's day whenever the
      // user is currently looking at a different day. Covers:
      //   - User on today saves a past-day meal → switch to past day
      //   - User on past day saves a today meal → switch to today
      //   - User on past day saves the same past day → no switch
      // Without this the meal lands silently in another day-bucket and
      // the user thinks the save was lost. Vanessa Build+28 bug:
      // "auf vergangenen Tag → Eintrag für heute → kein Sprung zu heute".
      final focusedNow = ref.read(focusedDayProvider);
      final focusedKey =
          DateTime(focusedNow.year, focusedNow.month, focusedNow.day);
      if (mealDay != focusedKey) {
        ref.read(scrollToDayProvider.notifier).state = mealDay;
      }
      return;
    }

    // Edit path: route through CoachSessionManager so the thinking bubble
    // appears in-thread next to the meal (same UX as live saves), instead
    // of as a detached banner above the input. Pre-capture the localized
    // fallback message because the modal pops before the manager's async
    // call resolves - touching context after that would throw.
    final fallbackMessage =
        AppLocalizations.of(context).confirmCoachErrorFallback;

    // If the time was edited, move the meal's ThreadItem (and any orphan
    // coach response on the old day) to the new timestamp before the
    // regenerate step. Without this the entry visually stays at the old
    // slot - and for cross-day edits in the wrong day bucket entirely.
    final originalAt = widget.existingCreatedAt;
    if (originalAt != null && originalAt != meal.createdAt) {
      await threadRepo.updateMealItemTime(
          meal.id, originalAt, meal.createdAt);
    }
    // The meal item is already in the thread. Remove the old coach response
    // so the manager's regenerate step can add the replacement cleanly.
    // (If updateMealItemTime just migrated it cross-day, this picks up the
    // migrated copy and removes it.)
    await threadRepo.removeCoachResponseForMeal(meal.id, meal.createdAt);

    // Retro edits skip the coach regen too - same reasoning as the
    // fresh-save path. Surface the save via a snack so the user gets a
    // confirmation even without the in-thread thinking bubble.
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    final mealDay = DateTime(
        meal.createdAt.year, meal.createdAt.month, meal.createdAt.day);
    final isPastDayEdit = mealDay.isBefore(todayKey);
    final isRetroEdit =
        CoachSessionManager.isRetroactiveMeal(meal.createdAt);
    if (isPastDayEdit || isRetroEdit) {
      snackbarDismissOnNavObserver.markPersistent();
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        importantSnack(
          message:
              isPastDayEdit ? pastDaySavedToast : coachRetroPausedToast,
          dismissLabel: snackDismissLabel,
        ),
      );
      scheduleImportantSnackForceDismiss();
      return;
    }

    ref
        .read(coachSessionProvider.notifier)
        .regenerateForMeal(meal, locale, fallbackMessage);
  }

  void _discard() {
    FocusScope.of(context).unfocus();
    if (widget.asSheet) {
      Navigator.of(context).pop();
    } else {
      Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  // Phase 6 of the diary refactor: one combined "Heute · 08:24" pill
  // replaces the two separate date + time pills. Tapping it walks the
  // user through a date picker first, then a time picker, in the same
  // gesture - so a retro-add is one tap-and-decide flow instead of two
  // pills the user has to discover are independent. Cancelling either
  // picker keeps _mealTime unchanged.
  Future<void> _pickMealDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _mealTime,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: AppLocalizations.of(context).homeDatePickerHelp,
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_mealTime),
      helpText: AppLocalizations.of(context).homeTimePickerHelp,
    );
    if (pickedTime == null || !mounted) return;
    setState(() {
      _mealTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute);
      _userTouched = true;
    });
  }

  String _formatMealTime() {
    final hh = _mealTime.hour.toString().padLeft(2, '0');
    final mm = _mealTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // Compact day label for the combined pill. "Heute" / "Gestern" for
  // the common cases stay readable at a glance; older days fall back
  // to day.month so the pill stays short.
  String _formatMealDate(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mealDay = DateTime(_mealTime.year, _mealTime.month, _mealTime.day);
    final delta = today.difference(mealDay).inDays;
    final l10n = AppLocalizations.of(context);
    if (delta == 0) return l10n.todayHeader;
    if (delta == 1) return l10n.yesterdayHeader;
    return '${_mealTime.day}.${_mealTime.month}.';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // True when the meal sits on a day other than today. Drives the
  // amber deviation tint on the combined date-time pill.
  bool get _isDeviationFromToday {
    final now = DateTime.now();
    return !_sameDay(_mealTime, now);
  }

  Widget _buildBody(BuildContext context) {
    final warnings = _currentSafetyWarnings;
    final portionUnit = widget.parsed.portionUnit;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    // Visible to the user mid-scan-session so they understand previous
    // scans haven't been "lost" - they're queued for one combined coach
    // reply. Only relevant on the barcode entry path.
    final pendingBundle = widget.allowScanAnother
        ? ref.watch(pendingScanBundleProvider)
        : const <MealEntry>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      shrinkWrap: widget.asSheet,
      children: [
        if (pendingBundle.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.layers_outlined,
                    size: 18, color: scheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.confirmBundleHint(pendingBundle.length + 1),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.imageBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              widget.imageBytes!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _summary,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                // Wrap long titles (multi-component meals from a photo).
                minLines: 1,
                maxLines: 3,
                // "Done" instead of the default "Return" so dismissing the
                // keyboard is a single tap. Multi-line is preserved for
                // photo-parsed multi-component summaries that wrap.
                textInputAction: TextInputAction.done,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                // Outlined notch-label per beta feedback: the borderless
                // input read as read-only, users didn't realise the meal
                // name was editable. Matches the portion/kcal fields
                // below visually so the whole sheet feels consistently
                // editable.
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.confirmDescriptionHint,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
            // Re-estimate affordance: only shown once the user has edited
            // the description away from the original Claude parse. Tap
            // refreshes kcal / macros / portion to match the new text.
            if (_summary.text.trim() != _origSummary &&
                _summary.text.trim().isNotEmpty) ...[
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _reparsing ? null : _reparseFromSummary,
                icon: _reparsing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: Text(l10n.confirmReparse),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        // Meal date + time: single combined "Heute · 08:24" pill. Tap
        // walks date-picker → time-picker in one gesture; the pill
        // tints amber when the chosen day deviates from today (visual
        // reminder that this entry won't land on today's running
        // total). ThreadRepository.updateMealItemTime handles the
        // cross-day move incl. its coach response when _save commits.
        Align(
          alignment: Alignment.centerLeft,
          child: _DateTimePill(
            icon: Icons.schedule,
            label: '${_formatMealDate(context)} · ${_formatMealTime()}',
            deviation: _isDeviationFromToday,
            onTap: _pickMealDateTime,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          // crossAxisAlignment.start keeps both input boxes at the same Y
          // when only one of them has helper text (the portion alias).
          // Without this, Row.center shifts both boxes off-axis whenever
          // a portion_alias comes back from Claude.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SmallField(
                controller: _portion,
                label: l10n.confirmFieldPortion,
                suffix: portionUnit,
                helper: _currentAlias != null
                    ? l10n.confirmAliasPrefix(_currentAlias!)
                    : null,
                decimal: true,
                onSubmit: _save,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SmallField(
                controller: _kcal,
                label: l10n.trendsLabelKcal,
                suffix: l10n.confirmFieldKcal,
                decimal: false,
                onSubmit: _save,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _showDetails = !_showDetails),
            icon: Icon(
              _showDetails ? Icons.expand_less : Icons.expand_more,
              size: 18,
            ),
            label: Text(_showDetails
                ? l10n.confirmDetailsHide
                : l10n.confirmDetailsToggle),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        if (_showDetails) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _SmallField(
                  controller: _protein,
                  label: l10n.confirmFieldProtein,
                  suffix: 'g',
                  decimal: true,
                  onSubmit: _save,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallField(
                  controller: _carbs,
                  label: l10n.confirmFieldCarbs,
                  suffix: 'g',
                  decimal: true,
                  onSubmit: _save,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallField(
                  controller: _fat,
                  label: l10n.confirmFieldFat,
                  suffix: 'g',
                  decimal: true,
                  onSubmit: _save,
                ),
              ),
            ],
          ),
        ],
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SafetyWarningsBlock(warnings: warnings),
        ],
        // Task B9, Build +34: when the parser surfaces nutrients we don't
        // currently track (magnesium, selenium, ...), tell the user that
        // it WAS detected but isn't part of the daily target yet. The
        // alternative was silent drop, which made the model look careless
        // ("how did it miss the magnesium tablet I logged?").
        Builder(builder: (context) {
          final unsupported =
              _unsupportedNutrientLabels(_currentMicronutrients, l10n);
          if (unsupported.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _UnsupportedNutrientNote(labels: unsupported),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  // Returns the user-visible labels (German or English depending on the
  // current l10n) for nutrient keys the parser sent through but which
  // [MicronutrientKey.all] does not yet track. The keys arrive already
  // canonicalized (see MealParseResult.canonicalNutrientKey), so D3 /
  // cholecalciferol have been merged into vitamin_d_ug before we get here
  // and won't show up as "unsupported".
  List<String> _unsupportedNutrientLabels(
      Map<String, double>? micros, AppLocalizations l10n) {
    if (micros == null || micros.isEmpty) return const [];
    final supported = MicronutrientKey.all.toSet();
    final extras = <String>[];
    for (final entry in micros.entries) {
      if (supported.contains(entry.key)) continue;
      // Belt + braces against the protein-leak bug a tester hit: macro
      // keys MIGHT still appear in older persisted entries (or future
      // model drift) - they're tracked above as kcal/macros, never as
      // "also detected". Drop them here too.
      if (_macroLeakKeys.contains(entry.key)) continue;
      // Build +35 follow-up: surface the actual quantity + unit so the
      // user can SEE what the model detected ("Vitamin C 45 mg") instead
      // of just the bare name ("Vitamin C"). Tester report: "ich
      // verstehe den Hinweis nicht ganz" - the value gives the hint
      // concrete content.
      final label = _prettifyNutrientKey(entry.key);
      final unit = _unitForNutrientKey(entry.key);
      final value = _formatNutrientValue(entry.value);
      extras.add(unit.isEmpty ? '$label $value' : '$label $value $unit');
    }
    return extras;
  }

  String _unitForNutrientKey(String key) {
    final lower = key.toLowerCase();
    if (lower.endsWith('_ug') || lower.endsWith('_mcg') ||
        lower.endsWith('µg')) {
      return 'µg';
    }
    if (lower.endsWith('_mg')) return 'mg';
    if (lower.endsWith('_g')) return 'g';
    if (lower.endsWith('_ml')) return 'ml';
    return '';
  }

  String _formatNutrientValue(double v) {
    if (v >= 100) return v.toStringAsFixed(0);
    if (v >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(1);
  }

  static const Set<String> _macroLeakKeys = {
    'protein_g',
    'carbs_g',
    'carbohydrates_g',
    'fat_g',
    'kcal',
    'kcal_total',
    'energy_kcal',
  };

  // Best-effort human label for an unknown nutrient key. The supplement
  // and meal prompts both use lower_snake_case + a trailing unit suffix
  // (e.g. magnesium_mg, selenium_ug, vitamin_c_mg), so we split off the
  // unit and Title-Case the rest. Falls back to the raw key on anything
  // weirder so we never hide what we got.
  String _prettifyNutrientKey(String key) {
    final stripped = key.replaceAll(
        RegExp(r'_(ug|mg|g|mcg|µg|kcal|kj|ml|l)$', caseSensitive: false), '');
    if (stripped.isEmpty) return key;
    return stripped
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  Widget _buildActionRow() {
    return _ActionRow(
      onDiscard: _discard,
      onSave: _save,
      onAddAnother: widget.allowScanAnother ? _showAddAnotherChooser : null,
    );
  }

  // Bottom-sheet chooser shown when the user taps "Weiteren Bestandteil
  // hinzufügen". A mixed meal might combine a scanned skyr with a typed
  // apple - barcode is one of three valid follow-up paths, not the only
  // one. Whatever the user picks gets passed back as the sheet's pop
  // value so the parent loop can branch accordingly.
  Future<void> _showAddAnotherChooser() async {
    final chosen = await showScanModeChooser(context);
    if (chosen == null || !mounted) return;
    // Save current meal into the pending bundle (no coach call yet) and
    // signal the parent loop which entry path to take next.
    await _save(fireCoach: false, popValue: chosen);
  }

  Widget _buildSheetHeader() {
    return _SheetHeaderContent(
      isEditing: widget.existingMealId != null,
      saveAsFavorite: _saveAsFavorite,
      onToggleFavorite: () =>
          setState(() => _saveAsFavorite = !_saveAsFavorite),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asSheet) {
      return PopScope(
        canPop: !_userTouched,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final navigator = Navigator.of(context);
          final discard = await _confirmDiscardChanges();
          if (discard && mounted) navigator.pop();
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHeader(),
                Flexible(child: _buildBody(context)),
                // Build +35 follow-up: dropped the bespoke keyboard-up
                // accessory bar. It flickered to/from the regular action
                // row when the keyboard slid in/out. With onTapOutside
                // on each TextField the user dismisses the keyboard by
                // tapping anywhere outside; the action row stays
                // consistently visible.
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _buildActionRow(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return PopScope(
      canPop: !_userTouched,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await _confirmDiscardChanges();
        if (discard && mounted) {
          navigator.pop();
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.existingMealId != null
                  ? AppLocalizations.of(context).confirmTitleEdit
                  : AppLocalizations.of(context).confirmTitleNew,
            ),
            centerTitle: false,
          actions: [
            IconButton(
              tooltip: _saveAsFavorite
                  ? AppLocalizations.of(context).confirmFavoriteRemove
                  : AppLocalizations.of(context).confirmFavoriteAdd,
              icon: Icon(
                _saveAsFavorite ? Icons.star : Icons.star_border,
                color: _saveAsFavorite
                    ? Theme.of(context).colorScheme.secondary
                    : null,
              ),
              onPressed: () =>
                  setState(() => _saveAsFavorite = !_saveAsFavorite),
            ),
          ],
        ),
          body: _buildBody(context),
          // Build +35 follow-up: keyboard-accessory bar dropped (same
          // reason as the sheet mode). Action row stays in the bottom
          // bar through keyboard transitions; onTapOutside on TextFields
          // handles dismiss.
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildActionRow(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final String? helper;
  final bool decimal;
  final VoidCallback? onSubmit;
  const _SmallField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.helper,
    required this.decimal,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      textInputAction: TextInputAction.done,
      // Build +35 follow-up: replace the bespoke keyboard accessory bar
      // with the standard onTapOutside dismiss. The accessory bar caused
      // an amber/beige "Fertig/Speichern" flicker between accessory and
      // ActionRow as the keyboard slid in/out - cleaner to just let the
      // keyboard collapse and show the regular action row throughout.
      onTapOutside: (_) =>
          FocusManager.instance.primaryFocus?.unfocus(),
      onSubmitted: (_) {
        if (onSubmit != null) {
          onSubmit!();
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: const OutlineInputBorder(),
        suffixText: suffix,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _SheetHeaderContent extends StatelessWidget {
  final bool isEditing;
  final bool saveAsFavorite;
  final VoidCallback onToggleFavorite;
  const _SheetHeaderContent({
    required this.isEditing,
    required this.saveAsFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    isEditing
                        ? AppLocalizations.of(context).confirmTitleEdit
                        : AppLocalizations.of(context).confirmTitleNew,
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.outline,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                // Edit-pencil sits beside the title when the user is
                // editing an existing meal - moved here from the diary
                // row per beta feedback. New entries don't get it
                // because they're being created, not edited.
                if (isEditing) const EditHintIcon(),
              ],
            ),
          ),
          IconButton(
            tooltip: saveAsFavorite
                ? AppLocalizations.of(context).confirmFavoriteRemove
                : AppLocalizations.of(context).confirmFavoriteAdd,
            icon: Icon(
              saveAsFavorite ? Icons.star : Icons.star_border,
              color: saveAsFavorite ? scheme.secondary : null,
            ),
            onPressed: onToggleFavorite,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onDiscard;
  final VoidCallback onSave;
  // Non-null only when the parent flow can chain another item (currently
  // bundle-session, started from the barcode entry). Triggers a chooser
  // sheet so the next item can be a scan, a photo, or text.
  final VoidCallback? onAddAnother;
  const _ActionRow({
    required this.onDiscard,
    required this.onSave,
    this.onAddAnother,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDiscard,
                child: Text(l10n.confirmDiscardConfirm),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: onSave,
                child: Text(l10n.confirmSave),
              ),
            ),
          ],
        ),
        if (onAddAnother != null) ...[
          const SizedBox(height: 4),
          // Same Layers icon + rose tone as the top "Bestandteil N" hint
          // so the connection between the action and the bundle state
          // reads at a glance, even though they sit at opposite ends of
          // the sheet.
          TextButton.icon(
            onPressed: onAddAnother,
            icon: Icon(
              Icons.layers_outlined,
              size: 18,
              color: scheme.tertiary,
            ),
            label: Text(
              l10n.confirmScanAnother,
              style: TextStyle(color: scheme.tertiary),
            ),
          ),
        ],
      ],
    );
  }
}

// Combined "{date} · {time}" pill above the confirm form (phase 6 of
// the diary refactor). Quiet by default; tints amber when the chosen
// day deviates from today so the user notices the retro-anchor at a
// glance. One tap opens date-picker → time-picker in sequence.
class _DateTimePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool deviation;
  final VoidCallback onTap;
  const _DateTimePill({
    required this.icon,
    required this.label,
    required this.deviation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bg = deviation
        ? scheme.secondaryContainer
        : scheme.surfaceContainerHighest;
    final fg = deviation
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Picks the next scan-session mode (barcode / photo / text). Shared by
// ConfirmScreen's "Add another" affordance and by the scan-session loop
// when the user backs out of a sub-scanner mid-session (Task A5,
// Build +34) - re-showing the chooser lets them switch entry mode
// instead of dropping the whole session.
Future<String?> showScanModeChooser(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: Text(l10n.confirmAddByBarcode),
            onTap: () => Navigator.pop(sheetContext, 'barcode'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.confirmAddByPhoto),
            onTap: () => Navigator.pop(sheetContext, 'photo'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.confirmAddByText),
            onTap: () => Navigator.pop(sheetContext, 'text'),
          ),
        ],
      ),
    ),
  );
}

// Informational card listing nutrients the parser identified but which
// the app's daily tracking does not cover yet (Task B9). Visually softer
// than the safety block (primaryContainer + info icon) so it reads as a
// transparency note, not a warning.
class _UnsupportedNutrientNote extends StatelessWidget {
  final List<String> labels;
  const _UnsupportedNutrientNote({required this.labels});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final joined = labels.join(', ');
    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 18, color: scheme.onPrimaryContainer),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.confirmUnsupportedNutrientHeader,
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.confirmUnsupportedNutrientHint(joined),
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onPrimaryContainer,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// Renders the per-meal safety warnings card with a severity-aware tier:
// any `critical` warning (alcohol today) flips the whole block to the
// error tone with the filled `error` icon so the user can't read past it.
// Default `warn` keeps the long-standing soft tertiary card. Pulled out
// of the build method so the visual contract is explicit and testable.
class _SafetyWarningsBlock extends StatelessWidget {
  final List<String> warnings;
  const _SafetyWarningsBlock({required this.warnings});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final highest = SafetyRules.highestSeverity(warnings);
    final isCritical = highest == SafetyWarningSeverity.critical;
    final bg = isCritical ? scheme.errorContainer : scheme.tertiaryContainer;
    final fg =
        isCritical ? scheme.onErrorContainer : scheme.onTertiaryContainer;
    final icon = isCritical ? Icons.error : Icons.warning_amber;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).confirmSafetyHeader,
                style: textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• $w',
                style: textTheme.bodySmall?.copyWith(color: fg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
