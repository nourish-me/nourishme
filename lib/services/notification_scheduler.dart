import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import '../models/reminder_settings.dart';

// Wraps flutter_local_notifications for the NourishMe meal-reminder slots.
// All notifications are LOCAL (scheduled on the device), no APNs server
// involvement. Each ReminderSlot has a fixed notification id derived from
// the enum index, so re-scheduling overwrites the existing pending entry.
class NotificationScheduler {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialised = false;

  static const _channelId = 'meal_reminders';

  static Future<void> init() async {
    if (_initialised) return;
    tzdata.initializeTimeZones();
    // Use the device's local timezone for daily-recurring schedules.
    final localName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(_tzCode(localName)));
    } catch (_) {
      // Fall back to UTC if the device name doesn't map. Notifications will
      // still fire on the right wall-clock minute via matchDateTimeComponents.
    }

    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(iOS: ios, android: android);
    // Notification tap → input-focus was retried twice and never landed
    // reliably (cold-launch race, tab-switch race, FocusNode-attach race).
    // Removed; notifications now just open the app (default iOS behavior)
    // with no custom post-tap logic. If/when we revisit, see Task #40 for
    // the deleted wiring.
    await _plugin.initialize(init);
    _initialised = true;
  }

  // iOS reports timezone abbreviations (CEST, PST) which `tz` doesn't always
  // know; map a few common European ones to IANA names. UTC fallback is
  // acceptable because matchDateTimeComponents.time keys on local wall-time.
  static String _tzCode(String name) {
    const map = {
      'CET': 'Europe/Berlin',
      'CEST': 'Europe/Berlin',
      'MEZ': 'Europe/Berlin',
      'MESZ': 'Europe/Berlin',
      'BST': 'Europe/London',
      'GMT': 'Europe/London',
    };
    return map[name] ?? name;
  }

  // Returns true if permission is granted (or already was). On iOS this
  // triggers the system permission dialog the first time.
  static Future<bool> requestPermissions() async {
    await init();
    final iOS = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iOS != null) {
      final ok = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return ok ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final ok = await android.requestNotificationsPermission();
      return ok ?? true; // older Android versions auto-grant.
    }
    return true;
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  // Cancels every existing meal-reminder and re-schedules the enabled ones
  // based on the supplied settings. Safe to call after any settings change.
  // l10n is passed so the system notifications match the app's current
  // language (English / German).
  static Future<void> rescheduleFor(
    ReminderSettings settings,
    AppLocalizations l10n,
  ) async {
    await init();
    await _plugin.cancelAll();
    if (!settings.masterEnabled) return;

    final details = NotificationDetails(
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
      android: AndroidNotificationDetails(
        _channelId,
        l10n.reminderChannelName,
        channelDescription: l10n.reminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    for (final entry in settings.entries) {
      if (!entry.enabled) continue;
      final firstFire = _nextOccurrence(entry.hour, entry.minute);
      await _plugin.zonedSchedule(
        entry.slot.index,
        ReminderCopy.titleFor(entry.slot, l10n),
        ReminderCopy.bodyFor(entry.slot, l10n),
        firstFire,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var fire =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!fire.isAfter(now)) {
      fire = fire.add(const Duration(days: 1));
    }
    return fire;
  }

  // Called after a meal_logged event. Cancels today's fire of the reminder
  // slot whose coverage bucket contains the meal's time-of-day, and re-anchors
  // that slot's daily chain to tomorrow's same time. `matchDateTimeComponents
  // .time` restores the daily-recurring behavior from the new anchor, so
  // future days keep firing on schedule.
  //
  // Coverage buckets (see [slotForMealTime]) partition the day along midpoints
  // between adjacent slot times: a meal at 12:00 with slots at 10:30 and 12:30
  // covers the 12:30 lunch slot (closer), not the 10:30 midmorning slot.
  //
  // Semantics:
  //  - Only meals logged on today count - past-day retroactive saves don't
  //    touch today's reminder chain (their date != today). Same-day past-time
  //    logs (e.g. "I forgot breakfast, logging at 11" with breakfast slot 8:00)
  //    still cover their slot because we match by time-of-day, not by "is the
  //    fire still in the future"; but we only re-anchor slots whose today-fire
  //    is still pending - already-fired slots are left alone.
  //  - One meal covers exactly one slot (the nearest by midpoint), so a heavy
  //    lunch can't accidentally suppress that afternoon's snack reminder.
  //  - Idempotent: safe to call multiple times for the same slot within
  //    the same minute (e.g. bundle session: each meal-save calls it).
  static Future<void> skipCoveredReminder({
    required DateTime mealAt,
    required ReminderSettings settings,
    required AppLocalizations l10n,
  }) async {
    await init();
    if (!settings.masterEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    // Only act on today's saves. Retroactively logging yesterday's lunch must
    // not retro-skip yesterday's reminder (it already fired) or skip today's.
    if (mealAt.year != now.year ||
        mealAt.month != now.month ||
        mealAt.day != now.day) {
      return;
    }
    final covered = slotForMealTime(mealAt, settings);
    if (covered == null) return;
    final entry = settings.entries.firstWhere(
      (e) => e.slot == covered,
      orElse: () => const ReminderEntry(
          slot: ReminderSlot.breakfast, enabled: false, hour: 0, minute: 0),
    );
    if (!entry.enabled) return;
    final todayFire = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, entry.hour, entry.minute);
    if (!todayFire.isAfter(now)) return; // already-fired slot

    final details = NotificationDetails(
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
      android: AndroidNotificationDetails(
        _channelId,
        l10n.reminderChannelName,
        channelDescription: l10n.reminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    await _plugin.cancel(entry.slot.index);
    final tomorrowFire = todayFire.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      entry.slot.index,
      ReminderCopy.titleFor(entry.slot, l10n),
      ReminderCopy.bodyFor(entry.slot, l10n),
      tomorrowFire,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Rebuilds today's reminder chain in one pass against the user's actual
  // meal history. For every enabled slot, looks for at least one meal
  // logged today whose coverage bucket maps to that slot - if found,
  // today's fire is cancelled and the chain re-anchors to tomorrow's
  // same time. Slots without a covering meal keep their next firing.
  //
  // Why this exists on top of skipCoveredReminder (Build +35 tester
  // report): a single-meal cancel can fail silently (iOS plugin race
  // when the app gets backgrounded mid-save), and a recurring reminder
  // would still fire. Calling this from BOTH the meal-save path AND
  // app-foreground re-establishes "if a meal exists for this slot
  // today, don't nag for it" as a converging invariant.
  static Future<void> recomputeSkipsForToday({
    required List<DateTime> todayMealTimes,
    required ReminderSettings settings,
    required AppLocalizations l10n,
  }) async {
    await init();
    if (!settings.masterEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final coveredSlots = <ReminderSlot>{};
    for (final mealAt in todayMealTimes) {
      if (mealAt.year != now.year ||
          mealAt.month != now.month ||
          mealAt.day != now.day) {
        continue;
      }
      final slot = slotForMealTime(mealAt, settings);
      if (slot != null) coveredSlots.add(slot);
    }

    final details = NotificationDetails(
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
      android: AndroidNotificationDetails(
        _channelId,
        l10n.reminderChannelName,
        channelDescription: l10n.reminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    for (final entry in settings.entries) {
      if (!entry.enabled) continue;
      final todayFire = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, entry.hour, entry.minute);
      final isCovered = coveredSlots.contains(entry.slot);
      if (isCovered && todayFire.isAfter(now)) {
        // A meal already covers this slot today. Push the chain to
        // tomorrow so the reminder doesn't fire later today.
        await _plugin.cancel(entry.slot.index);
        await _plugin.zonedSchedule(
          entry.slot.index,
          ReminderCopy.titleFor(entry.slot, l10n),
          ReminderCopy.bodyFor(entry.slot, l10n),
          todayFire.add(const Duration(days: 1)),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
      // Slots without coverage are left alone; rescheduleFor already
      // owns the "next occurrence" chain for them.
    }
  }

  // Returns the slot whose coverage bucket contains [mealAt]'s time-of-day,
  // or null when no slot is enabled. Buckets partition the day along the
  // midpoints between adjacent enabled slots: a meal at 12:00 with enabled
  // slots at 10:30 and 12:30 falls into the 12:30 bucket (midpoint 11:30),
  // covering the lunch slot. Pure / no plugin access, exposed for tests.
  static ReminderSlot? slotForMealTime(
      DateTime mealAt, ReminderSettings settings) {
    final enabled = settings.entries.where((e) => e.enabled).toList()
      ..sort((a, b) => (a.hour * 60 + a.minute)
          .compareTo(b.hour * 60 + b.minute));
    if (enabled.isEmpty) return null;
    final mealMin = mealAt.hour * 60 + mealAt.minute;
    ReminderEntry best = enabled.first;
    int bestDist = (mealMin - (enabled.first.hour * 60 + enabled.first.minute))
        .abs();
    for (final e in enabled.skip(1)) {
      final dist = (mealMin - (e.hour * 60 + e.minute)).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = e;
      }
    }
    return best.slot;
  }
}
