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

  // Called after a meal_logged event. Cancels any enabled reminder whose
  // today-fire is within [windowMinutes] of NOW (i.e. would buzz the user
  // for a meal she just covered) and re-anchors that slot's daily chain
  // to tomorrow's same time. `matchDateTimeComponents.time` restores the
  // daily-recurring behavior from the new anchor, so future days keep
  // firing on schedule.
  //
  // Semantics:
  //  - "Skip" only catches slots whose today-fire is still in the future.
  //    A retroactively-logged meal whose time is in the past doesn't try
  //    to skip an already-fired reminder.
  //  - Logging more than [windowMinutes] ahead of a slot does NOT skip it.
  //    Tradeoff: occasional false-negative (rare) over false-positive
  //    (would skip a reminder the user genuinely wanted).
  //  - Idempotent: safe to call multiple times for the same slot within
  //    the same minute (e.g. bundle session: each meal-save calls it).
  static Future<void> skipImminentReminders({
    required ReminderSettings settings,
    required AppLocalizations l10n,
    int windowMinutes = 60,
  }) async {
    await init();
    if (!settings.masterEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final windowEnd = now.add(Duration(minutes: windowMinutes));

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
      if (!todayFire.isAfter(now)) continue; // already-fired slot
      if (todayFire.isAfter(windowEnd)) continue; // outside skip window

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
  }
}
