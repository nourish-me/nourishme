import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal_entry.dart';
import '../providers/meal_providers.dart';
import '../services/claude_client.dart';
import 'input_screen.dart';

class ConfirmScreen extends ConsumerStatefulWidget {
  final String rawText;
  final MealParseResult parsed;
  final Uint8List? imageBytes;

  const ConfirmScreen({
    super.key,
    required this.rawText,
    required this.parsed,
    this.imageBytes,
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

  late final int _origKcal;
  late final double _origProtein;
  late final double _origCarbs;
  late final double _origFat;
  late final double _origPortion;
  bool _scaling = false;

  @override
  void initState() {
    super.initState();
    _origKcal = widget.parsed.kcal;
    _origProtein = widget.parsed.proteinG;
    _origCarbs = widget.parsed.carbsG;
    _origFat = widget.parsed.fatG;
    _origPortion = widget.parsed.portionAmount;

    _summary = TextEditingController(text: widget.parsed.summary);
    _kcal = TextEditingController(text: _origKcal.toString());
    _protein = TextEditingController(text: _origProtein.toStringAsFixed(1));
    _carbs = TextEditingController(text: _origCarbs.toStringAsFixed(1));
    _fat = TextEditingController(text: _origFat.toStringAsFixed(1));
    _portion = TextEditingController(
        text: _origPortion > 0 ? _origPortion.toStringAsFixed(0) : '');
    _portion.addListener(_onPortionChanged);
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
  }

  Future<void> _save() async {
    final meal = MealEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      rawText: widget.rawText,
      summary: _summary.text.trim().isEmpty
          ? widget.parsed.summary
          : _summary.text.trim(),
      kcal: int.tryParse(_kcal.text) ?? widget.parsed.kcal,
      proteinG: _parseDouble(_protein.text, widget.parsed.proteinG),
      carbsG: _parseDouble(_carbs.text, widget.parsed.carbsG),
      fatG: _parseDouble(_fat.text, widget.parsed.fatG),
      safetyWarnings: widget.parsed.safetyWarnings,
    );
    await ref.read(mealRepositoryProvider).save(meal);
    if (!mounted) return;
    _triggerCoachingTip(meal);
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  void _triggerCoachingTip(MealEntry meal) {
    final client = ref.read(claudeClientProvider);
    final target = ref.read(calorieTargetProvider);
    final today = ref.read(todayMealsProvider);
    final totalKcalToday =
        today.fold<int>(0, (sum, m) => sum + m.kcal) + meal.kcal;
    client
        .generateCoachingTip(
      justEatenSummary: meal.summary,
      justEatenKcal: meal.kcal,
      totalKcalToday: totalKcalToday,
      targetKcal: target,
      safetyWarnings: meal.safetyWarnings,
    )
        .then((tip) {
      if (!mounted) return;
      ref.read(latestTipProvider.notifier).state = tip.trim();
    }).catchError((_) {});
  }

  void _editText() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InputScreen(prefill: widget.rawText),
      ),
    );
  }

  void _discard() {
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final warnings = widget.parsed.safetyWarnings;
    final portionUnit = widget.parsed.portionUnit;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Prüfen und speichern'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                widget.imageBytes!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.rawText.isNotEmpty) ...[
            Card(
              elevation: 0,
              color: scheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Originaltext',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.outline,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.rawText),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (warnings.isNotEmpty) ...[
            Card(
              elevation: 0,
              color: scheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: scheme.onTertiaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          'Hinweise beim Stillen',
                          style: textTheme.titleSmall?.copyWith(
                            color: scheme.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...warnings.map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• $w',
                          style: TextStyle(color: scheme.onTertiaryContainer),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _summary,
            decoration: const InputDecoration(
              labelText: 'Beschreibung',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portion,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Geschätzte Portion',
              helperText:
                  'Ändern skaliert Kalorien und Makros entsprechend.',
              border: const OutlineInputBorder(),
              suffixText: portionUnit,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _kcal,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Kalorien',
              border: OutlineInputBorder(),
              suffixText: 'kcal',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _protein,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Protein',
                    border: OutlineInputBorder(),
                    suffixText: 'g',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _carbs,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'KH',
                    border: OutlineInputBorder(),
                    suffixText: 'g',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fat,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fett',
                    border: OutlineInputBorder(),
                    suffixText: 'g',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _discard,
                      child: const Text('Verwerfen'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _editText,
                      child: const Text('Text anpassen'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Speichern'),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
