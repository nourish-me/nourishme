import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../providers/meal_providers.dart';

// One-shot "how to get the most out of the app" deck shown once per install,
// after onboarding (for new users) or on first open after the build that
// introduced the deck (for existing testers). The seen-flag is versioned via
// SettingsRepository.hasSeenTipsV1, so future iterations can refresh the
// deck without permanently locking earlier users out.
//
// Routing: pushed by main_scaffold.dart after MainScaffold mounts and from
// the "Tipps erneut zeigen" button in Settings. Both Done / Skip mark the
// flag (via _finish) and pop the route.
//
// Illustrations: per-tip SVGs in assets/illustrations/, locale-suffixed
// (tip{N}_de.svg / tip{N}_en.svg) because some illustrations bake in short
// labels ("PRO 100 G", weekday letters, brand examples) that need to follow
// the app's language. The line colour is driven by currentColor so the
// SVGs blend with the active theme — pine in light mode, paper in dark.
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
    final localeCode =
        Localizations.localeOf(context).languageCode.toLowerCase();
    final assetSuffix = localeCode.startsWith('de') ? 'de' : 'en';
    final tips = <_Tip>[
      _Tip(
        asset: 'assets/illustrations/tip1_$assetSuffix.svg',
        title: l10n.tip1Title,
        body: l10n.tip1Body,
      ),
      _Tip(
        asset: 'assets/illustrations/tip2_$assetSuffix.svg',
        title: l10n.tip2Title,
        body: l10n.tip2Body,
      ),
      _Tip(
        asset: 'assets/illustrations/tip3_$assetSuffix.svg',
        title: l10n.tip3Title,
        body: l10n.tip3Body,
      ),
      _Tip(
        asset: 'assets/illustrations/tip4_$assetSuffix.svg',
        title: l10n.tip4Title,
        body: l10n.tip4Body,
      ),
      _Tip(
        asset: 'assets/illustrations/tip5_$assetSuffix.svg',
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
  final String asset;
  final String title;
  final String body;
  const _Tip({required this.asset, required this.title, required this.body});
}

class _TipPage extends StatelessWidget {
  final _Tip tip;
  const _TipPage({required this.tip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Drive the illustration's currentColor from the active theme so the line
    // work reads against both paper (light) and ink (dark) without shipping
    // separate light/dark assets. onSurface tracks the theme exactly.
    final lineColor = scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Center(
              child: SvgPicture.asset(
                tip.asset,
                fit: BoxFit.contain,
                // Drives only currentColor — leaves the amber accents
                // (#C8884A, hard-coded in the SVG) untouched. A colorFilter
                // would flatten everything to one tone.
                theme: SvgTheme(currentColor: lineColor),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
