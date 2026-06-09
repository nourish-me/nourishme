import 'dart:convert';
import 'dart:math';

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
  static const _analyticsIdKey = 'analytics_distinct_id';
  static const _analyticsOptOutKey = 'analytics_opt_out';
  // Bumped on the key when a new tips screen ships; existing users see the
  // refreshed deck once, instead of being permanently gated by an earlier
  // "I've seen tips" flag that was set against the old content.
  static const _tipsSeenKey = 'tips_seen_v1';
  // One-shot educational toast shown the first time the session manager
  // actually bundles multiple items into a single coach reply. Teaches the
  // bundling concept exactly in the moment the user experiences it.
  static const _bundlingToastSeenKey = 'bundling_toast_seen';

  // "What do you want to use up today?" feature (briefing
  // coach_zutaten_ziel_logik). The coach asks at most once per day and
  // prioritises listed ingredients in the next-meal suggestion. Both keys
  // are stored as ISO-8601 dates; the ingredients text is plain free-form.
  static const _coachIngredientsTextKey = 'coach_ingredients_text';
  static const _coachIngredientsDateKey = 'coach_ingredients_date';
  static const _coachLastAskedKey = 'coach_last_asked_ingredients_date';

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

  bool hasSeenTipsV1() => _box.get(_tipsSeenKey) == 'true';

  Future<void> setTipsV1Seen() => _box.put(_tipsSeenKey, 'true');

  bool hasSeenBundlingToast() => _box.get(_bundlingToastSeenKey) == 'true';

  Future<void> setBundlingToastSeen() =>
      _box.put(_bundlingToastSeenKey, 'true');

  // Stable, anonymous identifier for product analytics. Generated once and
  // persisted; carries no personal data, just lets PostHog group events from
  // the same install. Survives until the app data is cleared.
  String getOrCreateAnalyticsId() {
    final existing = _box.get(_analyticsIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final r = Random.secure();
    final id = List<int>.generate(16, (_) => r.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    _box.put(_analyticsIdKey, id);
    return id;
  }

  // Analytics is on by default (anonymous). The user can opt out in Settings.
  bool getAnalyticsOptOut() => _box.get(_analyticsOptOutKey) == 'true';

  Future<void> setAnalyticsOptOut(bool optOut) =>
      _box.put(_analyticsOptOutKey, optOut.toString());

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

  // ---- Coach "ingredients today" (briefing: coach_zutaten_ziel_logik) ----

  // Returns the user's stated ingredients for *today*. Auto-expires across
  // midnight: anything stored under yesterday's date returns null.
  String? getCoachTodaysIngredients() {
    final dateRaw = _box.get(_coachIngredientsDateKey);
    final text = _box.get(_coachIngredientsTextKey);
    if (dateRaw == null || text == null || text.isEmpty) return null;
    final stored = DateTime.tryParse(dateRaw);
    if (stored == null) return null;
    final now = DateTime.now();
    if (stored.year != now.year ||
        stored.month != now.month ||
        stored.day != now.day) {
      return null;
    }
    return text;
  }

  Future<void> setCoachTodaysIngredients(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await _box.delete(_coachIngredientsTextKey);
      await _box.delete(_coachIngredientsDateKey);
      return;
    }
    await _box.put(_coachIngredientsTextKey, trimmed);
    await _box.put(_coachIngredientsDateKey, _dayKey(DateTime.now()));
  }

  Future<void> clearCoachIngredients() async {
    await _box.delete(_coachIngredientsTextKey);
    await _box.delete(_coachIngredientsDateKey);
  }

  // True iff the coach already asked the "anything to use up?" question
  // today. Used by the per-meal flow to ask at most once per day, even if
  // the user ignores it.
  bool wasCoachAskedToday() {
    final raw = _box.get(_coachLastAskedKey);
    if (raw == null) return false;
    final stored = DateTime.tryParse(raw);
    if (stored == null) return false;
    final now = DateTime.now();
    return stored.year == now.year &&
        stored.month == now.month &&
        stored.day == now.day;
  }

  Future<void> markCoachAskedToday() =>
      _box.put(_coachLastAskedKey, _dayKey(DateTime.now()));

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
