import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/meal_providers.dart';

// One-shot consent collection for testers who onboarded BEFORE the
// GDPR Art. 9 consent step landed. They have a profile but no
// healthDataConsentAt timestamp, so the new ClaudeClient gate would
// block every coach call ("Coaching ist noch nicht aktiviert"). This
// dialog appears on the next app start, explains the new consent
// model in two sentences, and collects both ticks with the same
// rules as onboarding (Pflicht must be checked, Analytics is free).
//
// Non-dismissible: there's no "Verwerfen" path because the only way
// to keep using the app without consenting is to reset (handled
// separately via Settings). PopScope blocks back-swipe + Android
// back-button.
//
// Shows automatically from MainScaffold.initState when:
//   settings.hasProfile() && settings.getHealthDataConsentAt() == null
// Once both ticks are set + confirmed, getHealthDataConsentAt is
// non-null and the gate stops firing.
class LegacyConsentMigrationDialog extends ConsumerStatefulWidget {
  const LegacyConsentMigrationDialog({super.key});

  @override
  ConsumerState<LegacyConsentMigrationDialog> createState() =>
      _LegacyConsentMigrationDialogState();
}

class _LegacyConsentMigrationDialogState
    extends ConsumerState<LegacyConsentMigrationDialog> {
  bool _healthDataConsent = false;
  bool _analyticsConsent = false;

  Future<void> _confirm() async {
    final repo = ref.read(settingsRepositoryProvider);
    final now = DateTime.now();
    await repo.setHealthDataConsentAt(now);
    if (_analyticsConsent) {
      await repo.setAnalyticsConsentAt(now);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.legacyConsentTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.legacyConsentIntro,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _healthDataConsent,
                onChanged: (v) =>
                    setState(() => _healthDataConsent = v ?? false),
                title: Text(
                  l10n.onboardingConsentHealthDataLabel,
                  style: textTheme.bodyMedium,
                ),
                subtitle: Text(
                  l10n.onboardingConsentHealthDataRequired,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.secondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _analyticsConsent,
                onChanged: (v) =>
                    setState(() => _analyticsConsent = v ?? false),
                title: Text(
                  l10n.onboardingConsentAnalyticsLabel,
                  style: textTheme.bodyMedium,
                ),
                subtitle: Text(
                  l10n.onboardingConsentAnalyticsOptional,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(l10n.onboardingConsentPrivacyLink),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    final isDe = Localizations.localeOf(context)
                        .languageCode
                        .toLowerCase()
                        .startsWith('de');
                    final url = isDe
                        ? 'https://nourish-me.github.io/nourishme/privacy.html'
                        : 'https://nourish-me.github.io/nourishme/privacy-en.html';
                    launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: _healthDataConsent ? _confirm : null,
            child: Text(l10n.legacyConsentConfirm),
          ),
        ],
      ),
    );
  }
}
