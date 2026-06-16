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
  // GDPR Art. 9 lit. a: explicit consent for processing health-data
  // (pregnancy, lactation, weight, meal entries) by Anthropic in the
  // US. Without it we MUST NOT send any profile or meal payload to
  // the model. Set during onboarding's consent step, revocable via
  // app reset (clearAll).
  static const _healthDataConsentKey = 'health_data_consent_at';
  // GDPR-compliant opt-in for non-essential analytics (PostHog, EU).
  // Defaults to null = no consent = no tracking. Separate from the
  // health-data consent so the user can accept coaching but decline
  // analytics. Revocable any time via the Settings toggle.
  static const _analyticsConsentKey = 'analytics_consent_at';
  // Bumped on the key when a new tips screen ships; existing users see the
  // refreshed deck once, instead of being permanently gated by an earlier
  // "I've seen tips" flag that was set against the old content.
  static const _tipsSeenKey = 'tips_seen_v1';
  // One-shot educational toast shown the first time the session manager
  // actually bundles multiple items into a single coach reply. Teaches the
  // bundling concept exactly in the moment the user experiences it.
  static const _bundlingToastSeenKey = 'bundling_toast_seen';
  // Per-micronutrient timestamp of the last coach-side mention (#106).
  // Stored as JSON: { "iodine_ug": "2026-06-15T12:34:56Z", ... }. The
  // micro-nudge builder filters out keys whose last mention is within
  // the cooldown window so chronic gaps (T2: "App zeigt Jod-Lücke
  // dauernd an, verunsichert mich") get at most one nudge per week.
  static const _microMentionedAtKey = 'micro_mentioned_at';

  // "What do you want to use up today?" feature (briefing
  // coach_zutaten_ziel_logik). The coach asks at most once per day and
  // prioritises listed ingredients in the next-meal suggestion. Both keys
  // are stored as ISO-8601 dates; the ingredients text is plain free-form.
  static const _coachIngredientsTextKey = 'coach_ingredients_text';
  static const _coachIngredientsDateKey = 'coach_ingredients_date';
  static const _coachLastAskedKey = 'coach_last_asked_ingredients_date';
  // Meal-thread anchor for the "anything to use up today?" question so the
  // diary can render an inline reply input directly under THAT coach
  // bubble (not under every coach bubble of the day).
  static const _coachLastAskedMealIdKey = 'coach_last_asked_meal_id';

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

  // Legacy opt-out flag. Kept readable so a migration step (or audit)
  // can see what the user picked under the old regime. New code should
  // use getAnalyticsConsentAt() and clearAnalyticsConsent() instead -
  // GDPR requires opt-in, not opt-out, for non-essential tracking.
  bool getAnalyticsOptOut() => _box.get(_analyticsOptOutKey) == 'true';

  Future<void> setAnalyticsOptOut(bool optOut) =>
      _box.put(_analyticsOptOutKey, optOut.toString());

  // Health-data consent (GDPR Art. 9 lit. a). Returns the timestamp
  // when the user explicitly opted in during onboarding, or null if
  // they never have. Null MUST gate every Anthropic-bound network
  // call - no profile, no meal text, no photo bytes leave the device
  // until this is non-null.
  DateTime? getHealthDataConsentAt() {
    final raw = _box.get(_healthDataConsentKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setHealthDataConsentAt(DateTime at) =>
      _box.put(_healthDataConsentKey, at.toIso8601String());

  // Revocation path. Used by the settings screen when the user clears
  // their profile / "App zurücksetzen". The Hive box itself is wiped
  // by clearAll() in that flow; this is the surgical version for
  // tests or future "revoke health-data consent" UI.
  Future<void> clearHealthDataConsent() => _box.delete(_healthDataConsentKey);

  // Analytics consent (opt-in). Same shape as health-data consent:
  // null until the user actively ticks the optional box in onboarding,
  // or activates the toggle in settings later. Revoking via the
  // settings toggle calls clearAnalyticsConsent() and PostHog stops
  // immediately (no flushing of pending events).
  DateTime? getAnalyticsConsentAt() {
    final raw = _box.get(_analyticsConsentKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setAnalyticsConsentAt(DateTime at) =>
      _box.put(_analyticsConsentKey, at.toIso8601String());

  Future<void> clearAnalyticsConsent() => _box.delete(_analyticsConsentKey);

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

  // Returns the meal-id the coach last asked under, but only if that ask
  // was still today (yesterday's anchor would render an input in a
  // history view, which is wrong).
  String? getCoachLastAskedAtMealId() {
    if (!wasCoachAskedToday()) return null;
    return _box.get(_coachLastAskedMealIdKey);
  }

  Future<void> setCoachLastAskedAtMealId(String mealId) =>
      _box.put(_coachLastAskedMealIdKey, mealId);

  // Returns the per-key map of last-mention timestamps for micronutrient
  // nudges (#106). Empty map when nothing has been nudged yet or the
  // stored value is corrupt; never throws.
  Map<String, DateTime> getMicroMentionedAt() {
    final raw = _box.get(_microMentionedAtKey);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, DateTime>{};
      decoded.forEach((key, value) {
        if (value is String) {
          final parsed = DateTime.tryParse(value);
          if (parsed != null) out[key] = parsed;
        }
      });
      return out;
    } catch (_) {
      return const {};
    }
  }

  // Updates the timestamps for ALL keys in [keys] to [at]. The keys
  // are micronutrient IDs (e.g. "iodine_ug") that the nudge builder
  // included in its outgoing message.
  Future<void> setMicroMentionedAt(Iterable<String> keys, DateTime at) async {
    if (keys.isEmpty) return;
    final current = Map<String, DateTime>.from(getMicroMentionedAt());
    for (final key in keys) {
      current[key] = at;
    }
    final encoded = jsonEncode(
      current.map((k, v) => MapEntry(k, v.toUtc().toIso8601String())),
    );
    await _box.put(_microMentionedAtKey, encoded);
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
