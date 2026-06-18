import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'l10n/app_localizations.dart';
import 'providers/meal_providers.dart';
import 'providers/ui_providers.dart';
import 'screens/main_scaffold.dart';
import 'screens/onboarding_screen.dart';
import 'services/favorite_repository.dart';
import 'services/meal_repository.dart';
import 'services/notification_scheduler.dart';
import 'services/safety_rules.dart';
import 'services/settings_repository.dart';
import 'services/thread_repository.dart';
import 'services/weight_repository.dart';
import 'theme/nourishme_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  // Load deterministic food-safety rules from assets/safety-rules.json
  // BEFORE any code path can call SafetyRules.* — the rule methods throw
  // if data isn't loaded, which surfaces a forgotten init immediately
  // instead of silently returning empty warnings. Same file is consumed
  // by the Cloudflare Worker output-post-check (Task #88.4) so deploys
  // stay in lockstep.
  await SafetyRules.initFromAsset();

  // Set the global Intl default locale from the device language so
  // intl.NumberFormat / DateFormat without an explicit locale produce
  // locale-correct output (EN thousand separators are commas, DE are dots).
  // initializeDateFormatting loads locale data for DateFormat used in the UI.
  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  intl.Intl.defaultLocale = deviceLocale.toLanguageTag();
  await initializeDateFormatting(intl.Intl.defaultLocale);
  // Preload Newsreader so the editorial headlines render without a flash
  // of fallback serif on first launch. Other Google Fonts (Inter,
  // JetBrainsMono) lazy-load on demand and are far less brand-critical.
  unawaited(
    GoogleFonts.pendingFonts([
      GoogleFonts.newsreader(fontWeight: FontWeight.w700),
      GoogleFonts.newsreader(
          fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
    ]),
  );
  final mealRepo = await MealRepository.open();
  final settingsRepo = await SettingsRepository.open();
  final favoriteRepo = await FavoriteRepository.open();
  final threadRepo = await ThreadRepository.open();
  final weightRepo = await WeightRepository.open();

  // Initialise the notification plugin BEFORE runApp so we don't miss the
  // cold-launch tap signal: if the user opened the app by tapping a meal
  // reminder, getNotificationAppLaunchDetails inside init() bumps the
  // tapNotifier, and NourishMeApp.initState picks it up on first frame.
  await NotificationScheduler.init();

  // Re-arm scheduled reminders in the background. The first launch is a
  // no-op (master is off by default); on subsequent launches it restores
  // any slot iOS dropped after an OS update or reinstall. We load
  // AppLocalizations for the device locale so the notification copy
  // matches the app's language (en / de).
  unawaited(() async {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = await AppLocalizations.delegate.load(
      AppLocalizations.supportedLocales.firstWhere(
        (l) => l.languageCode == deviceLocale.languageCode,
        orElse: () => AppLocalizations.supportedLocales.first,
      ),
    );
    await NotificationScheduler.rescheduleFor(
      settingsRepo.getReminders(),
      l10n,
    );
    // Build +35: also reconcile "if a meal was already logged today for
    // this reminder slot, suppress today's fire". Catches the case
    // where yesterday's save-time call to recomputeSkipsForToday
    // dropped silently (iOS background race) and the recurring chain
    // would otherwise nag the user.
    final mealsRepoNow = mealRepo;
    final todayMealTimes = mealsRepoNow
        .all()
        .where((m) {
          final now = DateTime.now();
          return m.createdAt.year == now.year &&
              m.createdAt.month == now.month &&
              m.createdAt.day == now.day;
        })
        .map((m) => m.createdAt)
        .toList();
    await NotificationScheduler.recomputeSkipsForToday(
      todayMealTimes: todayMealTimes,
      settings: settingsRepo.getReminders(),
      l10n: l10n,
    );
  }());
  final hasProfile = settingsRepo.hasProfile();
  final themeMode = _parseThemeMode(settingsRepo.getThemeMode());

  // Sentry: crash + unhandled-exception reporting. Wraps runApp so any
  // throw in the widget tree, zone, or platform channel makes it back
  // to a Sentry issue we can actually see. Skipped silently when no DSN
  // is configured so local dev doesn't depend on Sentry being up.
  final sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';
  void startApp() {
    runApp(
      ProviderScope(
        overrides: [
          mealRepositoryProvider.overrideWithValue(mealRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          favoriteRepositoryProvider.overrideWithValue(favoriteRepo),
          threadRepositoryProvider.overrideWithValue(threadRepo),
          weightRepositoryProvider.overrideWithValue(weightRepo),
          themeModeProvider.overrideWith((ref) => themeMode),
        ],
        child: NourishMeApp(showOnboarding: !hasProfile),
      ),
    );
  }

  if (sentryDsn.isEmpty) {
    startApp();
    return;
  }

  // Debug builds (Simulator + Hot Reload) generate spurious framework
  // assertions every time we edit a running app - duplicate GlobalKeys,
  // RenderFlex overflows, "TextEditingController after dispose", etc.
  // Routing those to Sentry pollutes the beta crash signal. Only init
  // Sentry for release builds.
  if (kDebugMode) {
    startApp();
    return;
  }

  final info = await PackageInfo.fromPlatform();
  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      // Tag every event with the build's identity so we can filter beta
      // crashes from later production ones once the App Store version
      // ships. Pulled from PackageInfo so a pubspec version bump auto-
      // syncs to Sentry without a hardcoded string drift.
      options.release = 'nourishme@${info.version}+${info.buildNumber}';
      options.environment = 'beta';
      // Trace sampling stays off - we only care about crashes + errors,
      // not performance traces. Keeps the free-tier event budget intact.
      options.tracesSampleRate = 0.0;
      // Privacy: never send default PII (IP, device-attached identifiers
      // beyond what the SDK strictly needs). Aligns with the local-first
      // promise on the landing page.
      options.sendDefaultPii = false;
      options.attachScreenshot = false;
    },
    appRunner: startApp,
  );
}

ThemeMode _parseThemeMode(String s) {
  switch (s) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Navigator observer that hides any active SnackBar whenever a route
// pushes or pops (Build +35 snackbar audit). The root ScaffoldMessenger
// is global, so without this hook a snackbar shown on screen A would
// keep blocking taps on screen B for the full 15 s duration. The audit
// covers all snackbars in the app (settings auto-save, important snack
// for retro saves, errors etc.) - cross-screen persistence was the
// "snack hält ewig" tester report.
class _SnackbarDismissOnNavObserver extends NavigatorObserver {
  // Set via [markPersistent] right before a `showSnackBar` whose snack
  // is supposed to outlive the immediately-following pop/push. Build
  // +35 follow-up: the importantSnack the confirm-sheet shows after a
  // past-day save was getting hidden the instant the sheet popped -
  // user never saw it. The flag is consumed on the first nav event.
  bool _suppressOnce = false;

  void markPersistent() {
    _suppressOnce = true;
  }

  void _dismiss() {
    if (_suppressOnce) {
      _suppressOnce = false;
      return;
    }
    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _dismiss();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _dismiss();
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _dismiss();
}

final snackbarDismissOnNavObserver = _SnackbarDismissOnNavObserver();

class NourishMeApp extends ConsumerWidget {
  final bool showOnboarding;
  const NourishMeApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      navigatorObservers: [snackbarDismissOnNavObserver],
      title: 'NourishMe',
      // Field Manual palette. Hand-tuned brand colors instead of M3 auto-
      // generation. See lib/theme/nourishme_colors.dart for the tokens.
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      // English primary, German for users whose device is set to de/at/ch.
      // No explicit locale override, MaterialApp picks from device locale,
      // falls back to AppLocalizations.supportedLocales (en first).
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: showOnboarding
          ? const OnboardingScreen()
          : const MainScaffold(),
    );
  }
}
