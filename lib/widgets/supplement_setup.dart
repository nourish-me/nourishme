import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/user_profile_settings.dart';
import '../providers/meal_providers.dart';
import '../models/meal_entry.dart' show MicronutrientKey;
import '../services/claude_client.dart';
import '../services/micronutrient_targets.dart';

// One-stop setup flow for the user's daily supplement (prenatal, folic
// acid, etc). Asks for camera or gallery → posts the photo to Claude
// Vision via parseSupplementLabel → opens a review sheet so the user can
// edit name / dose / per-nutrient values before persisting an
// ActiveSupplement. Returns the saved supplement, or null if the user
// cancelled at any step.
//
// Used from:
//   - Onboarding supplement step
//   - Settings supplement section ("Add" + "Edit" entry points)
Future<ActiveSupplement?> runSupplementSetup(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context);
  // Step 1: choose source.
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetCtx) {
      final scheme = Theme.of(sheetCtx).colorScheme;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera_outlined,
                    color: scheme.primary),
                title: Text(l10n.supplementSourceCamera),
                onTap: () => Navigator.of(sheetCtx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: scheme.primary),
                title: Text(l10n.supplementSourceGallery),
                onTap: () => Navigator.of(sheetCtx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (source == null || !context.mounted) return null;

  // Step 2: pick the photo.
  final picked = await ImagePicker().pickImage(
    source: source,
    imageQuality: 80,
    maxWidth: 1280,
  );
  if (picked == null || !context.mounted) return null;
  final bytes = await picked.readAsBytes();
  if (!context.mounted) return null;

  // Step 3: parse + review. Show a loading dialog around the vision call
  // so the user sees something is happening; the review sheet replaces it
  // on success.
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (loadingCtx) => _LoadingDialog(text: l10n.supplementParsing),
  );
  SupplementParseResult? parsed;
  String? errorMessage;
  try {
    parsed = await ref.read(claudeClientProvider).parseSupplementLabel(
          bytes,
          locale: Localizations.localeOf(context).languageCode,
        );
  } on CoachApiException catch (e) {
    errorMessage = e.userMessage;
  } catch (e) {
    errorMessage = '$e';
  }
  if (!context.mounted) return null;
  Navigator.of(context, rootNavigator: true).pop(); // close loading

  // Step 4: review sheet. Open it even when Vision failed - the user can
  // still type the values in manually instead of being kicked back with a
  // snackbar. Surface the error inline above the form so they know the
  // photo didn't help, then let them fill in what they know.
  return await showModalBottomSheet<ActiveSupplement>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetCtx) => _ReviewSheet(
      parsed: parsed ??
          const SupplementParseResult(name: '', values: {}, dosesPerDay: 1),
      parseError: parsed == null ? errorMessage : null,
    ),
  );
}

// Direct edit on an existing supplement - no photo, no Vision call.
// Reuses the same _ReviewSheet UI but skips the parse step. Returns the
// edited supplement or null if cancelled.
Future<ActiveSupplement?> showSupplementEditSheet(
  BuildContext context,
  ActiveSupplement current,
) {
  // Hand the existing supplement to the sheet by adapting it to the same
  // SupplementParseResult shape the review UI already speaks. The added-at
  // timestamp on the original is preserved by the caller (Settings does
  // index-based replace), the sheet only edits the editable fields.
  final asResult = SupplementParseResult(
    name: current.name,
    values: Map<String, double>.from(current.values),
    dosesPerDay: current.dosesPerDay,
  );
  return showModalBottomSheet<ActiveSupplement>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _ReviewSheet(parsed: asResult, isEdit: true),
  );
}

class _LoadingDialog extends StatelessWidget {
  final String text;
  const _LoadingDialog({required this.text});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 14),
            Flexible(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  final SupplementParseResult parsed;
  // True when the sheet was opened to edit an existing supplement (no
  // fresh Vision parse). Only changes the header copy; logic is the same.
  final bool isEdit;
  // Set when Vision failed to read the label - shown inline as a hint
  // above the form so the user knows the empty fields aren't a bug.
  final String? parseError;
  const _ReviewSheet({
    required this.parsed,
    this.isEdit = false,
    this.parseError,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late final TextEditingController _name;
  late int _dosesPerDay;
  // Per-key text controllers for the parsed values. We mutate via parseDouble
  // back to the map on save.
  late final Map<String, TextEditingController> _valueControllers;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.parsed.name);
    _dosesPerDay = widget.parsed.dosesPerDay.clamp(1, 9);
    // Show ALL nine canonical nutrient slots, pre-filled with whatever
    // Vision parsed and otherwise blank. Lets the user manually type any
    // value the Vision pass missed (or all of them, if the parse failed).
    _valueControllers = {
      for (final key in MicronutrientKey.all)
        key: TextEditingController(
          text: widget.parsed.values.containsKey(key)
              ? _fmt(widget.parsed.values[key]!)
              : '',
        ),
    };
  }

  @override
  void dispose() {
    _name.dispose();
    for (final c in _valueControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(double v) {
    if (v >= 50) return v.round().toString();
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  void _save() {
    final values = <String, double>{};
    for (final entry in _valueControllers.entries) {
      final parsed = double.tryParse(entry.value.text.replaceAll(',', '.'));
      if (parsed != null && parsed > 0) values[entry.key] = parsed;
    }
    Navigator.of(context).pop(ActiveSupplement(
      name: _name.text.trim().isEmpty ? '?' : _name.text.trim(),
      values: values,
      dosesPerDay: _dosesPerDay,
      addedAt: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isEdit
                  ? l10n.supplementEditTitle
                  : l10n.supplementReviewTitle,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isEdit
                  ? l10n.supplementEditHint
                  : l10n.supplementReviewHint,
              style: textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            if (widget.parseError != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: scheme.onTertiaryContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.parseError!,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.supplementFieldName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text(l10n.supplementFieldDoses)),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _dosesPerDay > 1
                      ? () => setState(() => _dosesPerDay--)
                      : null,
                ),
                Text('$_dosesPerDay'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _dosesPerDay < 9
                      ? () => setState(() => _dosesPerDay++)
                      : null,
                ),
              ],
            ),
            const Divider(height: 24),
            for (final entry in _valueControllers.entries)
              _NutrientRow(
                nutrientKey: entry.key,
                controller: entry.value,
                locale: locale,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.supplementCancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(l10n.supplementSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  final String nutrientKey;
  final TextEditingController controller;
  final String locale;
  const _NutrientRow({
    required this.nutrientKey,
    required this.controller,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final display = MicronutrientDisplay.forKey(nutrientKey);
    final label = display?.nameForLocale(locale) ?? nutrientKey;
    final unit = display?.unitLabel ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label)),
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                suffixText: unit,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
