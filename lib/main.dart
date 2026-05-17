import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/meal_providers.dart';
import 'screens/main_scaffold.dart';
import 'services/favorite_repository.dart';
import 'services/meal_repository.dart';
import 'services/settings_repository.dart';
import 'services/thread_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  final mealRepo = await MealRepository.open();
  final settingsRepo = await SettingsRepository.open();
  final favoriteRepo = await FavoriteRepository.open();
  final threadRepo = await ThreadRepository.open();

  runApp(
    ProviderScope(
      overrides: [
        mealRepositoryProvider.overrideWithValue(mealRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        favoriteRepositoryProvider.overrideWithValue(favoriteRepo),
        threadRepositoryProvider.overrideWithValue(threadRepo),
      ],
      child: const NourishMeApp(),
    ),
  );
}

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class NourishMeApp extends StatelessWidget {
  const NourishMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'NourishMe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F8A8B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MainScaffold(),
    );
  }
}
