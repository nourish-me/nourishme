import 'package:flutter/material.dart';

import '../../theme/nourishme_colors.dart';
import '../nm_icons.dart';

// "All clear" food-safety state.
// Spec: handoff/testflight_1_1/README.md "Food Safety (alles ok)".
// Not wired into a screen yet — Food Safety is currently only surfaced
// inline on meal warnings.
class EmptySafety extends StatelessWidget {
  final List<SafetyCheckRow> checks;
  const EmptySafety({super.key, this.checks = const []});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rows = checks.isEmpty ? _defaultChecks : checks;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'FOOD SAFETY · BFR',
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: NMColors.inkMute,
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
                color: NMColors.paperHi,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NMColors.rule, width: 1),
              ),
              alignment: Alignment.center,
              child: NMIcons.foodSafety(size: 48),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Alles unauffällig.',
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
              Divider(color: NMColors.rule, height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: NMColors.moss,
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
                      color: NMColors.inkMute,
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

const _defaultChecks = [
  SafetyCheckRow(name: 'Quecksilber', note: 'ok'),
  SafetyCheckRow(name: 'Listeria-Risiko', note: 'pasteurisiert ok'),
  SafetyCheckRow(name: 'Koffein', note: '< 200 mg'),
];
