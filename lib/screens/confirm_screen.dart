import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';

import '../models/favorite_meal.dart';
import '../models/meal_entry.dart';
import '../models/meal_entry_source.dart';
import '../models/thread_item.dart';
import '../providers/meal_providers.dart';
import '../providers/ui_providers.dart';
import '../services/claude_client.dart';
import '../services/coach_session_manager.dart';
import '../services/notification_scheduler.dart';

class ConfirmScreen extends ConsumerStatefulWidget {
  final String rawText;
  final MealParseResult parsed;
  final Uint8List? imageBytes;
  final String? existingMealId;
  final DateTime? existingCreatedAt;
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
    _mealTime = widget.existingCreatedAt ?? DateTime.now();

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
      final parsed = await ref.read(claudeClientProvider).parseMeal(
            newText,
            locale: Localizations.localeOf(context).languageCode,
            isPregnant: profile?.isPregnant ?? false,
            trimester: profile?.trimester,
            isLactating: (profile?.numChildrenNursing ?? 0) > 0,
          );
      if (!mounted) return;
      if (!parsed.isMeal) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parsed.rejectionReason ??
                AppLocalizations.of(context).commonGenericError),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.userMessage)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).commonGenericError),
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
      safetyWarnings: widget.parsed.safetyWarnings,
      // Carry the parser's per-meal micronutrient estimates through to
      // storage. The daily-aggregation provider sums these across the
      // day's meals; absent on legacy entries or meals where the parser
      // judged all nutrients negligible.
      micronutrients: widget.parsed.micronutrients,
    );
    await ref.read(mealRepositoryProvider).save(meal);
    final analytics = ref.read(analyticsServiceProvider);
    analytics.capture('meal_logged', properties: {
      'method': widget.source.analyticsLabel,
      'edited': widget.existingMealId != null,
    });
    // Smart-skip: if this meal covers a reminder slot (by time-of-day
    // bucket), cancel today's occurrence of that slot and re-anchor its
    // daily chain to tomorrow. Fire-and-forget so the save UX isn't gated
    // on the notification plugin round-trip.
    NotificationScheduler.skipCoveredReminder(
      mealAt: meal.createdAt,
      settings: reminderSettings,
      l10n: reminderL10n,
    ).catchError((Object e, StackTrace _) {
      debugPrint('skipCoveredReminder failed: $e');
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
        safetyWarnings: widget.parsed.safetyWarnings,
        micronutrients: widget.parsed.micronutrients,
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

    if (!isEdit) {
      // New meal: persist it so it shows up in the diary right away. The
      // coach call is either fired now (with any pending bundle) or
      // deferred (added to the bundle for the next save to fire).
      await threadRepo.add(
          ThreadItem.meal(mealId: meal.id, at: meal.createdAt));
      final bundleNotifier =
          ref.read(pendingScanBundleProvider.notifier);
      if (fireCoach) {
        // Drain any in-progress scan bundle and fire one coach call for
        // everything together (or just this meal when no bundle exists).
        final pending = ref.read(pendingScanBundleProvider);
        bundleNotifier.state = const [];
        final all = [...pending, meal];
        ref.read(coachSessionProvider.notifier).submitMeals(all, locale);
      } else {
        // Append to the bundle without firing - used by the barcode
        // "+ Noch einen scannen" path.
        bundleNotifier.state = [...bundleNotifier.state, meal];
      }
      // Scroll the diary to the meal's day only for retro-logs (past-day
      // saves). Today's saves don't need it - the new entry lands at the
      // bottom near the input bar, naturally visible. Firing the scroll
      // for today made the diary jump up to "today's earliest entry",
      // which felt like an unwanted scroll-up right after saving.
      final now = DateTime.now();
      final todayKey = DateTime(now.year, now.month, now.day);
      final mealDay = DateTime(
          meal.createdAt.year, meal.createdAt.month, meal.createdAt.day);
      if (mealDay != todayKey) {
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

  Future<void> _pickMealTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_mealTime),
      helpText: AppLocalizations.of(context).homeTimePickerHelp,
    );
    if (picked != null && mounted) {
      setState(() {
        _mealTime = DateTime(_mealTime.year, _mealTime.month, _mealTime.day,
            picked.hour, picked.minute);
        _userTouched = true;
      });
    }
  }

  String _formatMealTime() {
    final hh = _mealTime.hour.toString().padLeft(2, '0');
    final mm = _mealTime.minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    final isToday = _mealTime.year == now.year &&
        _mealTime.month == now.month &&
        _mealTime.day == now.day;
    return isToday ? '$hh:$mm' : '${_mealTime.day}.${_mealTime.month}. · $hh:$mm';
  }

  Widget _buildBody(BuildContext context) {
    final warnings = widget.parsed.safetyWarnings;
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
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l10n.confirmDescriptionHint,
                  hintStyle: TextStyle(color: scheme.outline),
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
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
        // Meal time, editable here (moved out of the cramped home input row).
        // Defaults to now for fresh entries, or the entry's day for past-day
        // / edit flows.
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _pickMealTime,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule,
                        size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(_formatMealTime(), style: textTheme.labelLarge),
                  ],
                ),
              ),
            ),
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
          Container(
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber,
                        size: 18, color: scheme.onTertiaryContainer),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context).confirmSafetyHeader,
                      style: textTheme.labelLarge?.copyWith(
                        color: scheme.onTertiaryContainer,
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
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
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
    final l10n = AppLocalizations.of(context);
    final chosen = await showModalBottomSheet<String>(
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
      final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
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
                // When the keyboard is up, replace the full action row with a
                // compact accessory bar so the user has a "Speichern" button
                // immediately above the keys (iOS-Numpad has no Done key).
                if (keyboardOpen)
                  _KeyboardAccessoryBar(onSave: _save)
                else
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
          // Edit-mode (full Scaffold) used to show only the full action row in
          // the bottomNavigationBar. iOS keyboard kept it above the keys but
          // occluded the Save button visually for some users when the
          // description field was focused. Switch to the same accessory-bar
          // pattern as sheet mode: compact "Done + Save" bar while the
          // keyboard is up, full Discard + Save action row otherwise.
          bottomNavigationBar:
              MediaQuery.of(context).viewInsets.bottom > 0
                  ? _KeyboardAccessoryBar(onSave: _save)
                  : SafeArea(
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

class _KeyboardAccessoryBar extends StatelessWidget {
  final VoidCallback onSave;
  const _KeyboardAccessoryBar({required this.onSave});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => FocusScope.of(context).unfocus(),
            child: Text(
              AppLocalizations.of(context).commonDone,
              style: TextStyle(color: scheme.outline),
            ),
          ),
          const SizedBox(width: 4),
          FilledButton.tonal(
            onPressed: onSave,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(AppLocalizations.of(context).confirmSave),
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
