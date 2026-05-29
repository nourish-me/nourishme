import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/meal_providers.dart';

// One-shot "how to get the most out of the app" deck shown once per install,
// after onboarding (for new users) or on first open after the build that
// introduced the deck (for existing testers). The seen-flag is versioned via
// SettingsRepository.hasSeenTipsV1, so future iterations can refresh the
// deck without permanently locking earlier users out.
//
// Routing: pushed by main.dart in front of MainScaffold when hasProfile is
// true and hasSeenTipsV1 is false. The "Done" / "Skip" actions both mark the
// flag and replace the route with MainScaffold.
class TipsScreen extends ConsumerStatefulWidget {
  const TipsScreen({super.key});

  @override
  ConsumerState<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends ConsumerState<TipsScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(settingsRepositoryProvider).setTipsV1Seen();
    Navigator.of(context).pop();
  }

  void _next(int last) {
    if (_index >= last) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tips = <_Tip>[
      _Tip(
        icon: Icons.photo_camera_outlined,
        title: l10n.tip1Title,
        body: l10n.tip1Body,
      ),
      _Tip(
        icon: Icons.qr_code_scanner,
        title: l10n.tip2Title,
        body: l10n.tip2Body,
      ),
      _Tip(
        icon: Icons.lightbulb_outline,
        title: l10n.tip3Title,
        body: l10n.tip3Body,
      ),
      _Tip(
        icon: Icons.chat_bubble_outline,
        title: l10n.tip4Title,
        body: l10n.tip4Body,
      ),
      _Tip(
        icon: Icons.event_available_outlined,
        title: l10n.tip5Title,
        body: l10n.tip5Body,
      ),
    ];
    final lastIndex = tips.length - 1;
    final isLast = _index >= lastIndex;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tipsTitle),
        actions: [
          TextButton(
            onPressed: _finish,
            child: Text(l10n.tipsSkip),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: tips.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _TipPage(tip: tips[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < tips.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Container(
                      width: i == _index ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? scheme.primary
                            : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  Text(
                    l10n.tipsCounter(_index + 1, tips.length),
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => _next(lastIndex),
                    child: Text(isLast ? l10n.tipsDone : l10n.tipsNext),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip {
  final IconData icon;
  final String title;
  final String body;
  const _Tip({required this.icon, required this.title, required this.body});
}

class _TipPage extends StatelessWidget {
  final _Tip tip;
  const _TipPage({required this.tip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              tip.icon,
              size: 36,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            tip.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tip.body,
            style: textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
