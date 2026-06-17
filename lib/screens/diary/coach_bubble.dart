import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart' show rootScaffoldMessengerKey;
import '../../models/coach_response_type.dart';
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
  // Safety-layer classification (Task #88.5). normal = default amber lane;
  // escalation/emergency/blocked switch the lane tint + icon so the user
  // immediately sees this is not a regular coach tip but a safety hand-off.
  final CoachResponseType responseType;
  const CoachBubble({
    super.key,
    required this.text,
    required this.isAnswer,
    this.mealId,
    this.responseType = CoachResponseType.normal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Lane styling per response type. Normal = the established amber
    // "Bahn" at 10/18% alpha. Emergency = error tone, prominent.
    // Escalation/blocked = tertiary or error-container, distinct from
    // a normal coach tip but not as loud as emergency.
    final (laneTint, iconColor, leadIcon) = switch (responseType) {
      CoachResponseType.emergency => (
          scheme.errorContainer.withValues(alpha: isDark ? 0.55 : 0.40),
          scheme.error,
          Icons.emergency_outlined,
        ),
      CoachResponseType.escalation => (
          scheme.tertiaryContainer.withValues(alpha: isDark ? 0.45 : 0.30),
          scheme.tertiary,
          Icons.medical_services_outlined,
        ),
      CoachResponseType.blocked => (
          scheme.surfaceContainerHighest
              .withValues(alpha: isDark ? 0.85 : 0.70),
          scheme.outline,
          Icons.shield_outlined,
        ),
      CoachResponseType.normal => (
          scheme.secondary.withValues(alpha: isDark ? 0.18 : 0.10),
          scheme.secondary,
          Icons.tips_and_updates_outlined,
        ),
    };
    final fg = scheme.onSurface;
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
            // Coach rows sit on the same vertical track as meal rows so
            // the time column reads top-to-bottom, but the coach's own
            // bubble carries no timestamp - the user's mental model is
            // "the coach responded to my meal", not "the coach said
            // something at HH:MM". The tip icon below replaces the
            // time cell; an empty 44 px slot keeps it aligned with
            // meal rows.
            const SizedBox(width: _timeColumnWidth),
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
                              leadIcon,
                              size: 16,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MarkdownBody(
                              data: split.body,
                              // tel:112 tap-to-call for emergency bubbles
                              // (#111). Also accepts https:// (future
                              // disclaimer-page links). Failures degrade
                              // silently - the user sees the bubble text
                              // either way.
                              onTapLink: (text, href, title) async {
                                if (href == null || href.isEmpty) return;
                                final uri = Uri.tryParse(href);
                                if (uri == null) return;
                                try {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                } catch (_) {
                                  // ignore: the bubble still shows the number
                                }
                              },
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
                                a: TextStyle(
                                  color: iconColor,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
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
                                    // Task A1, Build +34: a chip tap fires
                                    // the coach question straight away
                                    // instead of pasting it into the input
                                    // (the prior paste-then-tap-send flow
                                    // was an unnecessary extra step that
                                    // beta testers consistently fumbled).
                                    final next = ref
                                            .read(coachSubmitRequestProvider
                                                .notifier)
                                            .state
                                            ?.version ??
                                        0;
                                    ref
                                        .read(coachSubmitRequestProvider
                                            .notifier)
                                        .state = CoachSubmitRequest(
                                            text: chip,
                                            version: next + 1);
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
  const UserBubble({super.key, required this.text});

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
            // Chat questions match coach rows: empty time slot, body
            // right-aligned to read as "your turn" in the conversation.
            const SizedBox(width: _timeColumnWidth),
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
    // Match the coach-bubble alpha rule so the thinking placeholder has
    // the same lane weight as a real reply - swapping in/out doesn't
    // visibly shift the column.
    final laneTint = scheme.tertiary
        .withValues(alpha: isDark ? 0.18 : 0.10);
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
