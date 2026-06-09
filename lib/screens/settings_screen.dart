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
import '../widgets/info_button.dart';
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
  late int _childrenAgeGroup;
  late int _dailyVolumeMl;
  // Birth date of the youngest nursing child; null = bucket-picker is the
  // source of truth, otherwise it's derived from this and the picker shown
  // read-only.
  DateTime? _youngestChildBirthdate;
  // Coach focus: 'nutrients' (default), 'body', or 'both'.
  late String _goal;
  // Hand-picked micronutrient subset for the diary header. null = follow
  // phase/diet defaults; non-null overrides them (capped at 3 by the UI).
  List<String>? _selectedMicros;
  bool _initialized = false;
  String? _initialProfileJson;
  bool _justSaved = false;

  @override
  void dispose() {
    if (_initialized) {
      _height.dispose();
      _weight.dispose();
      _dietaryNotes.dispose();
    }
    super.dispose();
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
    _initialProfileJson = jsonEncode(p.toJson());

    for (final c in [_height, _weight, _dietaryNotes]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
    _initialized = true;
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
      // Allow up to 3 years back — past 12 months the user is out of the
      // milk-volume estimation buckets anyway, but we don't gate on that.
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      helpText: AppLocalizations.of(context).settingsMilkBirthdatePickerHelp,
    );
    if (picked != null) {
      setState(() {
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

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate,
      firstDate: DateTime(now.year - 80),
      lastDate: now,
      helpText: AppLocalizations.of(context).settingsBirthdatePickerHelp,
    );
    if (picked != null) setState(() => _birthdate = picked);
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
      );

  void _onSharePercentChanged(int v) {
    setState(() {
      _milkSharePercent = v;
      _dailyVolumeMl = UserProfileSettings.estimatedDailyVolumeMl(
        numChildren: _numChildren,
        ageGroup: _childrenAgeGroup,
        sharePercent: v,
      );
    });
  }

  void _onNumChildrenChanged(int v) {
    setState(() {
      _numChildren = v;
      _dailyVolumeMl = UserProfileSettings.estimatedDailyVolumeMl(
        numChildren: v,
        ageGroup: _childrenAgeGroup,
        sharePercent: _milkSharePercent,
      );
    });
  }

  void _onAgeGroupChanged(int v) {
    setState(() {
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
    setState(() {
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
    setState(() {
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

  bool get _isDirty {
    if (_initialProfileJson == null) return false;
    return jsonEncode(_currentProfile().toJson()) != _initialProfileJson;
  }

  Future<bool> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDiscardTitle),
        content: Text(l10n.confirmDiscardBody),
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
            child: Text(l10n.confirmDiscardConfirm),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final newProfile = _currentProfile();
    await ref.read(settingsRepositoryProvider).saveProfile(newProfile);
    // Record a weight history entry whenever the value differs from the
    // last save. profile.weightKg keeps driving BMR; this log accumulates
    // for the Trends-tab line chart.
    final initial = _initialProfileJson;
    final prevWeight = initial == null
        ? null
        : (jsonDecode(initial) as Map<String, dynamic>)['weightKg'] as num?;
    if (prevWeight == null || prevWeight.toDouble() != newProfile.weightKg) {
      await ref.read(weightRepositoryProvider).save(WeightEntry(
            id: 'w-${DateTime.now().microsecondsSinceEpoch}',
            weightKg: newProfile.weightKg,
            recordedAt: DateTime.now(),
          ));
      ref.read(analyticsServiceProvider).capture('weight_logged',
          properties: {'source': 'settings'});
    }
    if (!mounted) return;
    ref.invalidate(userProfileProvider);
    _justSaved = true;
    Navigator.pop(context);
    // Surface confirmation on the parent scaffold (Verlauf / Tagebuch) so the
    // user lands back, sees the updated kcal/macros toolbar AND a brief
    // "Gespeichert" cue tying the two together.
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(l10n.settingsSavedSnackbar),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        return PopScope(
          canPop: _justSaved || !_isDirty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final navigator = Navigator.of(context);
            final discard = await _confirmDiscard();
            if (discard && mounted) {
              _justSaved = true; // bypass second confirm if any
              navigator.pop();
            }
          },
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context).settingsTitle),
                centerTitle: false,
              ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _OutcomeCard(profile: _currentProfile()),
                const SizedBox(height: 16),
                _PhaseSection(
                  phase: _phase,
                  onPhaseChanged: (v) => setState(() => _phase = v),
                  trimester: _trimester,
                  onTrimesterChanged: (v) => setState(() => _trimester = v),
                ),
                const SizedBox(height: 12),
                _GoalSection(
                  goal: _goal,
                  onChanged: (v) => setState(() => _goal = v),
                ),
                const SizedBox(height: 12),
                _Section(
                  title: AppLocalizations.of(context).settingsSectionProfile,
                  child: _ProfileFields(
                    birthdate: _birthdate,
                    onBirthdateTap: _pickBirthdate,
                    height: _height,
                    weight: _weight,
                  ),
                ),
                const SizedBox(height: 12),
                _ActivitySection(
                  activityFactor: _activityFactor,
                  onChanged: (v) => setState(() => _activityFactor = v),
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
                        setState(() => _youngestChildBirthdate = null),
                    sharePercent: _milkSharePercent,
                    onShareChanged: _onSharePercentChanged,
                    dailyVolumeMl: _dailyVolumeMl,
                    onVolumeChanged: (v) => setState(() => _dailyVolumeMl = v),
                  ),
                ],
                const SizedBox(height: 12),
                _MacroSplitSection(
                  profile: _currentProfile(),
                  proteinPct: _customProteinPct,
                  fatPct: _customFatPct,
                  onProteinChanged: _onProteinPctChanged,
                  onFatChanged: _onFatPctChanged,
                  onReset: () => setState(() {
                    _customProteinPct = 0;
                    _customFatPct = 0;
                  }),
                ),
                const SizedBox(height: 12),
                _DietSection(
                  dietStyle: _dietStyle,
                  onDietStyleChanged: (v) => setState(() => _dietStyle = v),
                  restrictions: _restrictions,
                  onRestrictionToggled: (tag, picked) {
                    setState(() {
                      if (picked) {
                        _restrictions = {..._restrictions, tag};
                      } else {
                        _restrictions = {..._restrictions}..remove(tag);
                      }
                    });
                  },
                  notesController: _dietaryNotes,
                ),
                const SizedBox(height: 12),
                _MicronutrientsSection(
                  selected: _selectedMicros,
                  onToggle: (key) {
                    setState(() {
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
                  onReset: () => setState(() => _selectedMicros = null),
                ),
                const SizedBox(height: 12),
                const _FavoritesSection(),
                const SizedBox(height: 16),
                const _RemindersSection(),
                const SizedBox(height: 16),
                _ThemeSection(),
                const SizedBox(height: 16),
                const _PrivacySection(),
                const SizedBox(height: 16),
                // Lets the user revisit the first-run tips deck. The deck
                // sets hasSeenTipsV1 on dismiss, so launching it from here
                // simply re-runs the same screen.
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TipsScreen()),
                  ),
                  icon: const Icon(Icons.lightbulb_outline),
                  label:
                      Text(AppLocalizations.of(context).settingsButtonShowTips),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => FeedbackSender.openFeedbackMail(
                    AppLocalizations.of(context),
                  ),
                  icon: const Icon(Icons.mail_outline),
                  label: Text(AppLocalizations.of(context).settingsButtonFeedback),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _resetApp,
                  icon: const Icon(Icons.restore_outlined),
                  label: Text(AppLocalizations.of(context).settingsButtonReset),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor:
                        Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error.withValues(
                            alpha: 0.5,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(AppLocalizations.of(context).settingsButtonSave),
                ),
              ),
            ),
            ),
          ),
        );
      },
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
                      fontWeight: FontWeight.w700,
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
  final TextEditingController weight;
  const _ProfileFields({
    required this.birthdate,
    required this.onBirthdateTap,
    required this.height,
    required this.weight,
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
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
      ],
    );
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
    _enabled = !ref.read(settingsRepositoryProvider).getAnalyticsOptOut();
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
              ref.read(settingsRepositoryProvider).setAnalyticsOptOut(!v);
            },
          ),
          Text(
            l10n.settingsAnalyticsHint,
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
  // picker becomes read-only — the bucket is derived from this date and
  // re-derives itself as time passes.
  final DateTime? youngestChildBirthdate;
  final VoidCallback onPickBirthdate;
  final VoidCallback onClearBirthdate;
  final int sharePercent;
  final ValueChanged<int> onShareChanged;
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
    required this.dailyVolumeMl,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final ageLabels = childAgeLabelsOf(l10n);
    final ageGroups = ChildAgeGroup.allFor(ageLabels);
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
          _NumberStepper(
            value: numChildren,
            min: 0,
            max: 4,
            onChanged: onChildrenChanged,
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
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: List.generate(
                  ageGroups.length,
                  (i) => ButtonSegment(
                    value: i,
                    label: Text(ageGroups[i].label),
                  ),
                ),
                selected: {ageGroup},
                showSelectedIcon: false,
                // Bucket is derived from birth date when present; lock the
                // segmented picker so users can't accidentally desync it.
                onSelectionChanged: youngestChildBirthdate != null
                    ? null
                    : (s) => onAgeChanged(s.first),
              ),
            ),
            const SizedBox(height: 8),
            _BirthdateRow(
              birthdate: youngestChildBirthdate,
              onPick: onPickBirthdate,
              onClear: onClearBirthdate,
            ),
            const SizedBox(height: 16),
            Text(
              numChildren == 1
                  ? l10n.settingsMilkShareSingular(sharePercent)
                  : l10n.settingsMilkSharePlural(sharePercent),
              style: textTheme.bodyMedium,
            ),
            Slider(
              value: sharePercent.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '$sharePercent%',
              onChanged: (v) => onShareChanged(v.round()),
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
  const _DietSection({
    required this.dietStyle,
    required this.onDietStyleChanged,
    required this.restrictions,
    required this.onRestrictionToggled,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
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
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.done,
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
                    trailing: const Icon(Icons.chevron_right),
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

class _NumberStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _NumberStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Text(value.toString(), style: textTheme.headlineSmall),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
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
          for (final key in MicronutrientKey.all)
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
        ],
      ),
    );
  }
}

class _BirthdateRow extends StatelessWidget {
  final DateTime? birthdate;
  final VoidCallback onPick;
  final VoidCallback onClear;
  const _BirthdateRow({
    required this.birthdate,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final df = intl.DateFormat.yMd(
        Localizations.localeOf(context).languageCode);
    if (birthdate == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.cake_outlined, size: 18),
          label: Text(l10n.settingsMilkBirthdatePick),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${l10n.settingsMilkBirthdateLabel}: ${df.format(birthdate!)}',
                style: textTheme.bodyMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: l10n.settingsMilkBirthdatePick,
              onPressed: onPick,
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: l10n.settingsMilkBirthdateClear,
              onPressed: onClear,
            ),
          ],
        ),
        Text(
          l10n.settingsMilkBirthdateAuto,
          style: textTheme.bodySmall?.copyWith(color: scheme.outline),
        ),
      ],
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
