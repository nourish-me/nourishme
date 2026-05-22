import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../models/favorite_meal.dart';
import '../models/reminder_settings.dart';
import '../services/feedback_sender.dart';
import '../services/notification_scheduler.dart';
import '../models/user_profile_settings.dart';
import '../providers/meal_providers.dart';
import '../services/calorie_target.dart';
import '../services/nutrition_facts.dart';
import '../utils/number_format.dart';
import '../widgets/empty/empty_favorites.dart';
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
  bool _initialized = false;
  String? _initialProfileJson;
  bool _justSaved = false;

  @override
  void dispose() {
    if (_initialized) {
      _height.dispose();
      _weight.dispose();
    }
    super.dispose();
  }

  void _hydrate(UserProfileSettings p) {
    _birthdate = p.birthdate ?? UserProfileSettings.birthdateFromAge(p.ageYears);
    _height = TextEditingController(text: p.heightCm.toStringAsFixed(0));
    _weight = TextEditingController(text: p.weightKg.toStringAsFixed(1));
    _activityFactor = p.activityFactor;
    // Lactation wins if user has children; pregnant otherwise (or default lactating).
    _phase = p.numChildrenNursing > 0 ? 'lactating' : (p.isPregnant ? 'pregnant' : 'lactating');
    _trimester = p.trimester ?? 1;
    _numChildren = p.numChildrenNursing > 0 ? p.numChildrenNursing : 1;
    _milkSharePercent = p.milkSharePercent;
    _childrenAgeGroup = p.childrenAgeGroup;
    _dailyVolumeMl = p.dailyMilkVolumeMl > 0
        ? p.dailyMilkVolumeMl
        : UserProfileSettings.estimatedDailyVolumeMl(
            numChildren: _numChildren,
            ageGroup: _childrenAgeGroup,
            sharePercent: _milkSharePercent,
          );
    _customProteinPct = p.customProteinPct;
    _customFatPct = p.customFatPct;
    _initialProfileJson = jsonEncode(p.toJson());

    for (final c in [_height, _weight]) {
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

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate,
      firstDate: DateTime(now.year - 80),
      lastDate: now,
      helpText: 'Geburtsdatum wählen',
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
        dailyMilkVolumeMl: _isLactating ? _dailyVolumeMl : 0,
        milkSupplementKcal: 0,
        customProteinPct: _customProteinPct,
        customFatPct: _customFatPct,
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
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Änderungen verwerfen?'),
        content: const Text(
          'Deine ungespeicherten Änderungen gehen verloren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _save() async {
    await ref.read(settingsRepositoryProvider).saveProfile(_currentProfile());
    if (!mounted) return;
    ref.invalidate(userProfileProvider);
    _justSaved = true;
    Navigator.pop(context);
    // Surface confirmation on the parent scaffold (Verlauf / Tagebuch) so the
    // user lands back, sees the updated kcal/macros toolbar AND a brief
    // "Gespeichert" cue tying the two together.
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Profil gespeichert'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _resetApp() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('App zurücksetzen?'),
        content: const Text(
          'Alle Einträge, Favoriten und dein Profil werden gelöscht. '
          'Du startest danach mit dem Onboarding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(mealRepositoryProvider).clearAll();
    await ref.read(favoriteRepositoryProvider).clearAll();
    await ref.read(threadRepositoryProvider).clearAll();
    await ref.read(settingsRepositoryProvider).clearAll();
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
      error: (e, _) => Scaffold(body: Center(child: Text('Fehler: $e'))),
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
                title: const Text('Einstellungen'),
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
                _Section(
                  title: 'Dein Profil',
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
                const _FavoritesSection(),
                const SizedBox(height: 16),
                const _RemindersSection(),
                const SizedBox(height: 16),
                _ThemeSection(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => FeedbackSender.openFeedbackMail(),
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('Feedback senden'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _resetApp,
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text('App zurücksetzen'),
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
                  child: const Text('Speichern'),
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
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
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
    return _Section(
      title: 'Aktuelle Phase',
      info: InfoButton(
        fact: phase == 'pregnant'
            ? NutritionFacts.energyPregnancy
            : NutritionFacts.energyLactation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhaseChoice(
            value: 'lactating',
            label: 'Milchproduzierend',
            subtitle: 'Stillend oder pumpend',
            selected: phase == 'lactating',
            onTap: () => onPhaseChanged('lactating'),
          ),
          _PhaseChoice(
            value: 'pregnant',
            label: 'Schwanger',
            subtitle: 'Aktuell schwanger',
            selected: phase == 'pregnant',
            onTap: () => onPhaseChanged('pregnant'),
          ),
          if (phase == 'pregnant') ...[
            const SizedBox(height: 12),
            Text('Trimester', style: textTheme.bodyMedium),
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
            decoration: const InputDecoration(
              labelText: 'Geburtsdatum',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              '${birthdate.day.toString().padLeft(2, '0')}.'
              '${birthdate.month.toString().padLeft(2, '0')}.'
              '${birthdate.year}',
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
                decoration: const InputDecoration(
                  labelText: 'Größe',
                  border: OutlineInputBorder(),
                  suffixText: 'cm',
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
                decoration: const InputDecoration(
                  labelText: 'Gewicht',
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
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
    return _Section(
      title: 'Aktivitätslevel',
      info: const InfoButton(
        fact: NutritionFact(
          topic: 'Aktivitätslevel',
          summary: 'Skaliert den Grundbedarf (PAL-Faktor)',
          detail:
              'Gering 1,2: kaum Bewegung. Mäßig 1,375: Spaziergänge, leichte Hausarbeit. '
              'Aktiv 1,55: regelmäßiges Training. Hoch 1,725: intensives Training oder '
              'körperliche Arbeit. Bei Babys zu Hause meist "Mäßig".',
          source: 'DGE PAL-Klassifikation',
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<double>(
              segments: ActivityLevel.all
                  .map((l) =>
                      ButtonSegment(value: l.factor, label: Text(l.label)))
                  .toList(),
              selected: {ActivityLevel.closestTo(activityFactor).factor},
              showSelectedIcon: false,
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ActivityLevel.closestTo(activityFactor).hint,
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
    await NotificationScheduler.rescheduleFor(s);
  }

  Future<void> _onMasterToggled(bool on) async {
    if (on) {
      final granted = await NotificationScheduler.requestPermissions();
      if (!mounted) return;
      if (!granted) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text(
                'Benachrichtigungen sind in den iOS-Einstellungen blockiert.'),
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
    final picked = await showTimePicker(
      context: context,
      initialTime: entry.time,
      helpText: '${ReminderCopy.label(entry.slot)} um …',
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
    return _Section(
      title: 'Erinnerungen',
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
                        'Mahlzeit-Erinnerungen',
                        style: textTheme.bodyLarge
                            ?.copyWith(color: scheme.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.masterEnabled
                            ? 'Aktiv. Stelle ein, was du wann hören willst.'
                            : 'Aus. Bei Aktivierung fragt iOS einmal um Erlaubnis.',
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
                        ReminderCopy.label(s.entries[i].slot),
                        style: textTheme.bodyLarge?.copyWith(
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

    return _Section(
      title: 'Design',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          choice('System', 'Folgt dem Geräte-Setting', ThemeMode.system),
          choice('Hell', 'Helles Theme', ThemeMode.light),
          choice('Dunkel', 'Dunkles Theme', ThemeMode.dark),
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
  final int sharePercent;
  final ValueChanged<int> onShareChanged;
  final int dailyVolumeMl;
  final ValueChanged<int> onVolumeChanged;

  const _MilkSection({
    required this.numChildren,
    required this.onChildrenChanged,
    required this.ageGroup,
    required this.onAgeChanged,
    required this.sharePercent,
    required this.onShareChanged,
    required this.dailyVolumeMl,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return _Section(
      title: 'Muttermilch',
      info: InfoButton(fact: NutritionFacts.energyLactation),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kinder, die du mit Milch versorgst',
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
                  ? 'Alter des Kindes'
                  : 'Alter der Kinder',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: List.generate(
                  ChildAgeGroup.all.length,
                  (i) => ButtonSegment(
                    value: i,
                    label: Text(ChildAgeGroup.all[i].label),
                  ),
                ),
                selected: {ageGroup},
                showSelectedIcon: false,
                onSelectionChanged: (s) => onAgeChanged(s.first),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              numChildren == 1
                  ? 'Dein Anteil: $sharePercent%'
                  : 'Anteil pro Kind: $sharePercent%',
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
                  child: Text('Geschätztes Tagesvolumen',
                      style: textTheme.bodyMedium),
                ),
                const InfoButton(
                  fact: NutritionFact(
                    topic: 'Tagesvolumen Muttermilch',
                    summary: 'Energie = Volumen × 0,84 kcal/ml',
                    detail:
                        'Energiekosten der Synthese: ~0,84 kcal pro ml Milch. '
                        'Wenn du pumpst und dein Volumen kennst, trage es exakt ein. '
                        'Anteil-Slider darüber liefert sonst eine Schätzung.',
                    source: 'DGE 2025, EFSA 2017',
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
              '$dailyVolumeMl ml/Tag → +${UserProfileSettings.volumeBasedSupplement(dailyVolumeMl)} kcal/Tag',
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
              'Dein Tagesziel',
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
              label: 'Grundbedarf + Aktivität',
              value: '${formatKcal(bmrTdee)} kcal',
              color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
              textTheme: textTheme,
            ),
            if (pregSupp > 0)
              _OutcomeRow(
                label: 'Schwangerschaft (T${profile.trimester})',
                value: '+${formatKcal(pregSupp)} kcal',
                color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                textTheme: textTheme,
              ),
            if (lactSupp > 0)
              _OutcomeRow(
                label: 'Muttermilch-Aufschlag',
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

    return _Section(
      title: 'Makro-Split',
      info: const InfoButton(
        fact: NutritionFact(
          topic: 'Makro-Split',
          summary: 'Anteile von Protein / Fett / KH am Tagesziel',
          detail:
              'Standard-Split aus DGE: Protein ergibt sich aus deinem Gewicht '
              '(1,2 g/kg in der Stillzeit), Fett ~30 % der kcal, Kohlenhydrate '
              'füllen den Rest. Du kannst Protein und Fett anpassen wenn du '
              'einer spezifischen Ernährung folgst (Low-Carb, High-Protein). '
              'Kohlenhydrate werden automatisch als Rest berechnet.',
          source: 'DGE 2025',
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MacroSlider(
            label: 'Protein',
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
            label: 'Fett',
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
                  child: RichText(
                    text: TextSpan(
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                      children: [
                        const TextSpan(text: 'Kohlenhydrate '),
                        TextSpan(
                          text: '(Rest)',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  '$cPct % · ${cGrams}g · $cKcal kcal',
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
                label: const Text('Auto wiederherstellen'),
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
                        text: isAuto ? '(Auto $autoPct %)' : '(Auto $autoPct %)',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '$pct % · ${grams}g · $kcal kcal',
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

class _FavoritesSection extends ConsumerWidget {
  const _FavoritesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider).valueOrNull ??
        const <FavoriteMeal>[];
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _Section(
      title: 'Favoriten verwalten',
      child: favorites.isEmpty
          ? const EmptyFavorites()
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
