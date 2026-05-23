import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum ReminderSlot {
  breakfast,
  midmorning,
  lunch,
  midafternoon,
  dinner,
}

class ReminderEntry {
  final ReminderSlot slot;
  final bool enabled;
  final int hour;
  final int minute;

  const ReminderEntry({
    required this.slot,
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  ReminderEntry copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderEntry(
        slot: slot,
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  Map<String, dynamic> toJson() => {
        'slot': slot.name,
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
      };

  static ReminderEntry fromJson(Map<String, dynamic> j) => ReminderEntry(
        slot: ReminderSlot.values.byName(j['slot'] as String),
        enabled: j['enabled'] as bool? ?? true,
        hour: j['hour'] as int,
        minute: j['minute'] as int,
      );
}

class ReminderSettings {
  final bool masterEnabled;
  final List<ReminderEntry> entries;

  const ReminderSettings({
    required this.masterEnabled,
    required this.entries,
  });

  static const defaults = ReminderSettings(
    masterEnabled: false,
    entries: [
      ReminderEntry(
          slot: ReminderSlot.breakfast,
          enabled: true,
          hour: 8,
          minute: 0),
      ReminderEntry(
          slot: ReminderSlot.midmorning,
          enabled: true,
          hour: 10,
          minute: 30),
      ReminderEntry(
          slot: ReminderSlot.lunch,
          enabled: true,
          hour: 12,
          minute: 30),
      ReminderEntry(
          slot: ReminderSlot.midafternoon,
          enabled: true,
          hour: 15,
          minute: 30),
      ReminderEntry(
          slot: ReminderSlot.dinner,
          enabled: true,
          hour: 18,
          minute: 30),
    ],
  );

  ReminderSettings copyWith({
    bool? masterEnabled,
    List<ReminderEntry>? entries,
  }) =>
      ReminderSettings(
        masterEnabled: masterEnabled ?? this.masterEnabled,
        entries: entries ?? this.entries,
      );

  ReminderSettings withEntry(ReminderEntry entry) {
    final newList = [
      for (final e in entries) e.slot == entry.slot ? entry : e,
    ];
    return copyWith(entries: newList);
  }

  Map<String, dynamic> toJson() => {
        'masterEnabled': masterEnabled,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  static ReminderSettings fromJson(Map<String, dynamic> j) => ReminderSettings(
        masterEnabled: j['masterEnabled'] as bool? ?? false,
        entries: (j['entries'] as List)
            .map((e) => ReminderEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// Notification copy proxies to AppLocalizations so the scheduler and the
// settings UI both speak the user's locale.
class ReminderCopy {
  static String titleFor(ReminderSlot s, AppLocalizations l10n) {
    switch (s) {
      case ReminderSlot.breakfast:
        return l10n.reminderBreakfastTitle;
      case ReminderSlot.midmorning:
        return l10n.reminderMidmorningTitle;
      case ReminderSlot.lunch:
        return l10n.reminderLunchTitle;
      case ReminderSlot.midafternoon:
        return l10n.reminderMidafternoonTitle;
      case ReminderSlot.dinner:
        return l10n.reminderDinnerTitle;
    }
  }

  static String bodyFor(ReminderSlot s, AppLocalizations l10n) {
    switch (s) {
      case ReminderSlot.breakfast:
        return l10n.reminderBreakfastBody;
      case ReminderSlot.midmorning:
        return l10n.reminderMidmorningBody;
      case ReminderSlot.lunch:
        return l10n.reminderLunchBody;
      case ReminderSlot.midafternoon:
        return l10n.reminderMidafternoonBody;
      case ReminderSlot.dinner:
        return l10n.reminderDinnerBody;
    }
  }

  static String label(ReminderSlot s, AppLocalizations l10n) {
    switch (s) {
      case ReminderSlot.breakfast:
        return l10n.reminderSlotBreakfast;
      case ReminderSlot.midmorning:
        return l10n.reminderSlotMidmorning;
      case ReminderSlot.lunch:
        return l10n.reminderSlotLunch;
      case ReminderSlot.midafternoon:
        return l10n.reminderSlotMidafternoon;
      case ReminderSlot.dinner:
        return l10n.reminderSlotDinner;
    }
  }
}
