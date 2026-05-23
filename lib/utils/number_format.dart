import 'package:intl/intl.dart' as intl;

// Locale-aware integer formatter for kcal values. Uses the current
// Intl.defaultLocale (set in main.dart from the device locale) so EN
// renders as 1,234 and DE as 1.234. Callers don't need to pass locale.
String formatKcal(num value) =>
    intl.NumberFormat.decimalPattern().format(value.round());
