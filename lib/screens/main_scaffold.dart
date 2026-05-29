import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/meal_providers.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'tips_screen.dart';
import 'trends_screen.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  final Set<int> _visited = {0};

  @override
  void initState() {
    super.initState();
    // First-time tips deck: shown once per install in front of MainScaffold.
    // Covers both the after-onboarding case (new user) and the first launch
    // after the update that introduced the deck (existing testers) — the
    // hasSeenTipsV1 flag is set only when the user finishes or skips it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(settingsRepositoryProvider).hasSeenTipsV1()) return;
      ref.read(analyticsServiceProvider).capture('tips_shown');
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TipsScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(selectedTabProvider);
    _visited.add(index);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          _visited.contains(0) ? const HomeScreen() : const SizedBox.shrink(),
          _visited.contains(1) ? const HistoryScreen() : const SizedBox.shrink(),
          _visited.contains(2) ? const TrendsScreen() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          ref.read(selectedTabProvider.notifier).state = i;
          const names = ['diary', 'history', 'trends'];
          ref.read(analyticsServiceProvider).screen(names[i]);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: l10n.tabDiary,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l10n.tabHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.tabTrends,
          ),
        ],
      ),
    );
  }
}
