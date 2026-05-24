import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';

import 'l10n/app_localizations.dart';
import 'providers/meal_providers.dart';
import 'screens/main_scaffold.dart';
import 'screens/onboarding_screen.dart';
import 'services/favorite_repository.dart';
import 'services/meal_repository.dart';
import 'services/notification_scheduler.dart';
import 'services/settings_repository.dart';
import 'services/thread_repository.dart';
import 'theme/nourishme_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();

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
  }());
  final hasProfile = settingsRepo.hasProfile();
  final themeMode = _parseThemeMode(settingsRepo.getThemeMode());

  runApp(
    ProviderScope(
      overrides: [
        mealRepositoryProvider.overrideWithValue(mealRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        favoriteRepositoryProvider.overrideWithValue(favoriteRepo),
        threadRepositoryProvider.overrideWithValue(threadRepo),
        themeModeProvider.overrideWith((ref) => themeMode),
      ],
      child: NourishMeApp(showOnboarding: !hasProfile),
    ),
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

class NourishMeApp extends ConsumerStatefulWidget {
  final bool showOnboarding;
  const NourishMeApp({super.key, required this.showOnboarding});

  @override
  ConsumerState<NourishMeApp> createState() => _NourishMeAppState();
}

class _NourishMeAppState extends ConsumerState<NourishMeApp> {
  void _onNotificationTap() {
    // Forward the static signal from NotificationScheduler into Riverpod so
    // _HomeInput (which reads via ref.watch) can pull focus on the next
    // build. Wrapped because the notifier may fire before ref is mounted.
    if (!mounted) return;
    ref.read(mealInputFocusRequestProvider.notifier).state++;
  }

  @override
  void initState() {
    super.initState();
    NotificationScheduler.tapNotifier.addListener(_onNotificationTap);
    // Cold-launch case: the notifier was bumped during init() before this
    // widget started listening. Pick that up now so the first frame already
    // routes through the focus path.
    if (NotificationScheduler.tapNotifier.value > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onNotificationTap());
    }
  }

  @override
  void dispose() {
    NotificationScheduler.tapNotifier.removeListener(_onNotificationTap);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
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
      home: widget.showOnboarding
          ? const OnboardingScreen()
          : const MainScaffold(),
    );
  }
}
