const _weekdays = [
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];

const _months = [
  'Januar',
  'Februar',
  'März',
  'April',
  'Mai',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'Dezember',
];

String formatDayHeader(DateTime day) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final dayStart = DateTime(day.year, day.month, day.day);
  final diffDays = todayStart.difference(dayStart).inDays;
  if (diffDays == 0) return 'Heute';
  if (diffDays == 1) return 'Gestern';
  return '${_weekdays[day.weekday - 1]}, ${day.day}. ${_months[day.month - 1]}';
}

String formatTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String formatFullDate(DateTime day) =>
    '${_weekdays[day.weekday - 1]}, ${day.day}. ${_months[day.month - 1]}';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isToday(DateTime d) => isSameDay(d, DateTime.now());
