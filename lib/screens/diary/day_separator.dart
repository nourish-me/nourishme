import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/date_format.dart';

// Day-row presentation primitives for the diary. All four widgets share
// the same purpose: structure the diary's vertical scroll so a fast
// scrub through a long history reads as days, not a wall of entries.

class DaySeparator extends StatelessWidget {
  final DateTime day;
  final ColorScheme scheme;
  final TextTheme textTheme;
  const DaySeparator({
    super.key,
    required this.day,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final label = formatDayHeader(context, day);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: scheme.outlineVariant, thickness: 0.5),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: scheme.outline,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: scheme.outlineVariant, thickness: 0.5),
          ),
        ],
      ),
    );
  }
}

// Compact summary line for a run of consecutive empty days when scrolling
// back through history. Shows "9. bis 18. Mai · keine Einträge" instead of
// stacking individual day separators with empty rows.
class EmptyDayRange extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback? onTap;
  const EmptyDayRange({
    super.key,
    required this.start,
    required this.end,
    required this.scheme,
    required this.textTheme,
    this.onTap,
  });

  String _format(DateTime d, BuildContext context) {
    // Use the platform-localised short month name. intl ships with the
    // localisation data via flutter_localizations.
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final monthName = DateFormat.MMM(localeTag).format(d);
    return '${d.day}. $monthName';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dayCount = end.difference(start).inDays + 1;
    final fromLabel = _format(start, context);
    final toLabel = _format(end, context);
    final label = dayCount == 1 ? fromLabel : null;
    final inner = Row(
      children: [
        Expanded(
          child: Container(height: 1, color: scheme.outlineVariant),
        ),
        const SizedBox(width: 10),
        Text(
          dayCount == 1
              ? l10n.homeEmptyRangeSingle(label!)
              : l10n.homeEmptyRangeMulti(fromLabel, toLabel, dayCount),
          style: textTheme.labelSmall?.copyWith(
            color: scheme.outline,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1, color: scheme.outlineVariant),
        ),
      ],
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: inner,
      ),
    );
  }
}

class EmptyDay extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback onAdd;
  const EmptyDay({
    super.key,
    required this.scheme,
    required this.textTheme,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context).homeEmptyDayText,
              style: textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(width: 8),
            Icon(Icons.add, size: 16, color: scheme.primary),
            const SizedBox(width: 2),
            Text(
              AppLocalizations.of(context).homeEmptyDayAdd,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Picker shown when the user taps a collapsed empty-day range. Lists
// each day in the range so the user can choose which one to log into,
// then the parent routes to the regular past-day input sheet.
class EmptyRangePickerSheet extends StatelessWidget {
  final List<DateTime> days;
  const EmptyRangePickerSheet({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weekdayFmt = DateFormat('EEEE', locale);
    final dayFmt = DateFormat('d MMM', locale);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeEmptyRangePickerTitle,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.homeEmptyRangePickerHint,
                style: textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: days.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: scheme.outlineVariant, height: 1),
                  itemBuilder: (_, i) {
                    final day = days[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        weekdayFmt.format(day),
                        style: textTheme.bodyLarge,
                      ),
                      trailing: Text(
                        dayFmt.format(day),
                        style: textTheme.bodyMedium
                            ?.copyWith(color: scheme.outline),
                      ),
                      onTap: () => Navigator.pop(context, day),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
