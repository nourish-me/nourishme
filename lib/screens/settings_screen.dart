import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile_settings.dart';
import '../providers/meal_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late double _activityFactor;
  late int _numChildren;
  late int _milkSharePercent;
  bool _initialized = false;

  @override
  void dispose() {
    if (_initialized) {
      _age.dispose();
      _height.dispose();
      _weight.dispose();
    }
    super.dispose();
  }

  void _hydrate(UserProfileSettings p) {
    _age = TextEditingController(text: p.ageYears.toString());
    _height = TextEditingController(text: p.heightCm.toStringAsFixed(0));
    _weight = TextEditingController(text: p.weightKg.toStringAsFixed(1));
    _activityFactor = p.activityFactor;
    _numChildren = p.numChildrenNursing;
    _milkSharePercent = p.milkSharePercent;
    _initialized = true;
  }

  double _parseDouble(String s, double fallback) =>
      double.tryParse(s.replaceAll(',', '.')) ?? fallback;

  Future<void> _save() async {
    final current = ref.read(userProfileProvider).valueOrNull ??
        UserProfileSettings.defaults();
    final updated = current.copyWith(
      ageYears: int.tryParse(_age.text) ?? current.ageYears,
      heightCm: _parseDouble(_height.text, current.heightCm),
      weightKg: _parseDouble(_weight.text, current.weightKg),
      activityFactor: _activityFactor,
      numChildrenNursing: _numChildren,
      milkSharePercent: _milkSharePercent,
    );
    await ref.read(settingsRepositoryProvider).saveProfile(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gespeichert')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Fehler: $e'))),
      data: (profile) {
        if (!_initialized) _hydrate(profile);
        final supplement = _numChildren * _milkSharePercent * 5;
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Einstellungen'),
              centerTitle: false,
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Dein Profil',
                  style: textTheme.titleSmall?.copyWith(color: scheme.outline),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _age,
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
                        controller: _height,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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
                        controller: _weight,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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
                const SizedBox(height: 24),
                Text(
                  'Aktivitätslevel',
                  style: textTheme.titleSmall?.copyWith(color: scheme.outline),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 1.2, label: Text('Wenig')),
                      ButtonSegment(value: 1.375, label: Text('Leicht')),
                      ButtonSegment(value: 1.55, label: Text('Mäßig')),
                      ButtonSegment(value: 1.725, label: Text('Sehr')),
                    ],
                    selected: {
                      ActivityLevel.closestTo(_activityFactor).factor,
                    },
                    showSelectedIcon: false,
                    onSelectionChanged: (s) {
                      setState(() => _activityFactor = s.first);
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ActivityLevel.closestTo(_activityFactor).hint,
                  style: textTheme.bodySmall?.copyWith(color: scheme.outline),
                ),
                const SizedBox(height: 24),
                Text(
                  'Muttermilch',
                  style: textTheme.titleSmall?.copyWith(color: scheme.outline),
                ),
                const SizedBox(height: 12),
                Text(
                  'Wie viele Kinder versorgst du gerade mit deiner Milch?',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                _NumberStepper(
                  value: _numChildren,
                  min: 0,
                  max: 4,
                  onChanged: (v) => setState(() => _numChildren = v),
                ),
                const SizedBox(height: 20),
                Text(
                  'Anteil deiner Milch pro Kind: $_milkSharePercent%',
                  style: textTheme.bodyMedium,
                ),
                Text(
                  '0% = du gibst keine Milch ab, 100% = ein Kind wird ausschließlich von dir versorgt',
                  style: textTheme.bodySmall?.copyWith(color: scheme.outline),
                ),
                Slider(
                  value: _milkSharePercent.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$_milkSharePercent%',
                  onChanged: _numChildren == 0
                      ? null
                      : (v) => setState(() => _milkSharePercent = v.round()),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: scheme.surfaceContainerLow,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.calculate_outlined,
                            size: 18, color: scheme.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Daraus berechneter Kalorien-Aufschlag: $supplement kcal pro Tag',
                            style: textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
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
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      ),
    );
  }
}
