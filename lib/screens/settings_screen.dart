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
  late final TextEditingController _supplement;
  late double _activityFactor;
  bool _initialized = false;

  @override
  void dispose() {
    if (_initialized) {
      _age.dispose();
      _height.dispose();
      _weight.dispose();
      _supplement.dispose();
    }
    super.dispose();
  }

  void _hydrate(UserProfileSettings p) {
    _age = TextEditingController(text: p.ageYears.toString());
    _height = TextEditingController(text: p.heightCm.toStringAsFixed(0));
    _weight = TextEditingController(text: p.weightKg.toStringAsFixed(1));
    _supplement =
        TextEditingController(text: p.breastfeedingSupplementKcal.toString());
    _activityFactor = p.activityFactor;
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
      breastfeedingSupplementKcal:
          int.tryParse(_supplement.text) ?? current.breastfeedingSupplementKcal,
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
        return Scaffold(
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
              RadioGroup<double>(
                groupValue: ActivityLevel.closestTo(_activityFactor).factor,
                onChanged: (v) {
                  if (v != null) setState(() => _activityFactor = v);
                },
                child: Column(
                  children: ActivityLevel.all
                      .map(
                        (level) => RadioListTile<double>(
                          value: level.factor,
                          title: Text(level.label),
                          subtitle: Text(level.hint),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Stillen',
                style: textTheme.titleSmall?.copyWith(color: scheme.outline),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _supplement,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kalorien-Zuschlag pro Tag',
                  helperText:
                      'Zwillinge exklusiv stillen: ca. 1000 kcal. Ein Kind: ca. 500 kcal. Beikost: weniger.',
                  border: OutlineInputBorder(),
                  suffixText: 'kcal',
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
        );
      },
    );
  }
}
