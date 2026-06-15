import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/meal_providers.dart';
import '../providers/ui_providers.dart';
import '../widgets/legacy_consent_migration_dialog.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Legacy-consent migration (#84): testers who onboarded before
      // the GDPR Art. 9 consent step landed have a profile but no
      // healthDataConsentAt. Without backfilling, the new
      // ClaudeClient gate would block every coach call. Show the
      // one-shot migration dialog FIRST, before the tips deck, so
      // they get one screen at a time (not stacked modals). The
      // dialog itself is non-dismissible and only pops once the
      // Pflicht-Box is ticked and confirmed.
      final settings = ref.read(settingsRepositoryProvider);
      if (settings.hasProfile() &&
          settings.getHealthDataConsentAt() == null) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const LegacyConsentMigrationDialog(),
        );
        if (!mounted) return;
      }
      // First-time tips deck: shown once per install in front of MainScaffold.
      // Covers both the after-onboarding case (new user) and the first launch
      // after the update that introduced the deck (existing testers) - the
      // hasSeenTipsV1 flag is set only when the user finishes or skips it.
      //
      // The presentation is delayed ~900 ms so the user sees the Diary land
      // first, then the deck slides up over it. Without the delay the deck
      // appeared instantly on top of onboarding's exit transition, which
      // felt like a jarring cut from one form to another.
      if (ref.read(settingsRepositoryProvider).hasSeenTipsV1()) return;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        ref.read(analyticsServiceProvider).capture('tips_shown');
        // Dismiss any lingering keyboard (e.g. from an onboarding text
        // field whose focus didn't release on the screen swap) before
        // pushing the deck, so the bottom half of the first tip card
        // isn't eaten by the keyboard.
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            transitionDuration: const Duration(milliseconds: 360),
            reverseTransitionDuration: const Duration(milliseconds: 240),
            pageBuilder: (ctx, anim, secAnim) => const TipsScreen(),
            transitionsBuilder: (ctx, anim, secAnim, child) {
              final curve = CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return FadeTransition(
                opacity: curve,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(curve),
                  child: child,
                ),
              );
            },
          ),
        );
      });
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
