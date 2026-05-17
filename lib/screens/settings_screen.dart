import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile_settings.dart';
import '../providers/meal_providers.dart';
import '../services/calorie_target.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _supplementKcal;
  late double _activityFactor;
  late int _numChildren;
  late int _milkSharePercent;
  late int _childrenAgeGroup;
  bool _initialized = false;

  @override
  void dispose() {
    if (_initialized) {
      _age.dispose();
      _height.dispose();
      _weight.dispose();
      _supplementKcal.dispose();
    }
    super.dispose();
  }

  void _hydrate(UserProfileSettings p) {
    _age = TextEditingController(text: p.ageYears.toString());
    _height = TextEditingController(text: p.heightCm.toStringAsFixed(0));
    _weight = TextEditingController(text: p.weightKg.toStringAsFixed(1));
    _supplementKcal =
        TextEditingController(text: p.milkSupplementKcal.toString());
    _activityFactor = p.activityFactor;
    _numChildren = p.numChildrenNursing;
    _milkSharePercent = p.milkSharePercent;
    _childrenAgeGroup = p.childrenAgeGroup;

    for (final c in [_age, _height, _weight, _supplementKcal]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
    _initialized = true;
  }

  double _parseDouble(String s, double fallback) =>
      double.tryParse(s.replaceAll(',', '.')) ?? fallback;

  int _parseInt(String s, int fallback) => int.tryParse(s) ?? fallback;

  int get _suggestedSupplement => UserProfileSettings.suggestedSupplement(
        numChildren: _numChildren,
        ageGroup: _childrenAgeGroup,
        sharePercent: _milkSharePercent,
      );

  int get _currentSupplement => _parseInt(_supplementKcal.text, 0);

  UserProfileSettings _currentProfile() => UserProfileSettings(
        ageYears: _parseInt(_age.text, 30),
        heightCm: _parseDouble(_height.text, 170),
        weightKg: _parseDouble(_weight.text, 65),
        activityFactor: _activityFactor,
        numChildrenNursing: _numChildren,
        milkSharePercent: _milkSharePercent,
        childrenAgeGroup: _childrenAgeGroup,
        milkSupplementKcal: _currentSupplement,
      );

  Future<void> _save() async {
    await ref.read(settingsRepositoryProvider).saveProfile(_currentProfile());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gespeichert')),
    );
    Navigator.pop(context);
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
        return GestureDetector(
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
                _Section(
                  title: 'Dein Profil',
                  child: _ProfileFields(
                    age: _age,
                    height: _height,
                    weight: _weight,
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Aktivitätslevel',
                  child: _ActivityPicker(
                    activityFactor: _activityFactor,
                    onChanged: (v) => setState(() => _activityFactor = v),
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Muttermilch',
                  child: _MilkSection(
                    numChildren: _numChildren,
                    onChildrenChanged: (v) =>
                        setState(() => _numChildren = v),
                    ageGroup: _childrenAgeGroup,
                    onAgeChanged: (v) =>
                        setState(() => _childrenAgeGroup = v),
                    sharePercent: _milkSharePercent,
                    onShareChanged: (v) =>
                        setState(() => _milkSharePercent = v),
                    supplementController: _supplementKcal,
                    suggested: _suggestedSupplement,
                    onApplySuggestion: () => setState(() {
                      _supplementKcal.text = _suggestedSupplement.toString();
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                _OutcomeCard(profile: _currentProfile()),
                const SizedBox(height: 24),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Speichern'),
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
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileFields extends StatelessWidget {
  final TextEditingController age;
  final TextEditingController height;
  final TextEditingController weight;
  const _ProfileFields({
    required this.age,
    required this.height,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: age,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          decoration: const InputDecoration(
            labelText: 'Alter',
            border: OutlineInputBorder(),
            suffixText: 'Jahre',
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
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
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

class _ActivityPicker extends StatelessWidget {
  final double activityFactor;
  final ValueChanged<double> onChanged;
  const _ActivityPicker({
    required this.activityFactor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<double>(
            segments: ActivityLevel.all
                .map((l) => ButtonSegment(value: l.factor, label: Text(l.label)))
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
  final TextEditingController supplementController;
  final int suggested;
  final VoidCallback onApplySuggestion;

  const _MilkSection({
    required this.numChildren,
    required this.onChildrenChanged,
    required this.ageGroup,
    required this.onAgeChanged,
    required this.sharePercent,
    required this.onShareChanged,
    required this.supplementController,
    required this.suggested,
    required this.onApplySuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currentValue = int.tryParse(supplementController.text) ?? 0;
    final showSuggestion = currentValue != suggested;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kinder, die du mit Milch versorgst',
            style: textTheme.bodyMedium),
        const SizedBox(height: 6),
        _NumberStepper(
          value: numChildren,
          min: 0,
          max: 4,
          onChanged: onChildrenChanged,
        ),
        if (numChildren > 0) ...[
          const SizedBox(height: 16),
          Text('Alter der Kinder (in Monaten)', style: textTheme.bodyMedium),
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
          Text('Anteil deiner Milch pro Kind: $sharePercent%',
              style: textTheme.bodyMedium),
          Slider(
            value: sharePercent.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            label: '$sharePercent%',
            onChanged: (v) => onShareChanged(v.round()),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Resultierender Aufschlag',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: supplementController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          decoration: const InputDecoration(
            labelText: 'Pro Tag',
            helperText:
                'Wird aus deinen Angaben oben berechnet. Du kannst den Wert direkt überschreiben.',
            helperMaxLines: 2,
            border: OutlineInputBorder(),
            suffixText: 'kcal',
          ),
        ),
        if (showSuggestion) ...[
          const SizedBox(height: 8),
          ActionChip(
            avatar: const Icon(Icons.auto_awesome, size: 18),
            label: Text('Vorschlag übernehmen: $suggested kcal'),
            onPressed: onApplySuggestion,
          ),
        ],
      ],
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
    final supplement = profile.milkSupplementKcal;
    final total = bmrTdee + supplement;

    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
              '$total kcal',
              style: textTheme.displaySmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Grundbedarf inkl. Aktivität: $bmrTdee kcal',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
              ),
            ),
            Text(
              'Muttermilch-Aufschlag: $supplement kcal',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
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
          Text(
            value.toString(),
            style: textTheme.headlineSmall,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
