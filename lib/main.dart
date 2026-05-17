import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/meal_providers.dart';
import 'screens/main_scaffold.dart';
import 'services/meal_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  final mealRepo = await MealRepository.open();

  runApp(
    ProviderScope(
      overrides: [
        mealRepositoryProvider.overrideWithValue(mealRepo),
      ],
      child: const NurtureTrackApp(),
    ),
  );
}

class NurtureTrackApp extends StatelessWidget {
  const NurtureTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NurtureTrack',
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
