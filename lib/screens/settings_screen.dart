import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/favorite_meal.dart';
import '../models/reminder_settings.dart';
import '../models/weight_entry.dart';
import '../services/feedback_sender.dart';
import 'tips_screen.dart';
import '../services/notification_scheduler.dart';
import '../models/meal_entry.dart' show MicronutrientKey;
import '../models/user_profile_settings.dart';
import '../services/micronutrient_targets.dart' show MicronutrientDisplay;
import '../providers/meal_providers.dart';
import '../providers/ui_providers.dart';
import '../services/calorie_target.dart';
import '../services/nutrition_facts.dart';
import '../utils/number_format.dart';
import '../utils/profile_labels.dart';
import '../widgets/child_age_input.dart';
import '../widgets/edit_hint_icon.dart';
import '../widgets/info_button.dart';
import '../widgets/milk_share_selector.dart';
import '../widgets/milk_volume_age_hint.dart';
import '../widgets/supplement_setup.dart';
import 'favorite_edit_sheet.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late DateTime _birthdate;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  // Focus-aware text-field bookkeeping (Build +34 fix to the auto-save
  // Undo bug Vanessa flagged): per-controller FocusNode + the value that
  // was in the field at the moment focus was acquired. We snapshot the
  // pre-edit profile WHEN focus arrives and persist WHEN focus leaves -
  // so the Undo action reverts to the user's pre-typing value instead of
  // mid-typing intermediates (the old behaviour treated each keystroke as
  // its own save batch, so typing "62" on top of "60" used to make Undo
  // jump to "6" not back to "60").
  late final FocusNode _heightFocus;
  late final FocusNode _weightFocus;
  late final FocusNode _notesFocus;
  // Macro split as percentages. 0 = follow auto-default, otherwise overridden.
  late int _customProteinPct;
  late int _customFatPct;
  // Diet + allergy state. Sourced from UserProfileSettings.dietStyle /
  // restrictions / dietaryNotes and threaded into the coach prompts on
  // save so the suggestions match.
  late String _dietStyle;
  late Set<String> _restrictions;
  late TextEditingController _dietaryNotes;
  late double _activityFactor;
  // Radio: 'lactating' or 'pregnant'. We treat them as mutually exclusive in
  // settings (covers >99% of cases). Tandem can be modelled via onboarding
  // or by editing once and switching.
  late String _phase;
  late int _trimester;
  // Lactation values are kept in state even when phase == 'pregnant' so the
  // user doesn't lose them when toggling.
  late int _numChildren;
  late int _milkSharePercent;
  // Per-child shares (multiples only); null/empty when single-mode. Average
  // drives the kcal estimate via UserProfileSettings.effectiveMilkSharePercent.
  List<int>? _perChildSharesPercent;
  late int _childrenAgeGroup;
  late int _dailyVolumeMl;
  // Birth date of the youngest nursing child; null = bucket-picker is the
  // source of truth, otherwise it's derived from this and the picker shown
  // read-only.
  DateTime? _youngestChildBirthdate;
  // Coach focus: 'nutrients' (default), 'body', or 'both'.
  late String _goal;
  // Meal pattern preference: classic / one_snack / three_meals / intuitive
  // (#108). Drives whether the coach proposes a "next meal" and what
  // rhythm it assumes.
  late String _mealPattern;
  // Snapshot of the user's supplements so Settings can show + add + edit +
  // remove without leaving the screen. _save persists back to the profile.
  late List<ActiveSupplement> _supplements;
  // Hand-picked micronutrient subset for the diary header. null = follow
  // phase/diet defaults; non-null overrides them (capped at 3 by the UI).
  List<String>? _selectedMicros;
  bool _initialized = false;
  String? _initialProfileJson;
  // Task A11, Build +34: settings auto-save with debounce + Undo snack.
  // The timer batches consecutive mutations (slider drags, typing) into
  // one save. The snapshot is the profile state BEFORE the first mutation
  // in a batch, so the Undo action reverts the whole batch in one tap.
  Timer? _autoSaveTimer;
  // Separate "show the Undo snackbar after a quiet period" timer
  // (Build +35 follow-up). The save itself fires fast (700ms debounce)
  // so data is safe. The snack waits another 1.5 s of silence so a
  // burst of consecutive changes collapses into a single trailing
  // snack instead of stacking three or four nearly-overlapping ones.
  Timer? _quietSnackTimer;
  UserProfileSettings? _pendingUndoSnapshot;
  UserProfileSettings? _quietSnackSnapshot;
  static const _autoSaveDebounce = Duration(milliseconds: 700);
  // Tighter than the first iteration (1500ms) - Vanessa flagged the
  // combined 1.5s + 4s snack as "bleibt zu lang". 0.8s quiet window
  // + 3s snack = 3.8s total, still inside MD3 spec for action snacks.
  static const _quietSnackDelay = Duration(milliseconds: 800);
  // Override for the next weight-history entry's recordedAt. Null = use
  // DateTime.now() on save. Set when the user taps the "Gewogen am"
  // pill that appears under the weight field after they actually change
  // its value (e.g. "ich habe mich heute morgen gewogen, sitze aber
  // erst jetzt abends in Settings" - they pick this morning's date so
  // the trends chart shows the right anchor point).
  DateTime? _weightRecordedAt;
  // Bumped on every setState so detail-page routes pushed on top of the
  // hub can ListenableBuilder-rebuild against the shared state. Without
  // this, a slider drag inside a detail page would only rebuild the hub
  // (which is hidden underneath) and leave the visible detail screen
  // stuck on the old value.
  final ValueNotifier<int> _stateVersion = ValueNotifier(0);

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _stateVersion.value++;
  }

  @override
  void dispose() {
    if (_initialized) {
      _height.dispose();
      _weight.dispose();
      _dietaryNotes.dispose();
      _heightFocus.dispose();
      _weightFocus.dispose();
      _notesFocus.dispose();
    }
    _stateVersion.dispose();
    // Flush pending auto-save synchronously: the timer would fire after
    // the widget tree is gone, so we drop it. The on-screen state was
    // already mirrored locally; the next time the user opens Settings
    // it rehydrates from the persisted profile, so we don't lose the
    // most recent edit unless dispose happens within 700ms of a mutation.
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _quietSnackTimer?.cancel();
    _quietSnackTimer = null;
    _snackForceDismissTimer?.cancel();
    _snackForceDismissTimer = null;
    super.dispose();
  }

  // Reconstructs the profile that was last persisted (mirrors what's on
  // disk + in userProfileProvider). Used as the Undo snapshot so we can
  // revert the user back to the last known good state regardless of how
  // many UI mutations or text-controller listener firings have happened
  // since.
  UserProfileSettings _lastPersistedSnapshot() {
    final raw = _initialProfileJson;
    if (raw == null) return _currentProfile();
    return UserProfileSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  // Wraps a state mutation with auto-save bookkeeping. Captures the
  // pre-change profile snapshot (only on the FIRST mutation of a batch
  // so multi-field undos still revert to the user's original state),
  // applies the change, and schedules a debounced save.
  void _mutate(VoidCallback fn) {
    _pendingUndoSnapshot ??= _lastPersistedSnapshot();
    // A fresh mutation cancels any pending "show the snack after quiet"
    // timer - we're not quiet anymore. The snack will get re-armed at
    // the next _runAutoSave tick.
    _quietSnackTimer?.cancel();
    _quietSnackTimer = null;
    setState(fn);
    _scheduleAutoSave();
  }

  // Restarts the debounce timer. Consecutive _mutate calls within 700ms
  // collapse into a single persist + snackbar.
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDebounce, _runAutoSave);
  }

  // Persists the current profile and shows a single Undo snackbar with
  // the pre-batch snapshot. Tapping Undo restores that snapshot (state +
  // repo) and silently writes it back; the snackbar shown for that revert
  // has no Undo (you "undo" the undo by editing again).
  Future<void> _runAutoSave() async {
    _autoSaveTimer = null;
    if (!mounted) return;
    final snapshot = _pendingUndoSnapshot;
    _pendingUndoSnapshot = null;
    if (snapshot == null) return;
    final newProfile = _currentProfile();
    if (jsonEncode(newProfile.toJson()) == jsonEncode(snapshot.toJson())) {
      // No effective change (e.g. text field reformatted, identical
      // value re-picked). Skip the noise of an Undo snack pointing at
      // itself.
      return;
    }
    await _persistProfile(newProfile, previousForUndo: snapshot);
  }

  // Core write path. Shared by the auto-save tick and the Undo revert.
  // When [previousForUndo] is supplied AND quietMode is true, the
  // snackbar is deferred until 1.5 s of mutation-free silence; consecutive
  // saves within a burst no longer stack visible snacks. Without
  // previousForUndo, the snack is informational and shows immediately
  // (used after the user already tapped Undo).
  Future<void> _persistProfile(UserProfileSettings newProfile,
      {UserProfileSettings? previousForUndo}) async {
    if (!mounted) return;
    await ref.read(settingsRepositoryProvider).saveProfile(newProfile);
    // Record a weight history entry whenever the value differs from the
    // last save. Mirrors the logic from the legacy explicit-save path so
    // the Trends-tab chart keeps its anchor points after a typed change.
    final initial = _initialProfileJson;
    final prevWeight = initial == null
        ? null
        : (jsonDecode(initial) as Map<String, dynamic>)['weightKg'] as num?;
    if (prevWeight == null || prevWeight.toDouble() != newProfile.weightKg) {
      await ref.read(weightRepositoryProvider).save(WeightEntry(
            id: 'w-${DateTime.now().microsecondsSinceEpoch}',
            weightKg: newProfile.weightKg,
            recordedAt: _weightRecordedAt ?? DateTime.now(),
          ));
      ref.read(analyticsServiceProvider).capture('weight_logged',
          properties: {'source': 'settings'});
    }
    _weightRecordedAt = null;
    if (!mounted) return;
    ref.invalidate(userProfileProvider);
    _initialProfileJson = jsonEncode(newProfile.toJson());
    if (previousForUndo != null) {
      // Save-side flow: arm a quiet-window timer instead of showing
      // immediately, so a burst of consecutive mutations collapses
      // into one trailing snack. Each _mutate() call cancels this
      // timer and a fresh one will be armed by the next _runAutoSave.
      _quietSnackSnapshot = previousForUndo;
      _quietSnackTimer?.cancel();
      _quietSnackTimer = Timer(_quietSnackDelay, _showQuietSnack);
    } else {
      // Revert-side flow: this snack confirms the user's own Undo tap
      // and should appear immediately, no quiet window needed.
      _showSavedSnack(previousForUndo: null);
    }
  }

  void _showQuietSnack() {
    if (!mounted) return;
    final snapshot = _quietSnackSnapshot;
    _quietSnackSnapshot = null;
    _quietSnackTimer = null;
    if (snapshot == null) return;
    _showSavedSnack(previousForUndo: snapshot);
  }

  void _showSavedSnack({required UserProfileSettings? previousForUndo}) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final messenger = rootScaffoldMessengerKey.currentState;
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(l10n.settingsSavedSnackbar),
        // Build +35 follow-up: 3 s instead of 4 s. Combined with the
        // 0.8 s quiet window the total user-perceived snack life is
        // ~3.8 s, which sits inside MD3 "action snackbar 3-10 s" and
        // addresses the "bleibt zu lang" tester report.
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: previousForUndo == null
            ? null
            : SnackBarAction(
                label: l10n.commonUndo,
                onPressed: () => _revertTo(previousForUndo),
              ),
      ),
    );
    // Belt-and-braces force-dismiss: tester report Build +35 found
    // SnackBars with action + floating behavior sometimes ignore the
    // declared duration on iOS. Manual hide guarantees the snack
    // disappears at the time we promised.
    _scheduleSnackForceDismiss(const Duration(seconds: 3, milliseconds: 200));
  }

  Timer? _snackForceDismissTimer;
  void _scheduleSnackForceDismiss(Duration after) {
    _snackForceDismissTimer?.cancel();
    _snackForceDismissTimer = Timer(after, () {
      if (!mounted) return;
      rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    });
  }

  // Restores state from [snapshot] (the profile before the most recent
  // batch of mutations) and writes it back so the persisted profile + UI
  // stay in sync. Cancels any debounce or pending snack that hadn't
  // fired yet.
  Future<void> _revertTo(UserProfileSettings snapshot) async {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _quietSnackTimer?.cancel();
    _quietSnackTimer = null;
    _quietSnackSnapshot = null;
    _pendingUndoSnapshot = null;
    if (!mounted) return;
    setState(() => _rehydrateState(snapshot));
    await _persistProfile(snapshot);
  }

  // Re-applies the values of [p] onto the existing controllers + fields.
  // Used by Undo so we can revert without disposing/recreating the text
  // controllers (which would lose focus / cursor positions).
  void _rehydrateState(UserProfileSettings p) {
    _birthdate = p.birthdate ?? UserProfileSettings.birthdateFromAge(p.ageYears);
    _height.text = p.heightCm.toStringAsFixed(0);
    _weight.text = p.weightKg.toStringAsFixed(1);
    _activityFactor = p.activityFactor;
    _phase = p.numChildrenNursing > 0
        ? 'lactating'
        : (p.isPregnant ? 'pregnant' : 'neither');
    _trimester = p.trimester ?? 1;
    _numChildren = p.numChildrenNursing > 0 ? p.numChildrenNursing : 1;
    _milkSharePercent = p.milkSharePercent;
    _perChildSharesPercent = p.perChildSharesPercent != null
        ? List<int>.from(p.perChildSharesPercent!)
        : null;
    _childrenAgeGroup = p.currentChildrenAgeGroup;
    _youngestChildBirthdate = p.youngestChildBirthdate;
    _dailyVolumeMl = p.dailyMilkVolumeMl;
    _customProteinPct = p.customProteinPct;
    _customFatPct = p.customFatPct;
    _dietStyle = p.dietStyle;
    _restrictions = {...p.restrictions};
    _dietaryNotes.text = p.dietaryNotes;
    _selectedMicros =
        p.selectedMicronutrients == null ? null : [...p.selectedMicronutrients!];
    _goal = p.goal;
    _mealPattern = p.mealPattern;
    _supplements = [...p.activeSupplements];
  }

  void _hydrate(UserProfileSettings p) {
    _birthdate = p.birthdate ?? UserProfileSettings.birthdateFromAge(p.ageYears);
    _height = TextEditingController(text: p.heightCm.toStringAsFixed(0));
    _weight = TextEditingController(text: p.weightKg.toStringAsFixed(1));
    _activityFactor = p.activityFactor;
    // Lactation wins if user has children; pregnant if flagged; else
    // 'neither' (was 'lactating' default before the 3rd option existed,
    // which surfaced fields the user couldn't fill in).
    _phase = p.numChildrenNursing > 0
        ? 'lactating'
        : (p.isPregnant ? 'pregnant' : 'neither');
    _trimester = p.trimester ?? 1;
    _numChildren = p.numChildrenNursing > 0 ? p.numChildrenNursing : 1;
    _milkSharePercent = p.milkSharePercent;
    _perChildSharesPercent = p.perChildSharesPercent != null
        ? List<int>.from(p.perChildSharesPercent!)
        : null;
    _childrenAgeGroup = p.currentChildrenAgeGroup;
    _youngestChildBirthdate = p.youngestChildBirthdate;
    _dailyVolumeMl = p.dailyMilkVolumeMl > 0
        ? p.dailyMilkVolumeMl
        : UserProfileSettings.estimatedDailyVolumeMl(
            numChildren: _numChildren,
            ageGroup: _childrenAgeGroup,
            sharePercent: _milkSharePercent,
          );
    _customProteinPct = p.customProteinPct;
    _customFatPct = p.customFatPct;
    _dietStyle = p.dietStyle;
    _restrictions = {...p.restrictions};
    _dietaryNotes = TextEditingController(text: p.dietaryNotes);
    _selectedMicros =
        p.selectedMicronutrients == null ? null : [...p.selectedMicronutrients!];
    _goal = p.goal;
    _mealPattern = p.mealPattern;
    _supplements = [...p.activeSupplements];
    _initialProfileJson = jsonEncode(p.toJson());

    _heightFocus = FocusNode();
    _weightFocus = FocusNode();
    _notesFocus = FocusNode();
    // Keystroke listeners only rebuild dependent sections (macro recompute
    // when weight changes, etc.) and do NOT schedule a save. Saves are
    // tied to focus loss - see _bindFocusSave below. This is the +34 fix
    // for the multi-keystroke Undo bug: typing "62" on top of "60" used
    // to make Undo revert to "6" because each keystroke captured the
    // intermediate state as the next snapshot. With focus-tied saves, one
    // focused edit = one save = one undo target.
    for (final c in [_height, _weight, _dietaryNotes]) {
      c.addListener(() {
        if (!mounted) return;
        setState(() {});
      });
    }
    _bindFocusSave(_heightFocus);
    _bindFocusSave(_weightFocus);
    _bindFocusSave(_notesFocus);
    _initialized = true;
  }

  // Hook a FocusNode so we (1) snapshot the persisted profile the moment
  // the field gains focus and (2) flush a save when focus leaves. The
  // snapshot is captured here (not on the FIRST keystroke) so the Undo
  // target is always the value before the user started typing, even if
  // the keystroke listeners fired before focus actually arrived.
  void _bindFocusSave(FocusNode node) {
    node.addListener(() {
      if (!mounted) return;
      if (node.hasFocus) {
        // New focus arrival - lock in the snapshot if there isn't one
        // already pending. (?? ensures a snapshot mid-edit, e.g. switch
        // between two text fields, doesn't overwrite an earlier snapshot.)
        _pendingUndoSnapshot ??= _lastPersistedSnapshot();
      } else {
        // Focus left - flush any pending debounce as a save. Cancel the
        // timer first so we don't double-save (the keystroke path doesn't
        // schedule any more, but a slider or chip might have).
        _autoSaveTimer?.cancel();
        _autoSaveTimer = null;
        _runAutoSave();
      }
    });
  }

  double _parseDouble(String s, double fallback) =>
      double.tryParse(s.replaceAll(',', '.')) ?? fallback;

  int _ageFromBirthdate(DateTime b) {
    final now = DateTime.now();
    var age = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickYoungestChildBirthdate() async {
    final now = DateTime.now();
    final initial = _youngestChildBirthdate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      // Allow up to 3 years back - past 12 months the user is out of the
      // milk-volume estimation buckets anyway, but we don't gate on that.
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      helpText: AppLocalizations.of(context).settingsMilkBirthdatePickerHelp,
    );
    if (picked != null) {
      _mutate(() {
        _youngestChildBirthdate = picked;
        // Sync the static bucket to the derived value so other code paths
        // that still read it (and the on-screen segmented picker) stay
        // visually consistent.
        final months = (now.year - picked.year) * 12 +
            (now.month - picked.month) -
            (now.day < picked.day ? 1 : 0);
        _childrenAgeGroup = months < 6 ? 0 : (months < 12 ? 1 : 2);
        _dailyVolumeMl = UserProfileSettings.estimatedDailyVolumeMl(
          numChildren: _numChildren,
          ageGroup: _childrenAgeGroup,
          sharePercent: _milkSharePercent,
        );
      });
    }
  }

  // True when the user has changed the weight value vs the snapshot we
  // hydrated from. Drives the visibility of the "Gewogen am" date pill -
  // showing it for every Settings open would just add noise when the user
  // wasn't touching weight at all.
  bool get _weightChanged {
    final initial = _initialProfileJson;
    if (initial == null) return false;
    final prev = (jsonDecode(initial) as Map<String, dynamic>)['weightKg'] as num?;
    if (prev == null) return false;
    return prev.toDouble() != _parseDouble(_weight.text, 65);
  }

  Future<void> _pickWeightRecordedAt() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _weightRecordedAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      helpText: AppLocalizations.of(context).homeDatePickerHelp,
    );
    if (picked != null && mounted) {
      // _weightRecordedAt is only metadata for the next weight save; doesn't
      // change the persisted profile by itself. No auto-save here; the
      // listener on _weight will fire if the value actually moves.
      setState(() => _weightRecordedAt = picked);
    }
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate,
      firstDate: DateTime(now.year - 80),
      lastDate: now,
      helpText: AppLocalizations.of(context).settingsBirthdatePickerHelp,
    );
    if (picked != null) _mutate(() => _birthdate = picked);
  }

  bool get _isLactating => _phase == 'lactating';
  bool get _isPregnant => _phase == 'pregnant';

  UserProfileSettings _currentProfile() => UserProfileSettings(
        ageYears: _ageFromBirthdate(_birthdate),
        birthdate: _birthdate,
        heightCm: _parseDouble(_height.text, 170),
        weightKg: _parseDouble(_weight.text, 65),
        activityFactor: _activityFactor,
        isPregnant: _isPregnant,
        trimester: _isPregnant ? _trimester : null,
        numChildrenNursing: _isLactating ? _numChildren : 0,
        milkSharePercent: _milkSharePercent,
        perChildSharesPercent: (_isLactating &&
                _numChildren > 1 &&
                _perChildSharesPercent != null &&
                _perChildSharesPercent!.isNotEmpty)
            ? List<int>.from(_perChildSharesPercent!)
            : null,
        childrenAgeGroup: _childrenAgeGroup,
        youngestChildBirthdate: _youngestChildBirthdate,
        dailyMilkVolumeMl: _isLactating ? _dailyVolumeMl : 0,
        milkSupplementKcal: 0,
        customProteinPct: _customProteinPct,
        customFatPct: _customFatPct,
        dietStyle: _dietStyle,
        restrictions: _restrictions,
        dietaryNotes: _dietaryNotes.text.trim(),
        selectedMicronutrients:
            _selectedMicros == null ? null : List<String>.from(_selectedMicros!),
        goal: _goal,
        mealPattern: _mealPattern,
        activeSupplements: List<ActiveSupplement>.from(_supplements),
      );

  void _onSharePercentChanged(int v) {
    _mutate(() {
      _milkSharePercent = v;
      _dailyVolumeMl = UserProfileSettings.estimatedDailyVolumeMl(
        numChildren: _numChildren,
        ageGroup: _childrenAgeGroup,
        sharePercent: v,
      );
    });
  }

  void _onPerChildSharesChanged(List<int>? list) {
    _mutate(() {
      _perChildSharesPercent = list;
      final effective = (list != null && list.isNotEmpty)
          ? (list.fold<int>(0, (a, b) => a + b) / list.length).round()
          : _milkSharePercent;
      _dailyVolumeMl = UserProfileSettings.estimatedDailyVolumeMl(
        numChildren: _numChildren,
        ageGroup: _childrenAgeGroup,
        sharePercent: effective,
      );
    });
  }

  void _onNumChildrenChanged(int v) {
    _mutate(() {
      _numChildren = v;
      // Per-child override only makes sense for multiples. Dropping to 1
      // (or 0) clears it so the single share value drives the estimate
      // again. The list length is also adjusted so a 3→2 transition
      // doesn't leave a stale row in storage.
      if (v <= 1) {
        _perChildSharesPercent = null;
      } else if (_perChildSharesPercent != null) {
        final old = _perChildSharesPercent!;
        _perChildSharesPercent = List<int>.generate(
            v, (i) => i < old.length ? old[i] : _milkSharePercent);
      }
      final effective = (_perChildSharesPercent != null &&
              _perChildSharesPercent!.isNotEmpty)
          ? (_perChildSharesPercent!.fold<int>(0, (a, b) => a + b) /
                  _perChildSharesPercent!.length)
              .round()
          : _milkSharePercent;
      _dailyVolumeMl = UserProfileSettings.estimatedDailyVolumeMl(
        numChildren: v,
        ageGroup: _childrenAgeGroup,
        sharePercent: effective,
      );
    });
  }

  void _onAgeGroupChanged(int v) {
    _mutate(() {
      _childrenAgeGroup = v;
      _dailyVolumeMl = UserProfileSettings.estimatedDailyVolumeMl(
        numChildren: _numChildren,
        ageGroup: v,
        sharePercent: _milkSharePercent,
      );
    });
  }

  // When one macro slider moves, clamp the other so carbs stay ≥ 5 % (else
  // the percent split would be inconsistent: visual clamp differs from
  // saved state).
  void _onProteinPctChanged(int newP) {
    _mutate(() {
      _customProteinPct = newP;
      final profile = _currentProfile();
      final auto = autoMacroSplit(
          profile, calculateDailyCalorieTarget(profile));
      final effectiveFat = _customFatPct > 0 ? _customFatPct : auto.fatPct;
      final maxFat = (100 - newP - 5).clamp(10, 60);
      if (effectiveFat > maxFat) {
        _customFatPct = maxFat;
      }
    });
  }

  void _onFatPctChanged(int newF) {
    _mutate(() {
      _customFatPct = newF;
      final profile = _currentProfile();
      final auto = autoMacroSplit(
          profile, calculateDailyCalorieTarget(profile));
      final effectiveProtein =
          _customProteinPct > 0 ? _customProteinPct : auto.proteinPct;
      final maxProtein = (100 - newF - 5).clamp(5, 50);
      if (effectiveProtein > maxProtein) {
        _customProteinPct = maxProtein;
      }
    });
  }

  Future<void> _resetApp() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsResetTitle),
        content: Text(l10n.settingsResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.settingsResetConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(mealRepositoryProvider).clearAll();
    await ref.read(favoriteRepositoryProvider).clearAll();
    await ref.read(threadRepositoryProvider).clearAll();
    await ref.read(settingsRepositoryProvider).clearAll();
    await ref.read(weightRepositoryProvider).clearAll();
    if (!mounted) return;
    ref.invalidate(userProfileProvider);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text(AppLocalizations.of(context).settingsErrorPrefix('$e')),
        ),
      ),
      data: (profile) {
        if (!_initialized) _hydrate(profile);
        // No PopScope guard: every mutation auto-saves via _mutate, so
        // exiting Settings never loses work. The Undo snackbar on each
        // save is the safety net if the user changes something by
        // mistake (Task A11, Build +34).
        return _buildHub(context);
      },
    );
  }

  Widget _buildHub(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        centerTitle: false,
      ),
      body: ListenableBuilder(
        listenable: _stateVersion,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _OutcomeCard(profile: _currentProfile()),
            const SizedBox(height: 16),
            _HubTile(
              icon: Icons.person_outline,
              title: l10n.settingsHubAboutYou,
              subtitle: l10n.settingsHubAboutYouSummary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => _buildAboutYouPage()),
              ),
            ),
            const SizedBox(height: 8),
            _HubTile(
              icon: Icons.restaurant_menu_outlined,
              title: l10n.settingsHubCoach,
              subtitle: l10n.settingsHubCoachSummary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => _buildCoachPage()),
              ),
            ),
            const SizedBox(height: 8),
            _HubTile(
              icon: Icons.tune_outlined,
              title: l10n.settingsHubApp,
              subtitle: l10n.settingsHubAppSummary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => _buildAppPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutYouPage() {
    return PopScope(
      // Snack from the auto-save lives on the root ScaffoldMessenger and
      // would persist over the back-nav (blocking taps on the hub view
      // below until it times out). Tester report Build +34: dismiss it
      // the moment the user leaves the detail page.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).settingsHubAboutYou),
          ),
        body: ListenableBuilder(
          listenable: _stateVersion,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _PhaseSection(
                phase: _phase,
                onPhaseChanged: (v) => _mutate(() => _phase = v),
                trimester: _trimester,
                onTrimesterChanged: (v) => _mutate(() => _trimester = v),
              ),
              const SizedBox(height: 12),
              _Section(
                title: AppLocalizations.of(context).settingsSectionProfile,
                child: _ProfileFields(
                  birthdate: _birthdate,
                  onBirthdateTap: _pickBirthdate,
                  height: _height,
                  heightFocus: _heightFocus,
                  weight: _weight,
                  weightFocus: _weightFocus,
                  weightChanged: _weightChanged,
                  weightRecordedAt: _weightRecordedAt,
                  onPickWeightDate: _pickWeightRecordedAt,
                ),
              ),
              const SizedBox(height: 12),
              _ActivitySection(
                activityFactor: _activityFactor,
                onChanged: (v) => _mutate(() => _activityFactor = v),
              ),
              if (_isLactating) ...[
                const SizedBox(height: 12),
                _MilkSection(
                  numChildren: _numChildren,
                  onChildrenChanged: _onNumChildrenChanged,
                  ageGroup: _childrenAgeGroup,
                  onAgeChanged: _onAgeGroupChanged,
                  youngestChildBirthdate: _youngestChildBirthdate,
                  onPickBirthdate: _pickYoungestChildBirthdate,
                  onClearBirthdate: () =>
                      _mutate(() => _youngestChildBirthdate = null),
                  sharePercent: _milkSharePercent,
                  onShareChanged: _onSharePercentChanged,
                  perChildSharesPercent: _perChildSharesPercent,
                  onPerChildSharesChanged: _onPerChildSharesChanged,
                  dailyVolumeMl: _dailyVolumeMl,
                  onVolumeChanged: (v) => _mutate(() => _dailyVolumeMl = v),
                ),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoachPage() {
    return PopScope(
      // Same snack-dismiss-on-back as About-You above (Build +34 tester).
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).settingsHubCoach),
          ),
        body: ListenableBuilder(
          listenable: _stateVersion,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _GoalSection(
                goal: _goal,
                onChanged: (v) => _mutate(() => _goal = v),
              ),
              const SizedBox(height: 12),
              _MealPatternSection(
                pattern: _mealPattern,
                onChanged: (v) => _mutate(() => _mealPattern = v),
              ),
              const SizedBox(height: 12),
              _MacroSplitSection(
                profile: _currentProfile(),
                proteinPct: _customProteinPct,
                fatPct: _customFatPct,
                onProteinChanged: _onProteinPctChanged,
                onFatChanged: _onFatPctChanged,
                onReset: () => _mutate(() {
                  _customProteinPct = 0;
                  _customFatPct = 0;
                }),
              ),
              const SizedBox(height: 12),
              _DietSection(
                dietStyle: _dietStyle,
                onDietStyleChanged: (v) => _mutate(() => _dietStyle = v),
                restrictions: _restrictions,
                onRestrictionToggled: (tag, picked) {
                  _mutate(() {
                    if (picked) {
                      _restrictions = {..._restrictions, tag};
                    } else {
                      _restrictions = {..._restrictions}..remove(tag);
                    }
                  });
                },
                notesController: _dietaryNotes,
                notesFocus: _notesFocus,
                isInPhase: _isPregnant || _isLactating,
              ),
              const SizedBox(height: 12),
              _MicronutrientsSection(
                selected: _selectedMicros,
                onToggle: (key) {
                  _mutate(() {
                    final current = _selectedMicros ?? <String>[];
                    final next = [...current];
                    if (next.contains(key)) {
                      next.remove(key);
                    } else if (next.length < 3) {
                      next.add(key);
                    }
                    _selectedMicros = next.isEmpty && _selectedMicros == null
                        ? null
                        : next;
                  });
                },
                onReset: () => _mutate(() => _selectedMicros = null),
              ),
              const SizedBox(height: 12),
              _SupplementSection(
                supplements: _supplements,
                phaseRequiresSupplement: _isPregnant || _isLactating,
                onAdd: () async {
                  final result = await runSupplementSetup(context, ref);
                  if (result != null && mounted) {
                    _mutate(() => _supplements = [..._supplements, result]);
                  }
                },
                onEdit: (index, edited) =>
                    _mutate(() => _supplements = [
                          for (var i = 0; i < _supplements.length; i++)
                            if (i == index) edited else _supplements[i],
                        ]),
                onRemove: (index) => _mutate(() => _supplements = [
                      for (var i = 0; i < _supplements.length; i++)
                        if (i != index) _supplements[i],
                    ]),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // App page sections all self-persist (Reminders, Theme, Privacy via their
  // own writers; Favorites is read-only here). No global Save button needed -
  // tipps/feedback/reset live here as standalone actions.
  Widget _buildAppPage() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsHubApp)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _RemindersSection(),
          const SizedBox(height: 12),
          const _FavoritesSection(),
          const SizedBox(height: 12),
          _ThemeSection(),
          const SizedBox(height: 12),
          const _PrivacySection(),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TipsScreen()),
            ),
            icon: const Icon(Icons.lightbulb_outline),
            label: Text(l10n.settingsButtonShowTips),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => FeedbackSender.openFeedbackMail(l10n),
            icon: const Icon(Icons.mail_outline),
            label: Text(l10n.settingsButtonFeedback),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _resetApp,
            icon: const Icon(Icons.restore_outlined),
            label: Text(l10n.settingsButtonReset),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Hub-level drill-down tile. Renders as a tappable card with icon + title +
// short summary line so the hub reads as "3 small cards" rather than a dense
// menu list.
class _HubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final InfoButton? info;
  const _Section({required this.title, required this.child, this.info});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    // Section heading is the largest text in each card so the
                    // hierarchy reads clearly (was titleSmall, which competed
                    // with the body labels below it).
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ?info,
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseSection extends StatelessWidget {
  final String phase;
  final ValueChanged<String> onPhaseChanged;
  final int trimester;
  final ValueChanged<int> onTrimesterChanged;
  const _PhaseSection({
    required this.phase,
    required this.onPhaseChanged,
    required this.trimester,
    required this.onTrimesterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return _Section(
      title: l10n.settingsSectionPhase,
      info: InfoButton(
        fact: phase == 'pregnant'
            ? energyPregnancyFact(l10n)
            : energyLactationFact(l10n),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhaseChoice(
            value: 'lactating',
            label: l10n.settingsPhaseLactating,
            subtitle: l10n.settingsPhaseLactatingHint,
            selected: phase == 'lactating',
            onTap: () => onPhaseChanged('lactating'),
          ),
          _PhaseChoice(
            value: 'pregnant',
            label: l10n.settingsPhasePregnant,
            subtitle: l10n.settingsPhasePregnantHint,
            selected: phase == 'pregnant',
            onTap: () => onPhaseChanged('pregnant'),
          ),
          _PhaseChoice(
            value: 'neither',
            label: l10n.settingsPhaseNeither,
            subtitle: l10n.settingsPhaseNeitherHint,
            selected: phase == 'neither',
            onTap: () => onPhaseChanged('neither'),
          ),
          if (phase == 'pregnant') ...[
            const SizedBox(height: 12),
            Text(l10n.settingsPhaseTrimester, style: textTheme.bodyMedium),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1. T')),
                  ButtonSegment(value: 2, label: Text('2. T')),
                  ButtonSegment(value: 3, label: Text('3. T')),
                ],
                selected: {trimester},
                showSelectedIcon: false,
                onSelectionChanged: (s) => onTrimesterChanged(s.first),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhaseChoice extends StatelessWidget {
  final String value;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _PhaseChoice({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? scheme.primary : scheme.outline,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFields extends StatelessWidget {
  final DateTime birthdate;
  final VoidCallback onBirthdateTap;
  final TextEditingController height;
  final FocusNode heightFocus;
  final TextEditingController weight;
  final FocusNode weightFocus;
  // Surfaced ONLY when the user has changed the weight value: lets them
  // log "I weighed myself this morning" with this morning's date instead
  // of the default DateTime.now() of the save moment. weightRecordedAt
  // is the picked override (or null = default to now); onPickWeightDate
  // opens the date picker.
  final bool weightChanged;
  final DateTime? weightRecordedAt;
  final VoidCallback onPickWeightDate;
  const _ProfileFields({
    required this.birthdate,
    required this.onBirthdateTap,
    required this.height,
    required this.heightFocus,
    required this.weight,
    required this.weightFocus,
    required this.weightChanged,
    required this.weightRecordedAt,
    required this.onPickWeightDate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        InkWell(
          onTap: onBirthdateTap,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).settingsFieldBirthdate,
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              intl.DateFormat.yMd(
                Localizations.localeOf(context).toLanguageTag(),
              ).format(birthdate),
              style: textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: height,
                focusNode: heightFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                // iOS numeric keyboard has no "Done" button - without an
                // explicit dismiss the user is trapped in the field and
                // the FocusLost-tied auto-save never fires. Tap-outside
                // unfocuses, which lets the keyboard close, the focus
                // listener trigger, and the Undo snack appear.
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).settingsFieldHeight,
                  border: const OutlineInputBorder(),
                  suffixText:
                      AppLocalizations.of(context).settingsFieldHeightSuffix,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: weight,
                focusNode: weightFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).settingsFieldWeight,
                  border: const OutlineInputBorder(),
                  suffixText:
                      AppLocalizations.of(context).settingsFieldWeightSuffix,
                ),
              ),
            ),
          ],
        ),
        if (weightChanged) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onPickWeightDate,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_outlined,
                        size: 16, color: scheme.outline),
                    const SizedBox(width: 6),
                    Text(
                      _weightDateLabel(context, weightRecordedAt),
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _weightDateLabel(BuildContext context, DateTime? picked) {
    final l10n = AppLocalizations.of(context);
    final date = picked ?? DateTime.now();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final delta = today.difference(day).inDays;
    final base = delta == 0
        ? l10n.todayHeader
        : delta == 1
            ? l10n.yesterdayHeader
            : '${date.day}.${date.month}.${date.year}';
    return l10n.settingsWeightLoggedOn(base);
  }
}

class _ActivitySection extends StatelessWidget {
  final double activityFactor;
  final ValueChanged<double> onChanged;
  const _ActivitySection({
    required this.activityFactor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final labels = activityLabelsOf(l10n);
    return _Section(
      title: l10n.settingsSectionActivity,
      info: InfoButton(
        fact: NutritionFact(
          topic: l10n.settingsSectionActivity,
          summary: l10n.settingsActivityInfoSummary,
          detail: l10n.settingsActivityInfoDetail,
          source: l10n.settingsActivityInfoSource,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<double>(
              // Tighter padding + single-line labels so the longest label
              // ("Medium" / "Mäßig") fits one segment on narrow phones
              // instead of wrapping mid-word.
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              ),
              segments: ActivityLevel.allFor(labels)
                  .map((l) => ButtonSegment(
                        value: l.factor,
                        label: Text(l.label,
                            maxLines: 1, softWrap: false, overflow: TextOverflow.visible),
                      ))
                  .toList(),
              selected: {ActivityLevel.closestTo(activityFactor, labels).factor},
              showSelectedIcon: false,
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ActivityLevel.closestTo(activityFactor, labels).hint,
            style: textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

class _RemindersSection extends ConsumerStatefulWidget {
  const _RemindersSection();

  @override
  ConsumerState<_RemindersSection> createState() => _RemindersSectionState();
}

class _RemindersSectionState extends ConsumerState<_RemindersSection> {
  ReminderSettings? _settings;

  @override
  void initState() {
    super.initState();
    _settings = ref.read(settingsRepositoryProvider).getReminders();
  }

  Future<void> _persist() async {
    final s = _settings!;
    await ref.read(settingsRepositoryProvider).saveReminders(s);
    if (!mounted) return;
    await NotificationScheduler.rescheduleFor(s, AppLocalizations.of(context));
  }

  Future<void> _onMasterToggled(bool on) async {
    if (on) {
      final granted = await NotificationScheduler.requestPermissions();
      if (!mounted) return;
      if (!granted) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).reminderPermissionBlocked),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    setState(() {
      _settings = _settings!.copyWith(masterEnabled: on);
    });
    await _persist();
  }

  Future<void> _onEntryToggled(ReminderEntry entry, bool on) async {
    setState(() {
      _settings = _settings!.withEntry(entry.copyWith(enabled: on));
    });
    await _persist();
  }

  Future<void> _onTimeTap(ReminderEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: entry.time,
      helpText: '${ReminderCopy.label(entry.slot, l10n)} um …',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _settings = _settings!.withEntry(
          entry.copyWith(hour: picked.hour, minute: picked.minute));
    });
    await _persist();
  }

  String _formatTime(ReminderEntry e) =>
      '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = _settings ?? ReminderSettings.defaults;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return _Section(
      title: l10n.settingsSectionReminders,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsReminderToggleTitle,
                        style: textTheme.bodyLarge
                            ?.copyWith(color: scheme.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.masterEnabled
                            ? l10n.settingsReminderToggleOn
                            : l10n.settingsReminderToggleOff,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: s.masterEnabled,
                  onChanged: _onMasterToggled,
                ),
              ],
            ),
          ),
          if (s.masterEnabled) ...[
            const SizedBox(height: 4),
            for (var i = 0; i < s.entries.length; i++) ...[
              if (i > 0) Divider(color: scheme.outlineVariant, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ReminderCopy.label(s.entries[i].slot,
                            AppLocalizations.of(context)),
                        // Align with the rest of Settings: row labels for
                        // tappable choices (phase, theme, reminders, diet)
                        // are bodyMedium w600. Was bodyLarge here, which
                        // made the meal-reminder rows visually mismatch the
                        // phase/theme choice rows.
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: s.entries[i].enabled
                              ? scheme.onSurface
                              : scheme.outline,
                        ),
                      ),
                    ),
                    // Time chip: clearly tappable when enabled, dim when off.
                    Material(
                      color: s.entries[i].enabled
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: s.entries[i].enabled
                            ? () => _onTimeTap(s.entries[i])
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          child: Text(
                            _formatTime(s.entries[i]),
                            style: textTheme.labelLarge?.copyWith(
                              color: s.entries[i].enabled
                                  ? scheme.onPrimaryContainer
                                  : scheme.outline,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: s.entries[i].enabled,
                      onChanged: (on) =>
                          _onEntryToggled(s.entries[i], on),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ThemeSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);

    void setMode(ThemeMode mode) {
      ref.read(themeModeProvider.notifier).state = mode;
      final asString = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      ref.read(settingsRepositoryProvider).setThemeMode(asString);
    }

    Widget choice(String label, String subtitle, ThemeMode mode) {
      final selected = themeMode == mode;
      return InkWell(
        onTap: () => setMode(mode),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? scheme.primary : scheme.outline,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    return _Section(
      title: l10n.settingsSectionTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          choice(l10n.themeSystem, l10n.themeSystemHint, ThemeMode.system),
          choice(l10n.themeLight, l10n.themeLightHint, ThemeMode.light),
          choice(l10n.themeDark, l10n.themeDarkHint, ThemeMode.dark),
        ],
      ),
    );
  }
}

class _PrivacySection extends ConsumerStatefulWidget {
  const _PrivacySection();

  @override
  ConsumerState<_PrivacySection> createState() => _PrivacySectionState();
}

class _PrivacySectionState extends ConsumerState<_PrivacySection> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    // New opt-in model (#83): enabled iff the user has an analytics
    // consent timestamp from onboarding or from this toggle.
    _enabled =
        ref.read(settingsRepositoryProvider).getAnalyticsConsentAt() != null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return _Section(
      title: l10n.settingsSectionPrivacy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsAnalyticsToggle),
            value: _enabled,
            onChanged: (v) {
              setState(() => _enabled = v);
              final repo = ref.read(settingsRepositoryProvider);
              if (v) {
                repo.setAnalyticsConsentAt(DateTime.now());
              } else {
                repo.clearAnalyticsConsent();
              }
            },
          ),
          Text(
            l10n.settingsAnalyticsHint,
            style: textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
          // Health-data consent revocation hint (no toggle - revocation
          // means "you can't use the app any more", which is the App-
          // zurücksetzen flow elsewhere in Settings). Keep the user
          // aware that the choice exists; an explicit toggle here
          // would invite accidental self-bricking.
          const SizedBox(height: 12),
          Text(
            l10n.settingsHealthDataConsentHint,
            style: textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

class _MilkSection extends StatelessWidget {
  final int numChildren;
  final ValueChanged<int> onChildrenChanged;
  final int ageGroup;
  final ValueChanged<int> onAgeChanged;
  // Optional youngest-child birth date. When set, the segmented bucket
  // picker becomes read-only - the bucket is derived from this date and
  // re-derives itself as time passes.
  final DateTime? youngestChildBirthdate;
  final VoidCallback onPickBirthdate;
  final VoidCallback onClearBirthdate;
  final int sharePercent;
  final ValueChanged<int> onShareChanged;
  // Per-child shares + handler (multiples only).
  final List<int>? perChildSharesPercent;
  final ValueChanged<List<int>?> onPerChildSharesChanged;
  final int dailyVolumeMl;
  final ValueChanged<int> onVolumeChanged;

  const _MilkSection({
    required this.numChildren,
    required this.onChildrenChanged,
    required this.ageGroup,
    required this.onAgeChanged,
    required this.youngestChildBirthdate,
    required this.onPickBirthdate,
    required this.onClearBirthdate,
    required this.sharePercent,
    required this.onShareChanged,
    required this.perChildSharesPercent,
    required this.onPerChildSharesChanged,
    required this.dailyVolumeMl,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return _Section(
      title: l10n.settingsSectionMilk,
      info: InfoButton(fact: energyLactationFact(l10n)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsMilkChildren,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('0')),
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 4, label: Text('4')),
              ],
              selected: {numChildren},
              showSelectedIcon: false,
              onSelectionChanged: (s) => onChildrenChanged(s.first),
            ),
          ),
          if (numChildren > 0) ...[
            const SizedBox(height: 16),
            Text(
              numChildren == 1
                  ? l10n.settingsMilkChildSingular
                  : l10n.settingsMilkChildPlural,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            ChildAgeInput(
              bucket: ageGroup,
              onBucketChanged: onAgeChanged,
              birthdate: youngestChildBirthdate,
              onPickBirthdate: onPickBirthdate,
              onClearBirthdate: onClearBirthdate,
            ),
            const SizedBox(height: 16),
            MilkShareSelector(
              sharePercent: sharePercent,
              numChildren: numChildren,
              onChanged: onShareChanged,
              perChildShares: perChildSharesPercent,
              onPerChildChanged: onPerChildSharesChanged,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(l10n.settingsMilkVolume,
                      style: textTheme.bodyMedium),
                ),
                InfoButton(
                  fact: NutritionFact(
                    topic: l10n.settingsMilkVolumeInfoTopic,
                    summary: l10n.settingsMilkVolumeInfoTitle,
                    detail: '${l10n.settingsMilkVolumeInfoSummary} '
                        '${l10n.settingsMilkVolumeInfoDetail}',
                    source: l10n.settingsMilkVolumeInfoSource,
                  ),
                ),
              ],
            ),
            Slider(
              value: dailyVolumeMl.toDouble().clamp(0, 3000),
              min: 0,
              max: 3000,
              divisions: 60,
              label: '$dailyVolumeMl ml',
              onChanged: (v) => onVolumeChanged(v.round()),
            ),
            Text(
              l10n.settingsMilkVolumePerDayLabel(
                dailyVolumeMl,
                UserProfileSettings.volumeBasedSupplement(dailyVolumeMl),
              ),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
            MilkVolumeAgeHint(
              ageGroup: ageGroup,
              numChildren: numChildren,
            ),
          ],
        ],
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  final UserProfileSettings profile;
  const _OutcomeCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final bmrTdee = calculateBmrTdee(profile);
    final pregSupp = calculatePregnancySupplement(profile);
    final lactSupp = calculateLactationSupplement(profile);
    final total = bmrTdee + pregSupp + lactSupp;

    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsTodayTarget,
              style: textTheme.titleSmall?.copyWith(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                letterSpacing: 0.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatKcal(total)} kcal',
              style: textTheme.displaySmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _OutcomeRow(
              label: l10n.settingsOutcomeBase,
              value: '${formatKcal(bmrTdee)} kcal',
              color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
              textTheme: textTheme,
            ),
            if (pregSupp > 0)
              _OutcomeRow(
                label: l10n.settingsOutcomePregnancy(profile.trimester ?? 0),
                value: '+${formatKcal(pregSupp)} kcal',
                color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                textTheme: textTheme,
              ),
            if (lactSupp > 0)
              _OutcomeRow(
                label: l10n.settingsOutcomeLactation,
                value: '+${formatKcal(lactSupp)} kcal',
                color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                textTheme: textTheme,
              ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final TextTheme textTheme;
  const _OutcomeRow({
    required this.label,
    required this.value,
    required this.color,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroSplitSection extends StatelessWidget {
  final UserProfileSettings profile;
  final int proteinPct; // 0 = use auto
  final int fatPct; // 0 = use auto
  final ValueChanged<int> onProteinChanged;
  final ValueChanged<int> onFatChanged;
  final VoidCallback onReset;

  const _MacroSplitSection({
    required this.profile,
    required this.proteinPct,
    required this.fatPct,
    required this.onProteinChanged,
    required this.onFatChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final targetKcal = calculateDailyCalorieTarget(profile);
    final auto = autoMacroSplit(profile, targetKcal);
    final pPct = proteinPct > 0 ? proteinPct : auto.proteinPct;
    final fPct = fatPct > 0 ? fatPct : auto.fatPct;
    final cPct = (100 - pPct - fPct).clamp(0, 100);
    final pIsAuto = proteinPct == 0;
    final fIsAuto = fatPct == 0;
    final pGrams = (targetKcal * pPct / 100 / 4).round();
    final fGrams = (targetKcal * fPct / 100 / 9).round();
    final cGrams = (targetKcal * cPct / 100 / 4).round();
    final pKcal = pGrams * 4;
    final fKcal = fGrams * 9;
    final cKcal = cGrams * 4;
    final isCustom = !pIsAuto || !fIsAuto;
    // Fat slider has to leave at least 5 % for carbs after subtracting protein.
    final fatMax = (100 - pPct - 5).clamp(10, 60);

    final l10n = AppLocalizations.of(context);
    return _Section(
      title: l10n.settingsMacroTitle,
      info: InfoButton(
        fact: NutritionFact(
          topic: l10n.settingsMacroTitle,
          summary: l10n.settingsMacroInfoSummary,
          detail: l10n.settingsMacroInfoDetail,
          source: 'DGE 2025',
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MacroSlider(
            label: l10n.settingsMacroProtein,
            pct: pPct,
            min: 5,
            max: 50,
            isAuto: pIsAuto,
            autoPct: auto.proteinPct,
            grams: pGrams,
            kcal: pKcal,
            color: scheme.primary,
            onChanged: onProteinChanged,
          ),
          const SizedBox(height: 4),
          _MacroSlider(
            label: l10n.settingsMacroFat,
            pct: fPct,
            min: 10,
            max: fatMax,
            isAuto: fIsAuto,
            autoPct: auto.fatPct,
            grams: fGrams,
            kcal: fKcal,
            color: scheme.primary,
            onChanged: onFatChanged,
          ),
          const SizedBox(height: 12),
          // Carbs are the remainder, not interactive. Render with the same
          // visual structure as Protein/Fett so the three rows read uniformly.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.settingsMacroCarbsRemainder,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  l10n.settingsMacroSliderValue(cPct, cGrams, cKcal),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (isCustom) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.settingsMacroResetAuto),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroSlider extends StatelessWidget {
  final String label;
  final int pct;
  final int min;
  final int max;
  final bool isAuto;
  final int autoPct;
  final int grams;
  final int kcal;
  final Color color;
  final ValueChanged<int> onChanged;

  const _MacroSlider({
    required this.label,
    required this.pct,
    required this.min,
    required this.max,
    required this.isAuto,
    required this.autoPct,
    required this.grams,
    required this.kcal,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                    children: [
                      TextSpan(text: '$label '),
                      TextSpan(
                        text: l10n.settingsMacroAutoLabel(autoPct),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                l10n.settingsMacroSliderValue(pct, grams, kcal),
                style: textTheme.bodySmall?.copyWith(
                  color: isAuto ? scheme.outline : scheme.primary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        Slider(
          value: pct.toDouble().clamp(min.toDouble(), max.toDouble()),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '$pct %',
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}

// Maps a canonical DietStyle / DietRestrictions ID to its localized label.
String _dietStyleLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case DietStyle.vegetarian:
      return l10n.dietStyleVegetarian;
    case DietStyle.vegan:
      return l10n.dietStyleVegan;
    case DietStyle.pescatarian:
      return l10n.dietStylePescatarian;
    case DietStyle.omnivore:
    default:
      return l10n.dietStyleOmnivore;
  }
}

String _restrictionLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case DietRestrictions.lactose:
      return l10n.restrictionLactose;
    case DietRestrictions.gluten:
      return l10n.restrictionGluten;
    case DietRestrictions.eggs:
      return l10n.restrictionEggs;
    case DietRestrictions.nuts:
      return l10n.restrictionNuts;
    case DietRestrictions.fish:
      return l10n.restrictionFish;
    case DietRestrictions.shellfish:
      return l10n.restrictionShellfish;
    case DietRestrictions.soy:
      return l10n.restrictionSoy;
    default:
      return id;
  }
}

class _DietSection extends StatelessWidget {
  final String dietStyle;
  final ValueChanged<String> onDietStyleChanged;
  final Set<String> restrictions;
  final void Function(String tag, bool picked) onRestrictionToggled;
  final TextEditingController notesController;
  final FocusNode notesFocus;
  // True when the user is currently pregnant OR lactating. Drives the
  // vegan-supplementation hint banner shown beneath the diet chips - the
  // overlap of "vegan" + this phase is where the dietitian flagged a
  // real risk of micronutrient gaps.
  final bool isInPhase;
  const _DietSection({
    required this.dietStyle,
    required this.onDietStyleChanged,
    required this.restrictions,
    required this.onRestrictionToggled,
    required this.notesController,
    required this.notesFocus,
    required this.isInPhase,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final showVeganHint = dietStyle == DietStyle.vegan && isInPhase;
    return _Section(
      title: l10n.settingsSectionDiet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // No "Diet style" label here: the section heading already says
          // "Diet & allergies" and the style chips are self-explanatory.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in DietStyle.all)
                ChoiceChip(
                  label: Text(_dietStyleLabel(l10n, id)),
                  selected: dietStyle == id,
                  onSelected: (_) => onDietStyleChanged(id),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (showVeganHint) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: scheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.settingsDietVeganPhaseHint,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.settingsDietRestrictionsLabel,
              style: textTheme.bodyMedium),
          const SizedBox(height: 2),
          Text(l10n.settingsDietRestrictionsHint,
              style: textTheme.bodySmall?.copyWith(color: scheme.outline)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in DietRestrictions.all)
                FilterChip(
                  label: Text(_restrictionLabel(l10n, tag)),
                  selected: restrictions.contains(tag),
                  onSelected: (picked) => onRestrictionToggled(tag, picked),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: notesController,
            focusNode: notesFocus,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onTapOutside: (_) =>
                FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              labelText: l10n.settingsDietNotesLabel,
              hintText: l10n.settingsDietNotesHint,
              hintStyle: TextStyle(color: scheme.outline),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesSection extends ConsumerWidget {
  const _FavoritesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider).valueOrNull ??
        const <FavoriteMeal>[];
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _Section(
      title: AppLocalizations.of(context).settingsSectionFavorites,
      child: favorites.isEmpty
          // Compact one-line hint instead of the large illustrated empty
          // state, which took too much room inside this settings card.
          ? Row(
              children: [
                Icon(Icons.star_outline_rounded,
                    size: 18, color: scheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).emptyFavoritesBody,
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in favorites)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.star_rounded,
                      color: scheme.secondary,
                    ),
                    title: Text(f.summary),
                    subtitle: Text(
                      '${f.kcal} kcal · ${f.portionAmount.toStringAsFixed(0)} ${f.portionUnit}',
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.outline),
                    ),
                    // Convention: edit_outlined (via EditHintIcon) for
                    // rows whose tap opens an edit sheet; chevron_right
                    // is reserved for drill-into-a-page navigation.
                    trailing: const EditHintIcon(),
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        showDragHandle: true,
                        builder: (_) => FavoriteEditSheet(favorite: f),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}


class _MicronutrientsSection extends StatelessWidget {
  // null → user follows phase/diet defaults; non-null → explicit pick
  // (possibly empty if the user wants to hide micros entirely). The cap
  // of 3 is enforced by the toggle handler in the screen state, not here.
  final List<String>? selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onReset;
  const _MicronutrientsSection({
    required this.selected,
    required this.onToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final picked = selected ?? const <String>[];
    final atMax = picked.length >= 3;
    final usingDefaults = selected == null;

    return _Section(
      title: l10n.settingsSectionMicronutrients,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsMicrosDescription,
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          // Sort the toggle list alphabetically by display name (Vanessa
          // Build+28 feedback: should match the trends + diary header
          // ordering for predictability).
          for (final key in ([...MicronutrientKey.all]..sort((a, b) =>
              _displayNameFor(a, locale)
                  .toLowerCase()
                  .compareTo(_displayNameFor(b, locale).toLowerCase()))))
            _MicroToggleRow(
              displayName: _displayNameFor(key, locale),
              isOn: picked.contains(key),
              isDisabled: !picked.contains(key) && atMax,
              onTap: () => onToggle(key),
            ),
          const SizedBox(height: 4),
          Text(
            usingDefaults
                ? l10n.settingsMicrosUsingDefaults
                : atMax
                    ? l10n.settingsMicrosMaxReached
                    : '${picked.length} / 3',
            style: textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
          if (!usingDefaults) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.settingsMicrosReset),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _displayNameFor(String key, String locale) {
    final d = MicronutrientDisplay.forKey(key);
    return d?.nameForLocale(locale) ?? key;
  }
}

class _GoalSection extends StatelessWidget {
  final String goal;
  final ValueChanged<String> onChanged;
  const _GoalSection({required this.goal, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return _Section(
      title: l10n.settingsSectionGoal,
      info: InfoButton(fact: goalFact(l10n)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsGoalHint,
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                    value: CoachGoal.nutrients,
                    label: Text(l10n.settingsGoalNutrients)),
                ButtonSegment(
                    value: CoachGoal.body,
                    label: Text(l10n.settingsGoalBody)),
                ButtonSegment(
                    value: CoachGoal.both,
                    label: Text(l10n.settingsGoalBoth)),
              ],
              selected: {goal},
              showSelectedIcon: false,
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: goal == CoachGoal.nutrients
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.fitness_center,
                              size: 16, color: scheme.onPrimaryContainer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.settingsGoalMacroImplication,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onPrimaryContainer,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Meal-pattern picker (#108). Lives in the Coach Settings hub right under
// the goal selector. RadioListTile-based instead of SegmentedButton because
// the four labels (e.g. "3 Hauptmahlzeiten + 2 Snacks") wrap on smaller
// screens; vertical radio rows scale better.
class _MealPatternSection extends StatelessWidget {
  final String pattern;
  final ValueChanged<String> onChanged;
  const _MealPatternSection({required this.pattern, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final options = <(String, String)>[
      (MealPattern.classic, l10n.settingsMealPatternClassic),
      (MealPattern.oneSnack, l10n.settingsMealPatternOneSnack),
      (MealPattern.threeMeals, l10n.settingsMealPatternThreeMeals),
      (MealPattern.intuitive, l10n.settingsMealPatternIntuitive),
    ];
    return _Section(
      title: l10n.settingsMealPatternTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsMealPatternHint,
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          RadioGroup<String>(
            groupValue: pattern,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (value, label) in options)
                  InkWell(
                    onTap: () => onChanged(value),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Radio<String>(value: value),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(label, style: textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplementSection extends StatelessWidget {
  final List<ActiveSupplement> supplements;
  final VoidCallback onAdd;
  final void Function(int index, ActiveSupplement edited) onEdit;
  final void Function(int index) onRemove;
  // Phase signal so we can show the "in this phase a supplement is often
  // critical"-nudge when the list is empty AND the user is pregnant or
  // producing milk (Task #101). For non-pregnant non-lactating users the
  // empty state stays silent.
  final bool phaseRequiresSupplement;
  const _SupplementSection({
    required this.supplements,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.phaseRequiresSupplement,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return _Section(
      title: l10n.supplementSectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (supplements.isEmpty && phaseRequiresSupplement) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medication_outlined,
                      size: 18, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.settingsSupplementMissingHint,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          for (var i = 0; i < supplements.length; i++) ...[
            _SupplementListItem(
              supplement: supplements[i],
              onEdit: () async {
                final edited =
                    await showSupplementEditSheet(context, supplements[i]);
                if (edited != null) onEdit(i, edited);
              },
              onRemove: () => onRemove(i),
            ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text(supplements.isEmpty
                  ? l10n.supplementAddCta
                  : l10n.supplementAddAnotherCta),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplementListItem extends StatelessWidget {
  final ActiveSupplement supplement;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  const _SupplementListItem({
    required this.supplement,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplement.name,
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      l10n.supplementCurrentDoses(supplement.dosesPerDay),
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.outline),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: l10n.supplementEdit,
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: l10n.supplementRemove,
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          if (supplement.values.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in supplement.values.entries)
                  _SupplementValueChip(nutrientKey: e.key, value: e.value),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SupplementValueChip extends StatelessWidget {
  final String nutrientKey;
  final double value;
  const _SupplementValueChip({required this.nutrientKey, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display = MicronutrientDisplay.forKey(nutrientKey);
    final locale = Localizations.localeOf(context).languageCode;
    final label = display?.nameForLocale(locale) ?? nutrientKey;
    final unit = display?.unitLabel ?? '';
    final vStr = value >= 50
        ? value.round().toString()
        : value == value.roundToDouble()
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label $vStr $unit',
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MicroToggleRow extends StatelessWidget {
  final String displayName;
  final bool isOn;
  final bool isDisabled;
  final VoidCallback onTap;
  const _MicroToggleRow({
    required this.displayName,
    required this.isOn,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              isOn ? Icons.check_box : Icons.check_box_outline_blank,
              size: 22,
              color: isDisabled
                  ? scheme.outlineVariant
                  : isOn
                      ? scheme.primary
                      : scheme.outline,
            ),
            const SizedBox(width: 12),
            Text(
              displayName,
              style: TextStyle(
                color: isDisabled ? scheme.outlineVariant : scheme.onSurface,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
