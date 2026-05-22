import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/user_profile_settings.dart';
import '../providers/meal_providers.dart';
import '../services/calorie_target.dart';
import '../services/nutrition_facts.dart';
import '../utils/number_format.dart';
import '../widgets/info_button.dart';
import '../widgets/nm_icons.dart';
import 'main_scaffold.dart';

// First-launch setup. Five steps with a thin progress bar at the top. Each
// step explains why we ask for the data via ⓘ-bottom-sheets so the user
// understands the scientific basis. Saves the profile at the end and routes
// to the main scaffold.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _step = 0;

  // Phase
  bool _isPregnant = false;
  bool _isLactating = true;
  int _trimester = 1;

  // Body fields are pre-filled with neutral defaults so the user can advance
  // straight away. Birthdate defaults to 30 years ago (matching old age=30
  // default) and is editable via date picker.
  DateTime _birthdate =
      DateTime(DateTime.now().year - 30, DateTime.now().month, DateTime.now().day);
  late final TextEditingController _height = TextEditingController(text: '165');
  late final TextEditingController _weight = TextEditingController(text: '65');
  double _activityFactor = 1.375;

  // Lactation
  int _numChildren = 1;
  int _childAgeGroup = 0;
  int _milkSharePercent = 100;
  int _dailyVolumeMl =
      UserProfileSettings.estimatedDailyVolumeMl(
          numChildren: 1, ageGroup: 0, sharePercent: 100);

  @override
  void dispose() {
    _controller.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  int get _totalSteps => 5;

  bool get _canAdvance {
    switch (_step) {
      case 1:
        // At least one of pregnant/lactating must be picked.
        return _isPregnant || _isLactating;
      case 2:
        // Birthdate is pre-filled, height/weight have defaults — always
        // advanceable. User can still adjust before continuing.
        return double.tryParse(_height.text.replaceAll(',', '.')) != null &&
            double.tryParse(_weight.text.replaceAll(',', '.')) != null;
      default:
        return true;
    }
  }

  static int _ageFromBirthdate(DateTime b) {
    final now = DateTime.now();
    var age = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) {
      age--;
    }
    return age;
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step += 1);
      _controller.animateToPage(
        _step,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step -= 1);
    _controller.animateToPage(
      _step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _restart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Onboarding neu starten?'),
        content: const Text(
          'Deine bisherigen Eingaben werden verworfen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Neu starten'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _step = 0;
      _isPregnant = false;
      _isLactating = true;
      _trimester = 1;
      _birthdate = DateTime(
          DateTime.now().year - 30, DateTime.now().month, DateTime.now().day);
      _height.clear();
      _weight.clear();
      _activityFactor = 1.375;
      _numChildren = 1;
      _childAgeGroup = 0;
      _milkSharePercent = 100;
      _dailyVolumeMl = UserProfileSettings.estimatedDailyVolumeMl(
        numChildren: 1,
        ageGroup: 0,
        sharePercent: 100,
      );
    });
    _controller.jumpToPage(0);
  }

  UserProfileSettings _buildProfile() => UserProfileSettings(
        ageYears: _ageFromBirthdate(_birthdate),
        birthdate: _birthdate,
        heightCm:
            double.tryParse(_height.text.replaceAll(',', '.')) ?? 167,
        weightKg:
            double.tryParse(_weight.text.replaceAll(',', '.')) ?? 56,
        activityFactor: _activityFactor,
        isPregnant: _isPregnant,
        trimester: _isPregnant ? _trimester : null,
        numChildrenNursing: _isLactating ? _numChildren : 0,
        milkSharePercent: _milkSharePercent,
        childrenAgeGroup: _childAgeGroup,
        dailyMilkVolumeMl: _isLactating ? _dailyVolumeMl : 0,
        milkSupplementKcal: 0, // derived from volume
      );

  Future<void> _finish() async {
    final profile = _buildProfile();
    await ref.read(settingsRepositoryProvider).saveProfile(profile);
    ref.invalidate(userProfileProvider);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScaffold()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _ProgressHeader(
                step: _step,
                total: _totalSteps,
                onBack: _step > 0 ? _back : null,
                onRestart: _restart,
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _WelcomeStep(scheme: scheme),
                    _PhaseStep(
                      isPregnant: _isPregnant,
                      isLactating: _isLactating,
                      onChange: (preg, lact) => setState(() {
                        _isPregnant = preg;
                        _isLactating = lact;
                      }),
                    ),
                    _BodyStep(
                      birthdate: _birthdate,
                      onBirthdateChanged: (d) =>
                          setState(() => _birthdate = d),
                      height: _height,
                      weight: _weight,
                      activityFactor: _activityFactor,
                      onActivityChanged: (v) =>
                          setState(() => _activityFactor = v),
                    ),
                    _PhaseDetailsStep(
                      isPregnant: _isPregnant,
                      isLactating: _isLactating,
                      trimester: _trimester,
                      onTrimesterChanged: (v) =>
                          setState(() => _trimester = v),
                      numChildren: _numChildren,
                      onChildrenChanged: (v) {
                        setState(() {
                          _numChildren = v;
                          _dailyVolumeMl =
                              UserProfileSettings.estimatedDailyVolumeMl(
                            numChildren: v,
                            ageGroup: _childAgeGroup,
                            sharePercent: _milkSharePercent,
                          );
                        });
                      },
                      childAgeGroup: _childAgeGroup,
                      onAgeGroupChanged: (v) {
                        setState(() {
                          _childAgeGroup = v;
                          _dailyVolumeMl =
                              UserProfileSettings.estimatedDailyVolumeMl(
                            numChildren: _numChildren,
                            ageGroup: v,
                            sharePercent: _milkSharePercent,
                          );
                        });
                      },
                      milkSharePercent: _milkSharePercent,
                      onSharePercentChanged: (v) {
                        setState(() {
                          _milkSharePercent = v;
                          _dailyVolumeMl =
                              UserProfileSettings.estimatedDailyVolumeMl(
                            numChildren: _numChildren,
                            ageGroup: _childAgeGroup,
                            sharePercent: v,
                          );
                        });
                      },
                      dailyVolumeMl: _dailyVolumeMl,
                      onVolumeChanged: (v) =>
                          setState(() => _dailyVolumeMl = v),
                    ),
                    _SummaryStep(profile: _buildProfile()),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_step == _totalSteps - 1) ...[
                        Text(
                          'Du kannst alle Werte später in den Einstellungen anpassen.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.outline,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                      ],
                      FilledButton(
                        onPressed: _canAdvance ? _next : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          _step < _totalSteps - 1 ? 'Weiter' : 'Loslegen',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int step;
  final int total;
  final VoidCallback? onBack;
  final VoidCallback onRestart;
  const _ProgressHeader({
    required this.step,
    required this.total,
    required this.onBack,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'SCHRITT ${step + 1} VON $total',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.outline,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Onboarding neu starten',
                onPressed: onRestart,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Pill-style step dots: current step is a wide pine pill, others are
          // small dots in the rule color. Direct visual translation of the
          // TestFlight 1.1 spec.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == step ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == step ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final ColorScheme scheme;
  const _WelcomeStep({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        Center(
          child: SvgPicture.asset(
            'assets/logo/bowl-mark.svg',
            width: 120,
            height: 120,
          ),
        ),
        const SizedBox(height: 24),
        // Wordmark: "NourishMe." in editorial italic with the amber dot.
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: textTheme.displayMedium?.copyWith(
                color: scheme.onSurface,
                fontSize: 40,
              ),
              children: [
                const TextSpan(text: 'Nourish'),
                TextSpan(
                  text: 'Me',
                  style: TextStyle(color: scheme.primary),
                ),
                TextSpan(
                  text: '.',
                  style: TextStyle(color: scheme.secondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'Ernährung, die mitdenkt.',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 22,
                height: 1.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              'Live-Coach für Schwangerschaft und Stillzeit. '
              'Wissenschaftlich fundiert, datenschutzfreundlich, '
              'ca. 3 Minuten Setup.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhaseStep extends StatelessWidget {
  final bool isPregnant;
  final bool isLactating;
  final void Function(bool pregnant, bool lactating) onChange;
  const _PhaseStep({
    required this.isPregnant,
    required this.isLactating,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('In welcher Phase bist du?',
              style: textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Daraus berechnen wir deinen Energie-Aufschlag und das Protein-Ziel.',
            style: textTheme.bodyMedium?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 24),
          _PhaseChoice(
            label: 'Stillzeit',
            description: 'Du produzierst Muttermilch (stillend oder pumpend)',
            selected: isLactating,
            onTap: () => onChange(isPregnant, !isLactating),
            fact: NutritionFacts.energyLactation,
            leading: NMIcons.nursing(size: 28),
          ),
          const SizedBox(height: 12),
          _PhaseChoice(
            label: 'Schwangerschaft',
            description: 'Aktuell schwanger',
            selected: isPregnant,
            onTap: () => onChange(!isPregnant, isLactating),
            fact: NutritionFacts.energyPregnancy,
            leading: NMIcons.pregnancy(size: 28),
          ),
          const SizedBox(height: 16),
          if (isPregnant && isLactating)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: scheme.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Schwangerschafts- und Stillzeit-Aufschlag werden addiert.',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onTertiaryContainer,
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

class _PhaseChoice extends StatelessWidget {
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final NutritionFact fact;
  final Widget? leading;
  const _PhaseChoice({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
    required this.fact,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: leading,
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              InfoButton(fact: fact),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyStep extends StatelessWidget {
  final DateTime birthdate;
  final ValueChanged<DateTime> onBirthdateChanged;
  final TextEditingController height;
  final TextEditingController weight;
  final double activityFactor;
  final ValueChanged<double> onActivityChanged;

  const _BodyStep({
    required this.birthdate,
    required this.onBirthdateChanged,
    required this.height,
    required this.weight,
    required this.activityFactor,
    required this.onActivityChanged,
  });

  Future<void> _pickBirthdate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: birthdate,
      firstDate: DateTime(now.year - 80),
      lastDate: now,
      helpText: 'Geburtsdatum wählen',
    );
    if (picked != null) onBirthdateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Deine Basisdaten',
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const InfoButton(
              fact: NutritionFact(
                topic: 'Basisdaten',
                summary: 'Brauchen wir für den Grundbedarf',
                detail:
                    'Wir berechnen mit der Mifflin-St Jeor Formel deinen täglichen '
                    'Grundbedarf. Daraus plus Aktivitätsfaktor plus Schwangerschaft/'
                    'Stillzeit-Aufschlag ergibt sich dein Tagesziel.',
                source: 'Mifflin-St Jeor 1990, DGE',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _pickBirthdate(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Geburtsdatum',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              _formatBirthdate(birthdate),
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
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Text('Aktivitätslevel', style: textTheme.titleSmall)),
            InfoButton(
              fact: const NutritionFact(
                topic: 'Aktivitätslevel',
                summary: 'Beeinflusst den Tagesumsatz (PAL-Faktor)',
                detail:
                    'Gering 1,2: kaum Bewegung. Mäßig 1,375: Spaziergänge, leichte Hausarbeit. '
                    'Aktiv 1,55: regelmäßiges Training. Hoch 1,725: intensives Training oder körperliche Arbeit. '
                    'Bei einem Baby zu Hause meist "Mäßig". Anpassen wenn du wieder mehr Sport machst.',
                source: 'DGE PAL-Klassifikation',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<double>(
            segments: ActivityLevel.all
                .map((l) =>
                    ButtonSegment(value: l.factor, label: Text(l.label)))
                .toList(),
            selected: {ActivityLevel.closestTo(activityFactor).factor},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onActivityChanged(s.first),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          ActivityLevel.closestTo(activityFactor).hint,
          style: textTheme.bodySmall?.copyWith(color: scheme.outline),
        ),
      ],
    );
  }
}

class _PhaseDetailsStep extends StatelessWidget {
  final bool isPregnant;
  final bool isLactating;
  final int trimester;
  final ValueChanged<int> onTrimesterChanged;
  final int numChildren;
  final ValueChanged<int> onChildrenChanged;
  final int childAgeGroup;
  final ValueChanged<int> onAgeGroupChanged;
  final int milkSharePercent;
  final ValueChanged<int> onSharePercentChanged;
  final int dailyVolumeMl;
  final ValueChanged<int> onVolumeChanged;

  const _PhaseDetailsStep({
    required this.isPregnant,
    required this.isLactating,
    required this.trimester,
    required this.onTrimesterChanged,
    required this.numChildren,
    required this.onChildrenChanged,
    required this.childAgeGroup,
    required this.onAgeGroupChanged,
    required this.milkSharePercent,
    required this.onSharePercentChanged,
    required this.dailyVolumeMl,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Details',
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            InfoButton(
              fact: isPregnant
                  ? NutritionFacts.energyPregnancy
                  : NutritionFacts.energyLactation,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isPregnant) ...[
          Row(
            children: [
              Expanded(child: Text('Trimester', style: textTheme.titleSmall)),
              InfoButton(fact: NutritionFacts.energyPregnancy),
            ],
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 24),
        ],
        if (isLactating) ...[
          Row(
            children: [
              Expanded(
                child: Text('Kinder, die du mit Milch versorgst',
                    style: textTheme.titleSmall),
              ),
              InfoButton(fact: NutritionFacts.energyLactation),
            ],
          ),
          const SizedBox(height: 8),
          _NumberStepper(
            value: numChildren,
            min: 1,
            max: 4,
            onChanged: onChildrenChanged,
          ),
          const SizedBox(height: 20),
          Text(
            numChildren == 1
                ? 'Alter des Kindes'
                : 'Alter der Kinder',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
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
              selected: {childAgeGroup},
              showSelectedIcon: false,
              onSelectionChanged: (s) => onAgeGroupChanged(s.first),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ChildAgeGroup.all[childAgeGroup].hint,
            style: textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 20),
          Text(
            numChildren == 1
                ? 'Wie groß ist dein Anteil an der Ernährung?'
                : 'Wie groß ist dein Anteil pro Kind?',
            style: textTheme.titleSmall,
          ),
          Slider(
            value: milkSharePercent.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            label: '$milkSharePercent%',
            onChanged: (v) => onSharePercentChanged(v.round()),
          ),
          Text(
            '$milkSharePercent% (0% = nur Beikost/Flasche, 100% = ausschließlich)',
            style: textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text('Geschätztes Tagesvolumen',
                    style: textTheme.titleSmall),
              ),
              InfoButton(
                fact: const NutritionFact(
                  topic: 'Tagesvolumen Muttermilch',
                  summary: 'Energie = Volumen × 0,84 kcal/ml',
                  detail:
                      'Die Energiekosten der Milchsynthese liegen bei ~0,84 kcal '
                      'pro produziertem Milliliter (0,67 kcal/g Energiedichte / '
                      '80% Synthese-Effizienz). Typisch: Einling 0-6 Mo ~780 ml/Tag, '
                      'Zwillinge ~1.500 ml/Tag, 6-12 Mo ~575 ml, >12 Mo ~300 ml. '
                      'Wenn du abpumpst und dein Volumen kennst, trage es genau ein.',
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
    );
  }
}

class _SummaryStep extends StatelessWidget {
  final UserProfileSettings profile;
  const _SummaryStep({required this.profile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bmrTdee = calculateBmrTdee(profile);
    final pregSupp = calculatePregnancySupplement(profile);
    final lactSupp = calculateLactationSupplement(profile);
    final total = bmrTdee + pregSupp + lactSupp;
    final macros = calculateMacroTargets(profile, total);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text(
          'BERECHNUNG',
          style: textTheme.labelSmall?.copyWith(
            color: scheme.outline,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Dein Tagesziel',
          style: textTheme.headlineMedium?.copyWith(
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        // Editorial result card with the big italic kcal hero.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatKcal(total),
                    style: textTheme.displayLarge?.copyWith(
                      color: scheme.primary,
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'kcal',
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _buildLede(profile, bmrTdee, pregSupp, lactSupp),
                style: textTheme.titleLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: 16),
              Text(
                'MAKRONÄHRSTOFFE · TAGESBEDARF',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.outline,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _MacroRow(label: 'Protein', value: '${macros.proteinG} g'),
              Divider(color: scheme.outlineVariant, height: 1),
              _MacroRow(label: 'Kohlenhydrate', value: '${macros.carbsG} g'),
              Divider(color: scheme.outlineVariant, height: 1),
              _MacroRow(label: 'Fett', value: '${macros.fatG} g'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Spacer(),
            InfoButton(fact: NutritionFacts.proteinLactation),
          ],
        ),
      ],
    );
  }

  String _buildLede(UserProfileSettings p, int bmr, int preg, int lact) {
    final parts = <String>['Grundbedarf + Aktivität: ${formatKcal(bmr)} kcal'];
    if (preg > 0) parts.add('+ ${formatKcal(preg)} kcal Schwangerschaft (T${p.trimester})');
    if (lact > 0) parts.add('+ ${formatKcal(lact)} kcal für Stillen');
    return parts.join(' · ');
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;
  const _MacroRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
            ),
          ),
          Text(
            value,
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
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

String _formatBirthdate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
