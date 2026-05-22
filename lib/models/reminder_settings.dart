import 'package:flutter/material.dart';

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

// Static copy of the notification copy so tests + the scheduler agree.
class ReminderCopy {
  static String titleFor(ReminderSlot s) {
    switch (s) {
      case ReminderSlot.breakfast:
        return 'Frühstück?';
      case ReminderSlot.midmorning:
        return 'Kleine Stärkung?';
      case ReminderSlot.lunch:
        return 'Mittagszeit.';
      case ReminderSlot.midafternoon:
        return 'Zwischendurch was gegessen?';
      case ReminderSlot.dinner:
        return 'Abendessen geloggt?';
    }
  }

  static String bodyFor(ReminderSlot s) {
    switch (s) {
      case ReminderSlot.breakfast:
        return 'Falls du schon was hattest, tippe deine Mahlzeit ein.';
      case ReminderSlot.midmorning:
        return 'Apfel, Joghurt, Brötchen? Tippe deine Mahlzeit ein.';
      case ReminderSlot.lunch:
        return 'Coach wartet auf deine Mahlzeit.';
      case ReminderSlot.midafternoon:
        return 'Tippe deine Mahlzeit ein, dann hast du den Tag im Bild.';
      case ReminderSlot.dinner:
        return 'Letzter Eintrag heute, danach ist Feierabend.';
    }
  }

  static String label(ReminderSlot s) {
    switch (s) {
      case ReminderSlot.breakfast:
        return 'Frühstück';
      case ReminderSlot.midmorning:
        return 'Vormittags-Snack';
      case ReminderSlot.lunch:
        return 'Mittagessen';
      case ReminderSlot.midafternoon:
        return 'Nachmittags-Snack';
      case ReminderSlot.dinner:
        return 'Abendessen';
    }
  }
}
