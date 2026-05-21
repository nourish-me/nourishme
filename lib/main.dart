import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/meal_providers.dart';
import 'screens/main_scaffold.dart';
import 'screens/onboarding_screen.dart';
import 'services/favorite_repository.dart';
import 'services/meal_repository.dart';
import 'services/settings_repository.dart';
import 'services/thread_repository.dart';
import 'theme/nourishme_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
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

class NourishMeApp extends ConsumerWidget {
  final bool showOnboarding;
  const NourishMeApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'NourishMe',
      // Field Manual palette. Hand-tuned brand colors instead of M3 auto-
      // generation. See lib/theme/nourishme_colors.dart for the tokens.
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      home: showOnboarding ? const OnboardingScreen() : const MainScaffold(),
    );
  }
}
