import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/favorite_meal.dart';
import '../providers/meal_providers.dart';

// Bottom sheet to edit an existing favorite directly (without creating a new
// one). Opened via long-press on a favorite chip.
class FavoriteEditSheet extends ConsumerStatefulWidget {
  final FavoriteMeal favorite;
  const FavoriteEditSheet({super.key, required this.favorite});

  @override
  ConsumerState<FavoriteEditSheet> createState() =>
      _FavoriteEditSheetState();
}

class _FavoriteEditSheetState extends ConsumerState<FavoriteEditSheet> {
  late final TextEditingController _summary;
  late final TextEditingController _portion;
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    final f = widget.favorite;
    _summary = TextEditingController(text: f.summary);
    _portion = TextEditingController(
        text: f.portionAmount > 0 ? f.portionAmount.toStringAsFixed(0) : '');
    _kcal = TextEditingController(text: f.kcal.toString());
    _protein = TextEditingController(text: f.proteinG.toStringAsFixed(1));
    _carbs = TextEditingController(text: f.carbsG.toStringAsFixed(1));
    _fat = TextEditingController(text: f.fatG.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _summary.dispose();
    _portion.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  double _parseDouble(String s, double fallback) =>
      double.tryParse(s.replaceAll(',', '.')) ?? fallback;

  Future<void> _save() async {
    final original = widget.favorite;
    final updated = FavoriteMeal(
      id: original.id,
      summary: _summary.text.trim().isEmpty
          ? original.summary
          : _summary.text.trim(),
      kcal: int.tryParse(_kcal.text) ?? original.kcal,
      proteinG: _parseDouble(_protein.text, original.proteinG),
      carbsG: _parseDouble(_carbs.text, original.carbsG),
      fatG: _parseDouble(_fat.text, original.fatG),
      portionAmount: _parseDouble(_portion.text, original.portionAmount),
      portionUnit: original.portionUnit,
      safetyWarnings: original.safetyWarnings,
    );
    await ref.read(favoriteRepositoryProvider).save(updated);
    if (mounted) {
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    await ref.read(favoriteRepositoryProvider).delete(widget.favorite.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final portionUnit = widget.favorite.portionUnit;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Favorit bearbeiten',
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.outline,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Aus Favoriten entfernen',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _delete,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _summary,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Beschreibung',
                    hintStyle: TextStyle(color: scheme.outline),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _portion,
                        label: 'Portion',
                        suffix: portionUnit,
                        decimal: true,
                        onSubmit: _save,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Field(
                        controller: _kcal,
                        label: 'Kalorien',
                        suffix: 'kcal',
                        decimal: false,
                        onSubmit: _save,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _showDetails = !_showDetails),
                    icon: Icon(
                      _showDetails ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    label:
                        Text(_showDetails ? 'Weniger' : 'Makros bearbeiten'),
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
                        child: _Field(
                          controller: _protein,
                          label: 'Protein',
                          suffix: 'g',
                          decimal: true,
                          onSubmit: _save,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Field(
                          controller: _carbs,
                          label: 'KH',
                          suffix: 'g',
                          decimal: true,
                          onSubmit: _save,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Field(
                          controller: _fat,
                          label: 'Fett',
                          suffix: 'g',
                          decimal: true,
                          onSubmit: _save,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Abbrechen'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: const Text('Speichern'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool decimal;
  final VoidCallback onSubmit;
  const _Field({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.decimal,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixText: suffix,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
