import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nurturetrack/services/claude_client.dart';

// Exercises the _post error-mapping (timeout/socket/connection/401/429/5xx/
// non-200/bad-200) via the public generatePerMealResponse path, with a
// MockClient so no network is touched. Also locks in the EN/DE localisation
// of the whole CoachApiException family (the i18n fix).

void main() {
  setUpAll(() {
    // _post only reaches the HTTP layer when the proxy is configured;
    // without this it short-circuits with "App is not configured".
    dotenv.testLoad(
        fileInput: 'NOURISHME_API_URL=https://test.example\nAPP_SECRET=secret');
  });

  // Minimal valid per-meal call; the meal content is irrelevant, we only
  // care which response the (mocked) transport returns.
  Future<String> callPerMeal(http.Client mock, String locale) {
    return ClaudeClient(httpClient: mock).generatePerMealResponse(
      mealRawText: 'Apfel',
      mealSummary: 'Apfel',
      mealKcal: 100,
      mealProteinG: 1,
      mealCarbsG: 1,
      mealFatG: 1,
      safetyWarnings: const [],
      totalKcalToday: 100,
      targetKcal: 2000,
      totalProteinToday: 1,
      proteinTargetG: 80,
      numChildrenNursing: 1,
      milkSharePercent: 100,
      weightKg: 60,
      heightCm: 165,
      ageYears: 34,
      activityFactor: 1.4,
      isPregnant: false,
      trimester: null,
      dailyMilkVolumeMl: 800,
      locale: locale,
    );
  }

  MockClient status(int code, [String body = '{}']) =>
      MockClient((_) async => http.Response(body, code));

  Future<CoachApiException> capture(http.Client mock, String locale) async {
    try {
      await callPerMeal(mock, locale);
    } on CoachApiException catch (e) {
      return e;
    }
    fail('expected CoachApiException');
  }

  group('HTTP status mapping', () {
    test('401 → auth message', () async {
      expect((await capture(status(401), 'en')).userMessage,
          contains('Auth problem'));
      expect((await capture(status(403), 'de')).userMessage,
          contains('Authentifizierungsproblem'));
    });

    test('429 → overloaded message (EN/DE)', () async {
      expect((await capture(status(429), 'en')).userMessage,
          contains('overloaded'));
      expect((await capture(status(429), 'de')).userMessage,
          contains('überlastet'));
    });

    test('5xx → unavailable message (EN/DE)', () async {
      expect((await capture(status(500), 'en')).userMessage,
          contains('unavailable'));
      expect((await capture(status(503), 'de')).userMessage,
          contains('nicht erreichbar'));
    });

    test('other non-200 → generic message (EN/DE)', () async {
      expect((await capture(status(400), 'en')).userMessage,
          contains('Something went wrong'));
      expect((await capture(status(418), 'de')).userMessage,
          contains('schiefgelaufen'));
    });

    test('200 with unexpected body → generic message', () async {
      // 200 OK but not the {content:[{text}]} shape (e.g. a proxy error page).
      expect((await capture(status(200, '{"unexpected":true}'), 'de')).userMessage,
          contains('schiefgelaufen'));
    });
  });

  group('transport errors', () {
    test('SocketException → no-internet message (EN/DE)', () async {
      MockClient sock() =>
          MockClient((_) async => throw const SocketException('no net'));
      expect(
          (await capture(sock(), 'en')).userMessage, contains('No internet'));
      expect((await capture(sock(), 'de')).userMessage,
          contains('Keine Internetverbindung'));
    });

    test('ClientException → connection message (EN/DE)', () async {
      MockClient conn() =>
          MockClient((_) async => throw http.ClientException('boom'));
      expect((await capture(conn(), 'en')).userMessage,
          contains('Connection problem'));
      expect((await capture(conn(), 'de')).userMessage,
          contains('Verbindungsproblem'));
    });
  });

  test('network errors keep the midwife/doctor hint', () async {
    final msg = (await capture(
            MockClient((_) async => throw const SocketException('x')), 'de'))
        .userMessage;
    expect(msg, contains('Hebamme oder Ärztin'));
  });

  test('successful 200 returns the coach text', () async {
    final mock = MockClient((_) async => http.Response(
        '{"content":[{"text":"Gut gemacht!"}]}', 200));
    expect(await callPerMeal(mock, 'de'), 'Gut gemacht!');
  });
}
