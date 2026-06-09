import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/models/reminder_settings.dart';
import 'package:nurturetrack/services/notification_scheduler.dart';

// Locks the "covered slot" math for push smart-skip: a meal logged at time T
// must map to the slot whose time-of-day is nearest, NOT just the next
// upcoming slot. This is the difference between the old "imminent window"
// (60 min before fire) and the new bucket-based coverage: a 7:00 breakfast
// log must still skip the 8:00 reminder, even though 7 < 8 - 60min.
void main() {
  group('slotForMealTime - default slots', () {
    final defaults = ReminderSettings.defaults.copyWith(masterEnabled: true);

    test('7:00 covers breakfast (8:00), even though > 60min before fire', () {
      // Regression: old skipImminentReminders missed this case because 7:00
      // is outside the 60-minute pre-fire window. The user logs breakfast
      // early, the 8:00 reminder fires anyway. Now it skips.
      expect(
        NotificationScheduler.slotForMealTime(
            DateTime(2026, 6, 9, 7, 0), defaults),
        ReminderSlot.breakfast,
      );
    });

    test('8:00 covers breakfast (exact match)', () {
      expect(
        NotificationScheduler.slotForMealTime(
            DateTime(2026, 6, 9, 8, 0), defaults),
        ReminderSlot.breakfast,
      );
    });

    test('9:00 → midpoint between breakfast (8:00) and midmorning (10:30) '
        'is 9:15; 9:00 falls on the breakfast side', () {
      expect(
        NotificationScheduler.slotForMealTime(
            DateTime(2026, 6, 9, 9, 0), defaults),
        ReminderSlot.breakfast,
      );
    });

    test('10:00 falls on the midmorning side of the 9:15 midpoint', () {
      expect(
        NotificationScheduler.slotForMealTime(
            DateTime(2026, 6, 9, 10, 0), defaults),
        ReminderSlot.midmorning,
      );
    });

    test('12:00 covers lunch (12:30), NOT midmorning - heavy meal must not '
        'silence the snack reminder for an unrelated slot', () {
      expect(
        NotificationScheduler.slotForMealTime(
            DateTime(2026, 6, 9, 12, 0), defaults),
        ReminderSlot.lunch,
      );
    });

    test('17:00 → midpoint of midafternoon (15:30) and dinner (18:30) is 17:00; '
        'tie picks the first scanned (midafternoon)', () {
      expect(
        NotificationScheduler.slotForMealTime(
            DateTime(2026, 6, 9, 17, 0), defaults),
        ReminderSlot.midafternoon,
      );
    });

    test('22:00 (late dinner) still covers the dinner slot - "after the last '
        'slot" tail goes to the last slot, no silent miss', () {
      expect(
        NotificationScheduler.slotForMealTime(
            DateTime(2026, 6, 9, 22, 0), defaults),
        ReminderSlot.dinner,
      );
    });

    test('5:00 (very early breakfast) still covers breakfast', () {
      expect(
        NotificationScheduler.slotForMealTime(
            DateTime(2026, 6, 9, 5, 0), defaults),
        ReminderSlot.breakfast,
      );
    });
  });

  group('slotForMealTime - disabled slots', () {
    test('a disabled slot is skipped: meal at 10:30 with midmorning OFF '
        'covers breakfast (closer than lunch)', () {
      final noMidmorning = ReminderSettings.defaults.copyWith(
        masterEnabled: true,
        entries: [
          for (final e in ReminderSettings.defaults.entries)
            if (e.slot == ReminderSlot.midmorning)
              e.copyWith(enabled: false)
            else
              e.copyWith(enabled: true),
        ],
      );
      // Now buckets are: breakfast (8:00) and lunch (12:30); midpoint = 10:15.
      // 10:30 > 10:15 → lunch.
      expect(
        NotificationScheduler.slotForMealTime(
            DateTime(2026, 6, 9, 10, 30), noMidmorning),
        ReminderSlot.lunch,
      );
      // 10:00 < 10:15 → breakfast.
      expect(
        NotificationScheduler.slotForMealTime(
            DateTime(2026, 6, 9, 10, 0), noMidmorning),
        ReminderSlot.breakfast,
      );
    });

    test('all slots disabled → null', () {
      final allOff = ReminderSettings.defaults.copyWith(
        masterEnabled: true,
        entries: [
          for (final e in ReminderSettings.defaults.entries)
            e.copyWith(enabled: false),
        ],
      );
      expect(
        NotificationScheduler.slotForMealTime(
            DateTime(2026, 6, 9, 12, 0), allOff),
        isNull,
      );
    });
  });
}
