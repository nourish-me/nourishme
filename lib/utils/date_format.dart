import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

import '../l10n/app_localizations.dart';

// Locale-aware day headers used in the history list and the home day
// jumper. Today / Yesterday are pulled from AppLocalizations (already
// translated); older days fall back to the intl weekday + day + month
// pattern for the current locale.
String formatDayHeader(BuildContext context, DateTime day) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final dayStart = DateTime(day.year, day.month, day.day);
  final diffDays = todayStart.difference(dayStart).inDays;
  final l10n = AppLocalizations.of(context);
  if (diffDays == 0) return l10n.todayHeader;
  if (diffDays == 1) return l10n.yesterdayHeader;
  return formatFullDate(context, day);
}

String formatFullDate(BuildContext context, DateTime day) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  // "Monday, 23 May" / "Monday, May 23" — DateFormat picks the locale's
  // preferred order. EEEE = full weekday, MMMM = full month, d = day.
  return intl.DateFormat('EEEE, MMMM d', locale).format(day);
}

String formatTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isToday(DateTime d) => isSameDay(d, DateTime.now());
