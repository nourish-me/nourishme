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

  @override
  void initState() {
    super.initState();
    _summary = TextEditingController(text: widget.parsed.summary);
    _kcal = TextEditingController(text: widget.parsed.kcal.toString());
    _protein = TextEditingController(
        text: widget.parsed.proteinG.toStringAsFixed(1));
    _carbs = TextEditingController(
        text: widget.parsed.carbsG.toStringAsFixed(1));
    _fat = TextEditingController(text: widget.parsed.fatG.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _summary.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  double _parseDouble(String s, double fallback) =>
      double.tryParse(s.replaceAll(',', '.')) ?? fallback;

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
    Navigator.popUntil(context, (r) => r.isFirst);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Prüfen und speichern')),
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
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Originaltext',
                        style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(widget.rawText),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (warnings.isNotEmpty) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text('Hinweise beim Stillen',
                            style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...warnings.map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('• $w'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
    );
  }
}
