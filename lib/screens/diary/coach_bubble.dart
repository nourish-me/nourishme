import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart' show rootScaffoldMessengerKey;
import '../../providers/meal_providers.dart';
import '../../providers/ui_providers.dart';
import '../../utils/coach_followups.dart';

// Coach + user bubbles rendered inline in the diary thread, plus the
// transient placeholder shown while a coach call is in flight, plus
// the loading banner above the chat input.
//
// Time-Ledger layout (phase 4 of the Claude Design diary refactor):
// all three coach surfaces share the 44 px time column with the meal
// rows, sit on the same hairline-divider rhythm, and use a borderless
// amber-tinted "Bahn" (lane) for the body area instead of a card with
// rounded corners. The time column reads top-to-bottom across coach
// and meal entries as one continuous track.

// Shared column width so meal rows, coach bubbles, and user bubbles
// align on the same vertical track.
const double _timeColumnWidth = 44;

String _formatTimeLabel(DateTime t) {
  final tod = TimeOfDay.fromDateTime(t);
  return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
}

Widget _timeCell({
  required String label,
  required ColorScheme scheme,
  required TextTheme textTheme,
}) {
  return SizedBox(
    width: _timeColumnWidth,
    child: Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          textStyle: textTheme.labelSmall?.copyWith(
            color: scheme.outline,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _ledgerRowDecoration(ColorScheme scheme) => BoxDecoration(
      border: Border(
        bottom: BorderSide(color: scheme.outlineVariant, width: 0.5),
      ),
    );

class CoachBubble extends ConsumerWidget {
  final String text;
  final bool isAnswer;
  // mealId is the meal this coach reply was generated for. Used to anchor
  // the inline "ingredients today" reply input under THIS bubble when the
  // coach asked the question with this meal. Null is fine (older code
  // paths, fallback bubbles).
  final String? mealId;
  // Timestamp of the coach reply so the row aligns on the time ledger.
  final DateTime timestamp;
  const CoachBubble({
    super.key,
    required this.text,
    required this.isAnswer,
    required this.timestamp,
    this.mealId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Borderless amber lane: subtle secondaryContainer tint, no border,
    // no border-radius. Quieter in dark mode where the saturated
    // secondaryContainer reads as heavy against the ink background.
    final laneTint = scheme.secondaryContainer
        .withValues(alpha: isDark ? 0.35 : 0.55);
    final fg = scheme.onSurface;
    final iconColor = scheme.secondary;
    final split = splitCoachResponse(text);
    final ask = ref.watch(coachAskStateProvider);
    final showIngredientsInput = mealId != null &&
        ask.askedMealId == mealId &&
        ask.ingredients == null;
    return DecoratedBox(
      decoration: _ledgerRowDecoration(scheme),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _timeCell(
              label: _formatTimeLabel(timestamp),
              scheme: scheme,
              textTheme: textTheme,
            ),
            Expanded(
              child: ColoredBox(
                color: laneTint,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                      Theme.of(context))
                                  .copyWith(
                                p: TextStyle(color: fg, height: 1.35),
                                strong: TextStyle(
                                    color: fg,
                                    fontWeight: FontWeight.w600),
                                em: TextStyle(
                                    color: fg,
                                    fontStyle: FontStyle.italic),
                                listBullet: TextStyle(color: fg),
                                blockSpacing: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (showIngredientsInput) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(left: 26),
                          child: _IngredientsReplyInput(
                              fg: fg, scheme: scheme),
                        ),
                      ],
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
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide(
                                    color: scheme.secondary
                                        .withValues(alpha: 0.5),
                                    width: 0.8,
                                  ),
                                  onPressed: () {
                                    final next = ref
                                            .read(mealInputPrefillProvider
                                                .notifier)
                                            .state
                                            ?.version ??
                                        0;
                                    ref
                                        .read(mealInputPrefillProvider
                                            .notifier)
                                        .state = MealInputPrefill(
                                            text: chip,
                                            version: next + 1);
                                    ref
                                        .read(mealInputFocusRequestProvider
                                            .notifier)
                                        .state++;
                                    ref
                                        .read(analyticsServiceProvider)
                                        .capture('coach_chip_tapped');
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientsReplyInput extends ConsumerStatefulWidget {
  final Color fg;
  final ColorScheme scheme;
  const _IngredientsReplyInput({required this.fg, required this.scheme});

  @override
  ConsumerState<_IngredientsReplyInput> createState() =>
      _IngredientsReplyInputState();
}

class _IngredientsReplyInputState
    extends ConsumerState<_IngredientsReplyInput> {
  late final TextEditingController _c;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _c.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final snackText = AppLocalizations.of(context).coachIngredientsSavedSnack;
    await ref
        .read(coachAskStateProvider.notifier)
        .submitIngredients(text);
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(snackText),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _c,
            enabled: !_submitting,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
            style: TextStyle(color: widget.fg, fontSize: 14),
            decoration: InputDecoration(
              hintText: l10n.coachIngredientsReplyHint,
              hintStyle: TextStyle(
                color: widget.fg.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: widget.scheme.secondary.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: widget.scheme.secondary.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.scheme.secondary),
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.arrow_upward, size: 18),
          color: widget.scheme.secondary,
          onPressed: _submitting ? null : _submit,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}

class UserBubble extends StatelessWidget {
  final String text;
  final DateTime timestamp;
  const UserBubble({super.key, required this.text, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: _ledgerRowDecoration(scheme),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _timeCell(
              label: _formatTimeLabel(timestamp),
              scheme: scheme,
              textTheme: textTheme,
            ),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.right,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quiet placeholder shown inline in the diary while a coach call is in
// flight for a given meal. Sits on the same time-ledger row as a coach
// reply; the time column is left empty (no timestamp yet) and a small
// spinner replaces the tip icon.
class CoachThinkingBubble extends StatelessWidget {
  const CoachThinkingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final laneTint = scheme.tertiaryContainer
        .withValues(alpha: isDark ? 0.35 : 0.5);
    return DecoratedBox(
      decoration: _ledgerRowDecoration(scheme),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Empty time column - the reply hasn't been written yet.
            const SizedBox(width: _timeColumnWidth),
            Expanded(
              child: ColoredBox(
                color: laneTint,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                ),
              ),
            ),
          ],
        ),
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
