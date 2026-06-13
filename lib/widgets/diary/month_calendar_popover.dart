import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

// Custom month-grid date picker for the diary AppBar (▾). Replaces the
// stock Material showDatePicker per Claude-Design-Brief: "▾ öffnet einen
// Monatskalender-Popover. Geloggte Tage tragen einen kleinen amber Punkt,
// der fokussierte Tag ist pine-gefüllt."
//
// API:
// - [mealDays] is the set of days (normalized to midnight) on which a
//   meal exists. Days in this set get an amber dot under the number.
// - [focused] is the day the diary is currently bound to; rendered as a
//   pine-filled circle so the user sees which day they're sitting on.
// - [firstSelectable] / [lastSelectable] bound the picker. Days outside
//   the range render with reduced opacity and don't respond to taps -
//   we don't allow future logging in this MVP.
//
// Returns the picked day (normalized to midnight) or null on cancel.
Future<DateTime?> showMonthCalendarPopover(
  BuildContext context, {
  required DateTime focused,
  required Set<DateTime> mealDays,
  required DateTime firstSelectable,
  required DateTime lastSelectable,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _MonthCalendarDialog(
      initialMonth: DateTime(focused.year, focused.month, 1),
      focused: focused,
      mealDays: mealDays,
      firstSelectable: firstSelectable,
      lastSelectable: lastSelectable,
    ),
  );
}

class _MonthCalendarDialog extends StatefulWidget {
  final DateTime initialMonth;
  final DateTime focused;
  final Set<DateTime> mealDays;
  final DateTime firstSelectable;
  final DateTime lastSelectable;
  const _MonthCalendarDialog({
    required this.initialMonth,
    required this.focused,
    required this.mealDays,
    required this.firstSelectable,
    required this.lastSelectable,
  });

  @override
  State<_MonthCalendarDialog> createState() => _MonthCalendarDialogState();
}

class _MonthCalendarDialogState extends State<_MonthCalendarDialog> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth;
  }

  void _stepMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monthLabel = intl.DateFormat.yMMMM(locale).format(_month);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstWeekday =
        DateTime(_month.year, _month.month, 1).weekday; // 1=Mon..7=Sun
    final daysInMonth =
        DateTime(_month.year, _month.month + 1, 0).day;
    // Show the previous month at most until firstSelectable's month;
    // disable forward stepping past today's month (future logging is
    // disabled for the MVP).
    final canStepBack = !_isSameMonth(_month, widget.firstSelectable);
    final canStepForward = !_isSameMonth(_month, today);
    final dayLabels = _localeShortWeekdays(locale);

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed:
                        canStepBack ? () => _stepMonth(-1) : null,
                    tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        monthLabel,
                        style: textTheme.titleMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed:
                        canStepForward ? () => _stepMonth(1) : null,
                    tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (final label in dayLabels)
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: GoogleFonts.jetBrainsMono(
                            textStyle: textTheme.labelSmall?.copyWith(
                              color: scheme.outline,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // 6 rows × 7 columns covers every possible month layout.
              for (var row = 0; row < 6; row++)
                _CalendarRow(
                  cells: List<_DayCellData?>.generate(7, (col) {
                    final dayNum =
                        row * 7 + col + 1 - (firstWeekday - 1);
                    if (dayNum < 1 || dayNum > daysInMonth) return null;
                    final day = DateTime(_month.year, _month.month, dayNum);
                    final isFocused = _isSameDay(day, widget.focused);
                    final isToday = _isSameDay(day, today);
                    final hasMeal = widget.mealDays.contains(day);
                    final outOfRange =
                        day.isBefore(widget.firstSelectable) ||
                            day.isAfter(widget.lastSelectable);
                    return _DayCellData(
                      day: day,
                      label: dayNum.toString(),
                      isFocused: isFocused,
                      isToday: isToday,
                      hasMeal: hasMeal,
                      enabled: !outOfRange,
                    );
                  }),
                  onTap: (day) => Navigator.pop(context, day),
                ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                      MaterialLocalizations.of(context).cancelButtonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  // Locale-aware short weekday labels, Mon..Sun. Uses intl's narrow
  // names so the row fits in 7 equal columns. Falls back to first letter
  // if narrow names overlap on the dialog width.
  List<String> _localeShortWeekdays(String locale) {
    final df = intl.DateFormat.E(locale);
    // Anchor Monday: 2024-01-01 was a Monday.
    return List<String>.generate(7, (i) {
      final d = DateTime(2024, 1, 1).add(Duration(days: i));
      return df.format(d).substring(0, df.format(d).length >= 2 ? 2 : 1);
    });
  }
}

class _DayCellData {
  final DateTime day;
  final String label;
  final bool isFocused;
  final bool isToday;
  final bool hasMeal;
  final bool enabled;
  const _DayCellData({
    required this.day,
    required this.label,
    required this.isFocused,
    required this.isToday,
    required this.hasMeal,
    required this.enabled,
  });
}

class _CalendarRow extends StatelessWidget {
  final List<_DayCellData?> cells;
  final ValueChanged<DateTime> onTap;
  const _CalendarRow({required this.cells, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final allEmpty = cells.every((c) => c == null);
    if (allEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          for (final cell in cells)
            Expanded(
              child: cell == null
                  ? const SizedBox(height: 36)
                  : _DayCell(data: cell, onTap: onTap),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final _DayCellData data;
  final ValueChanged<DateTime> onTap;
  const _DayCell({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Focused: pine-filled circle, white-ish text.
    // Today (not focused): pine-outline ring, no fill.
    // Plain: just the number.
    // Out of range: greyed out, no interaction.
    Color? bg;
    Color textColor = scheme.onSurface;
    BoxBorder? border;
    if (data.isFocused) {
      bg = scheme.primary;
      textColor = scheme.onPrimary;
    } else if (data.isToday) {
      border = Border.all(color: scheme.primary, width: 1);
    }
    if (!data.enabled) {
      textColor = scheme.outline.withValues(alpha: 0.5);
    }
    return InkResponse(
      onTap: data.enabled ? () => onTap(data.day) : null,
      radius: 22,
      child: SizedBox(
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: border,
              ),
              alignment: Alignment.center,
              child: Text(
                data.label,
                style: textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: data.isFocused || data.isToday
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            if (data.hasMeal && !data.isFocused)
              Positioned(
                bottom: 2,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
