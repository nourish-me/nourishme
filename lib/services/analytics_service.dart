import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'settings_repository.dart';

// Minimal, privacy-first product analytics. We post a fixed set of named
// events to PostHog's capture endpoint over plain HTTP, so we control exactly
// what leaves the device: no autocapture, no PII, an anonymous install id.
//
// Disabled (every call a no-op) when the key is absent (e.g. local dev without
// a .env entry) or the user has opted out in Settings. Capture is
// fire-and-forget and never throws, so instrumentation can't break a flow.
class AnalyticsService {
  AnalyticsService(this._settings);

  final SettingsRepository _settings;

  static String get _apiKey => dotenv.env['POSTHOG_API_KEY'] ?? '';
  static String get _host =>
      (dotenv.env['POSTHOG_HOST'] ?? 'https://eu.i.posthog.com')
          .replaceAll(RegExp(r'/+$'), '');

  String? _appVersionCache;

  bool get _enabled => _apiKey.isNotEmpty && !_settings.getAnalyticsOptOut();

  Future<String> _appVersion() async {
    if (_appVersionCache != null) return _appVersionCache!;
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersionCache = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _appVersionCache = 'unknown';
    }
    return _appVersionCache!;
  }

  // Records a named event with optional non-sensitive properties. Safe to call
  // from any flow: returns immediately and swallows all errors.
  Future<void> capture(String event, {Map<String, Object?>? properties}) async {
    if (!_enabled) return;
    try {
      final body = jsonEncode({
        'api_key': _apiKey,
        'event': event,
        'distinct_id': _settings.getOrCreateAnalyticsId(),
        'properties': {
          '\$lib': 'nourishme-dart',
          'app_version': await _appVersion(),
          ...?properties,
        },
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      await http
          .post(
            Uri.parse('$_host/capture/'),
            headers: const {'content-type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Analytics capture failed for "$event": $e');
    }
  }

  // Convenience for navigation tracking. Mirrors PostHog's "$screen" concept
  // but as a plain named event so it shows up predictably in the dashboard.
  Future<void> screen(String name) =>
      capture('screen_view', properties: {'screen': name});
}
