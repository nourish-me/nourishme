import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../l10n/app_localizations.dart';
import '../models/user_profile_settings.dart';
import '../utils/profile_labels.dart';

// One-stop input for "how old is the (youngest) child?". Two equivalent
// inputs used to live side by side in Settings + Onboarding (a segmented
// 0-6 / 6-12 / 12+ picker AND a birth-date row), which was clunky and
// surfaced a locked segmented picker once the date was set. This widget
// collapses them into one visible input at a time:
//
//   - Default: a "pick a birth date" CTA, plus a quiet link to fall back
//     to the bracket picker if the user doesn't want to enter a date.
//   - Birth date set: a compact display row with the date + computed age,
//     edit + clear buttons. Bracket picker is hidden — bucket is derived.
//   - Bracket-picker mode (user opted in via the link): segmented picker
//     plus a counter-link back to the date input.
class ChildAgeInput extends StatefulWidget {
  final int bucket;
  final ValueChanged<int> onBucketChanged;
  final DateTime? birthdate;
  // True when the parent has not yet recorded an explicit age pick. Used
  // to render the segmented bracket picker with NO segment selected, so
  // a tap on the default 0-6mo segment also fires onBucketChanged
  // (otherwise SegmentedButton swallows same-value taps).
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
  State<ChildAgeInput> createState() => _ChildAgeInputState();
}

class _ChildAgeInputState extends State<ChildAgeInput> {
  // Toggle that decides which input to show when no birth date is set yet:
  // the birth-date CTA (default, false) or the legacy bracket picker (true).
  bool _showBucket = false;

  int _monthsSince(DateTime birthdate) {
    final now = DateTime.now();
    var months = (now.year - birthdate.year) * 12 + (now.month - birthdate.month);
    if (now.day < birthdate.day) months--;
    return months < 0 ? 0 : months;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    if (widget.birthdate != null) {
      // State 2: birth date set. Display + edit + clear; the bucket is
      // derived from the date and shown as a quiet computed-age caption.
      return _BirthdateDisplay(
        birthdate: widget.birthdate!,
        ageLabel: _ageLabel(l10n, _monthsSince(widget.birthdate!)),
        onPick: widget.onPickBirthdate,
        onClear: widget.onClearBirthdate,
        textTheme: textTheme,
        scheme: scheme,
      );
    }
    if (_showBucket) {
      // State 3: user opted into the bracket picker. Picker + back-link.
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
              emptySelectionAllowed: widget.unpicked,
              selected:
                  widget.unpicked ? <int>{} : {widget.bucket},
              showSelectedIcon: false,
              onSelectionChanged: (s) => widget.onBucketChanged(s.first),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() => _showBucket = false);
                widget.onPickBirthdate();
              },
              icon: const Icon(Icons.cake_outlined, size: 16),
              label: Text(l10n.settingsMilkBirthdateBackToDate),
            ),
          ),
        ],
      );
    }
    // State 1 (default): birth-date CTA + fallback link to the bracket
    // picker so users who don't want to enter a date still have a path.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: widget.onPickBirthdate,
            icon: const Icon(Icons.cake_outlined, size: 18),
            label: Text(l10n.settingsMilkBirthdatePick),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _showBucket = true),
            child: Text(l10n.settingsMilkBirthdateUseBucket),
          ),
        ),
      ],
    );
  }

  String _ageLabel(AppLocalizations l10n, int months) =>
      months == 1 ? l10n.settingsMilkBirthdateAgeMonthsOne : l10n.settingsMilkBirthdateAgeMonths(months);
}

class _BirthdateDisplay extends StatelessWidget {
  final DateTime birthdate;
  final String ageLabel;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final TextTheme textTheme;
  final ColorScheme scheme;
  const _BirthdateDisplay({
    required this.birthdate,
    required this.ageLabel,
    required this.onPick,
    required this.onClear,
    required this.textTheme,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final df = intl.DateFormat.yMd(
        Localizations.localeOf(context).languageCode);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 2),
            child: Text(
              l10n.settingsMilkBirthdateAuto,
              style: textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}
