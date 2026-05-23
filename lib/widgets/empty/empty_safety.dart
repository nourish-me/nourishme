import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/nourishme_colors.dart';
import '../nm_icons.dart';

// "All clear" food-safety state.
// Spec: handoff/testflight_1_1/README.md "Food Safety (alles ok)".
class EmptySafety extends StatelessWidget {
  final List<SafetyCheckRow> checks;
  const EmptySafety({super.key, this.checks = const []});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final rows = checks.isEmpty ? _defaultChecksFor(l10n) : checks;
    // Moss stays as the semantic "ok" colour token; on dark backgrounds we
    // brighten it via the colorScheme outline-variant blend so it remains
    // legible against the dark surface.
    final okDotColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFA8C5A2)
        : NMColors.moss;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.emptySafetyEyebrow,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.outline,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.outlineVariant, width: 1),
              ),
              alignment: Alignment.center,
              child: NMIcons.foodSafety(size: 48),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.emptySafetyHeadline,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(color: scheme.outlineVariant, height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: okDotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rows[i].name,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].note,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.outline,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SafetyCheckRow {
  final String name;
  final String note;
  const SafetyCheckRow({required this.name, required this.note});
}

List<SafetyCheckRow> _defaultChecksFor(AppLocalizations l10n) => [
      SafetyCheckRow(
          name: l10n.emptySafetyMercury, note: l10n.emptySafetyMercuryNote),
      SafetyCheckRow(
          name: l10n.emptySafetyListeria, note: l10n.emptySafetyListeriaNote),
      SafetyCheckRow(
          name: l10n.emptySafetyCaffeine, note: l10n.emptySafetyCaffeineNote),
    ];
