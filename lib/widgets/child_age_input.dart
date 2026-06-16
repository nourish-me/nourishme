import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../l10n/app_localizations.dart';
import '../models/user_profile_settings.dart';
import '../utils/profile_labels.dart';

// Compact age input: ONE visible picker pattern by default (segmented
// bracket: 0-6mo / 6-12mo / 12+mo), plus a small inline link to enter
// an exact birth date instead. Once a birth date is set the picker
// is replaced with a quiet date row + clear icon - the bucket is then
// derived automatically.
//
// Vanessa Build+29 design refactor: the previous version had THREE
// view states (birthdate CTA / bracket toggle / birthdate display)
// which made the form feel inconsistent next to the children-count
// segmented picker and the milk-share scenario tiles. Collapsing to
// ONE primary affordance (the bracket) matches the visual pattern of
// the children-count segmented above it and reads as one form.
//
// Buckets follow calorie_target.dart convention:
//   0 = 0-6 mo, 1 = 6-12 mo, 2 = 12+ mo
class ChildAgeInput extends StatelessWidget {
  final int bucket;
  final ValueChanged<int> onBucketChanged;
  final DateTime? birthdate;
  // True when the parent has not yet recorded an explicit age pick.
  // Renders the segmented button with no selection so a tap on the
  // default 0-6mo segment also fires onBucketChanged.
  final bool unpicked;
  final VoidCallback onPickBirthdate;
  final VoidCallback onClearBirthdate;

  const ChildAgeInput({
    super.key,
    required this.bucket,
    required this.onBucketChanged,
    required this.birthdate,
    this.unpicked = false,
    required this.onPickBirthdate,
    required this.onClearBirthdate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    if (birthdate != null) {
      return _BirthdateDisplay(
        birthdate: birthdate!,
        onPick: onPickBirthdate,
        onClear: onClearBirthdate,
        textTheme: textTheme,
        scheme: scheme,
      );
    }

    final ageLabels = childAgeLabelsOf(l10n);
    final ageGroups = ChildAgeGroup.allFor(ageLabels);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            segments: List.generate(
              ageGroups.length,
              (i) => ButtonSegment(
                value: i,
                label: Text(ageGroups[i].label),
              ),
            ),
            // Always allow empty selection so the unpicked → picked
            // transition doesn't reset the internal selection state
            // (Vanessa Build+29 bug).
            emptySelectionAllowed: true,
            selected: unpicked ? <int>{} : {bucket},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onBucketChanged(s.first),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onPickBirthdate,
            icon: const Icon(Icons.cake_outlined, size: 16),
            label: Text(l10n.settingsMilkBirthdatePick),
          ),
        ),
      ],
    );
  }
}

class _BirthdateDisplay extends StatelessWidget {
  final DateTime birthdate;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final TextTheme textTheme;
  final ColorScheme scheme;
  const _BirthdateDisplay({
    required this.birthdate,
    required this.onPick,
    required this.onClear,
    required this.textTheme,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final df =
        intl.DateFormat.yMd(Localizations.localeOf(context).languageCode);
    final l10n = AppLocalizations.of(context);
    final months = _monthsSince(birthdate);
    final ageLabel =
        months == 1 ? l10n.settingsMilkBirthdateAgeMonthsOne : l10n.settingsMilkBirthdateAgeMonths(months);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.cake_outlined, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${df.format(birthdate)} · $ageLabel',
              style: textTheme.bodyMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: l10n.settingsMilkBirthdatePick,
            onPressed: onPick,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: l10n.settingsMilkBirthdateClear,
            onPressed: onClear,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  static int _monthsSince(DateTime birthdate) {
    final now = DateTime.now();
    var months = (now.year - birthdate.year) * 12 + (now.month - birthdate.month);
    if (now.day < birthdate.day) months--;
    return months < 0 ? 0 : months;
  }
}
