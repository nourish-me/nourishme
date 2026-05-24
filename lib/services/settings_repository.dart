import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/reminder_settings.dart';
import '../models/user_profile_settings.dart';

class SettingsRepository {
  static const _boxName = 'settings';
  static const _profileKey = 'profile';
  static const _coachingDateKey = 'coaching_last_opened_day';
  static const _insightDateKey = 'insight_last_generated_day';
  static const _themeModeKey = 'theme_mode';
  static const _remindersKey = 'meal_reminders';
  static const _disclaimerKey = 'disclaimer_accepted_at';

  final Box<String> _box;

  SettingsRepository(this._box);

  static Future<SettingsRepository> open() async {
    final box = await Hive.openBox<String>(_boxName);
    return SettingsRepository(box);
  }

  bool hasProfile() => _box.get(_profileKey) != null;

  UserProfileSettings getProfile() {
    final raw = _box.get(_profileKey);
    if (raw == null) return UserProfileSettings.defaults();
    return UserProfileSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfileSettings profile) =>
      _box.put(_profileKey, jsonEncode(profile.toJson()));

  // Persisted theme mode: 'light', 'dark', or 'system' (default).
  String getThemeMode() => _box.get(_themeModeKey) ?? 'system';

  Future<void> setThemeMode(String mode) =>
      _box.put(_themeModeKey, mode);

  // Audit trail of the medical-disclaimer acceptance during onboarding.
  // Null until the user ticks the checkbox + finishes onboarding.
  DateTime? getDisclaimerAcceptedAt() {
    final raw = _box.get(_disclaimerKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setDisclaimerAcceptedAt(DateTime at) =>
      _box.put(_disclaimerKey, at.toIso8601String());

  Future<void> clearAll() => _box.clear();

  Stream<UserProfileSettings> watchProfile() async* {
    yield getProfile();
    await for (final _ in _box.watch(key: _profileKey)) {
      yield getProfile();
    }
  }

  DateTime? getLastCoachingOpenDate() {
    final raw = _box.get(_coachingDateKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastCoachingOpenDate(DateTime d) {
    final iso =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return _box.put(_coachingDateKey, iso);
  }

  DateTime? getLastInsightDate() {
    final raw = _box.get(_insightDateKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastInsightDate(DateTime d) {
    final iso =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return _box.put(_insightDateKey, iso);
  }

  ReminderSettings getReminders() {
    final raw = _box.get(_remindersKey);
    if (raw == null) return ReminderSettings.defaults;
    try {
      return ReminderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return ReminderSettings.defaults;
    }
  }

  Future<void> saveReminders(ReminderSettings r) =>
      _box.put(_remindersKey, jsonEncode(r.toJson()));
}
