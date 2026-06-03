import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/meal_providers.dart';
import '../../utils/coach_followups.dart';

// Coach + user bubbles rendered inline in the diary thread, plus the
// rose-tinted thinking placeholder shown while a coach call is in
// flight, plus the standalone loading banner above the chat input.
// All grouped here because they share the coach-conversation visual
// language (amber container + tertiary tone for placeholders).

class CoachBubble extends ConsumerWidget {
  final String text;
  final bool isAnswer;
  const CoachBubble({super.key, required this.text, required this.isAnswer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Light mode keeps the warm amber-container chip look. Dark mode uses
    // a quieter neutral surface with an amber left rule, otherwise the
    // saturated dark-amber container reads as heavy/dominant against the
    // ink background.
    final bg = isDark ? scheme.surfaceContainerLow : scheme.secondaryContainer;
    final fg = isDark ? scheme.onSurface : scheme.onSecondaryContainer;
    final iconColor = scheme.secondary;
    final split = splitCoachResponse(text);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border(left: BorderSide(color: scheme.secondary, width: 3))
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.tips_and_updates_outlined,
                  size: 16,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MarkdownBody(
                  data: split.body,
                  styleSheet:
                      MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: TextStyle(color: fg, height: 1.35),
                    strong: TextStyle(color: fg, fontWeight: FontWeight.w700),
                    em: TextStyle(color: fg, fontStyle: FontStyle.italic),
                    listBullet: TextStyle(color: fg),
                    blockSpacing: 6,
                  ),
                ),
              ),
            ],
          ),
          if (split.followUps.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final chip in split.followUps)
                    ActionChip(
                      label: Text(chip),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      labelStyle: TextStyle(
                        color: fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      backgroundColor: bg,
                      side: BorderSide(
                        color: scheme.secondary.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                      onPressed: () {
                        final next = ref.read(
                                mealInputPrefillProvider.notifier).state?.version ?? 0;
                        ref.read(mealInputPrefillProvider.notifier).state =
                            MealInputPrefill(text: chip, version: next + 1);
                        ref
                            .read(mealInputFocusRequestProvider.notifier)
                            .state++;
                        ref.read(analyticsServiceProvider).capture(
                            'coach_chip_tapped');
                      },
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class UserBubble extends StatelessWidget {
  final String text;
  const UserBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}

// Quiet rose-tinted placeholder shown inline in the diary while a coach
// call is in flight for a given meal. The caller already gates rendering
// on the in-flight set, so this widget just draws — no provider lookup.
// Visual is intentionally quieter than CoachBubble so a real reply
// still stands out when it replaces this placeholder.
class CoachThinkingBubble extends StatelessWidget {
  const CoachThinkingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.homeCoachThinking,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onTertiaryContainer,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sticky banner shown above the input bar while the chat-question path
// is waiting for a coach reply. Lives in the bottomNavigationBar slot
// so it always reads as "loading near where you typed".
class CoachLoadingBanner extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  const CoachLoadingBanner(
      {super.key, required this.scheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.tertiaryContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context).homeCoachThinking,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onTertiaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
