import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../l10n/app_localizations.dart';
import '../models/meal_entry.dart';
import '../models/meal_entry_source.dart';
import '../widgets/nutrition_header/macro_detail_modal.dart';
import '../widgets/nutrition_header/micro_detail_modal.dart';
import '../widgets/nutrition_header/nutrition_header.dart';
import '../models/thread_item.dart';
import '../providers/meal_providers.dart';
import '../providers/ui_providers.dart';
import '../services/claude_client.dart';
import '../services/coach_session_manager.dart';
import '../widgets/empty/empty_today.dart';
import 'confirm_screen.dart';
import 'diary/coach_bubble.dart';
import 'diary/home_input.dart';
import 'diary/thread_meal_card.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  final Map<String, GlobalKey> _mealKeys = {};
  // True while a programmatic scroll is running. Suppresses both the
  // scroll-up-to-load-more trigger and the auto-follow-to-bottom on item add,
  // so a Verlauf-tap or post-save scroll lands cleanly.
  bool _programmaticScroll = false;
  // When true the diary hides coach bubbles, user questions and answers, so
  // the day reads as a plain list of what was eaten.
  bool _mealsOnly = false;
  int _lastTotalItemCount = 0;
  // Snapshot of meal IDs we last saw in the rendered thread; used to detect
  // genuinely-new meals (just saved) versus older meals appearing because the
  // user loaded an older day.
  Set<String> _lastThreadMealIds = <String>{};
  // Last scroll-to-day target we already scheduled a scroll for; prevents
  // double-firing when the provider value bounces through rebuilds.
  DateTime? _handledScrollToDay;
  // Last scrollToBottomRequest bump value we already acted on. Used to skip
  // the existing bump on first build (initial state == 0) so we don't
  // jump to bottom every time the diary opens.
  int? _handledScrollToBottomBump;
  // Direction-aware jump FAB. Tracks the last meaningful scroll direction
  // so the FAB matches the user's intent: scrolling down → offer "jump to
  // bottom", scrolling up → offer "jump to top". Hidden when at the edge
  // in the same direction (already at top / already at bottom).
  // null = no FAB visible.
  _ScrollDir? _scrollDir;
  double _lastScrollPixels = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyForMeal(String mealId) =>
      _mealKeys.putIfAbsent(mealId, () => GlobalKey());

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    // Single-day-view doesn't auto-load older days: history navigation
    // happens via the AppBar date picker. Older "scroll up = load more"
    // plumbing was retired in phase 7 of the diary refactor.
    //
    // Direction-aware FAB. Use a small dead zone (8px) so micro-jitter
    // doesn't flip the icon. Hide when there isn't enough room to scroll
    // in that direction (already near the edge).
    final delta = pos.pixels - _lastScrollPixels;
    _ScrollDir? next = _scrollDir;
    if (delta > 8) {
      // Scrolling down (toward bottom / today). Offer jump-to-bottom.
      next = pos.maxScrollExtent - pos.pixels > 400 ? _ScrollDir.down : null;
    } else if (delta < -8) {
      // Scrolling up (away from today, into history). Offer jump-to-top.
      next = pos.pixels > 400 ? _ScrollDir.up : null;
    }
    _lastScrollPixels = pos.pixels;
    if (next != _scrollDir) {
      setState(() => _scrollDir = next);
    }
  }

  void _scrollToTop({bool animate = true}) {
    if (!_scroll.hasClients) return;
    if (animate) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(0);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scroll.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(
          pos,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(pos);
      }
    });
  }

  // Scrolls a keyed widget to the top of the viewport. Retries with growing
  // delays because the IndexedStack tab swap + ListView layout can take more
  // than one frame to settle, and the GlobalKey's currentContext / RenderBox
  // is null until then.
  // ignore_for_file: use_build_context_synchronously
  Future<void> _scrollKeyToTop(GlobalKey key) async {
    _programmaticScroll = true;
    for (var attempt = 0; attempt < 12; attempt++) {
      if (!mounted) {
        _programmaticScroll = false;
        return;
      }
      final ctx = key.currentContext;
      final renderObject = ctx?.findRenderObject();
      if (ctx != null &&
          renderObject is RenderBox &&
          renderObject.attached &&
          _scroll.hasClients) {
        try {
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            alignment: 0.0,
            alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
            curve: Curves.easeOut,
          );
          _programmaticScroll = false;
          return;
        } catch (_) {
          // Fall through to retry.
        }
      }
      await Future.delayed(const Duration(milliseconds: 80));
    }
    _programmaticScroll = false;
  }

  Future<void> _scrollToNewMeal(String mealId) async {
    final key = _mealKeys[mealId];
    if (key == null) return;
    await _scrollKeyToTop(key);
  }

  // _logForDay (the past-day-input-sheet entry point) has been retired in
  // the Single-Day-View refactor. Past-day logging now happens by switching
  // focusedDay via the AppBar picker and using the normal input bar; the
  // confirm sheet's date/time pill carries the right createdAt.

  // Title that the AppBar shows above the diary. Today and yesterday get
  // their named-day form; older days are formatted as "weekday, day. month"
  // (e.g. "So, 8. Juni" / "Sun, 8 Jun") using the locale's short month.
  String _focusedDayTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final focused = ref.watch(focusedDayProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final delta = today.difference(focused).inDays;
    if (delta == 0) return l10n.todayHeader;
    if (delta == 1) return l10n.yesterdayHeader;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final weekday = intl.DateFormat.E(localeTag).format(focused);
    final dayMonth = intl.DateFormat.MMMd(localeTag).format(focused);
    return '$weekday, $dayMonth';
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = ref.read(focusedDayProvider);
    final l10n = AppLocalizations.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: l10n.homeOpenDayHelp,
      cancelText: l10n.commonCancel,
      confirmText: 'OK',
    );
    if (picked == null) return;
    final normalized = DateTime(picked.year, picked.month, picked.day);
    // Drives the Single-Day-View: NutritionHeader, thread body and AppBar
    // title all rebind to this day. Phase-2 follow-up: replace this dialog
    // with the briefed month-calendar popover that shows dotted logged days.
    ref.read(focusedDayProvider.notifier).state = normalized;
    ref.read(scrollToDayProvider.notifier).state = normalized;
  }

  @override
  Widget build(BuildContext context) {
    // Single-day-view: body binds to the focused day's thread directly.
    // Multi-day plumbing (loadedDaysProvider / loadedThreadProvider) was
    // retired in phase 7 of the diary refactor.
    final focusedDayItems =
        ref.watch(focusedDayThreadProvider).valueOrNull ?? const [];
    final coachLoading = ref.watch(insightLoadingProvider);
    final mealsAll = ref.watch(mealsProvider).valueOrNull ?? const [];
    // kcal / macro / micronutrient totals are now consumed by
    // NutritionHeader directly via providers, so the diary build no
    // longer needs to recompute them locally.

    // Detect genuinely-new meals by looking at the thread itself: we collect
    // all meal IDs currently rendered and diff against the previous snapshot.
    // This catches the moment the new meal's ThreadItem lands in
    // loadedThreadProvider (the mealsAll stream often fires earlier, before
    // the card is actually in the tree, so scrolling then would miss the key).
    final currentThreadMealIds = <String>{};
    for (final item in focusedDayItems) {
      if (item.type == ThreadItemType.meal && item.mealId != null) {
        currentThreadMealIds.add(item.mealId!);
      }
    }
    final newlyRenderedMealIds =
        currentThreadMealIds.difference(_lastThreadMealIds);
    final mealsById = {for (final m in mealsAll) m.id: m};
    String? scrollTargetMealId;
    DateTime? newestNewTime;
    for (final id in newlyRenderedMealIds) {
      final m = mealsById[id];
      if (m == null) continue;
      // Only treat as "just saved" if it was created in the last 60 seconds.
      // Older meals appearing because the user loaded a past day shouldn't
      // hijack the scroll position.
      if (DateTime.now().difference(m.createdAt).inSeconds < 60) {
        if (newestNewTime == null || m.createdAt.isAfter(newestNewTime)) {
          newestNewTime = m.createdAt;
          scrollTargetMealId = id;
        }
      }
    }
    final totalItems = focusedDayItems.length;
    // Peek scroll-to-day target before the autoscroll heuristics fire so a
    // pending day-jump from Verlauf doesn't get overridden by the
    // "follow new bottom" autoscroll when loadedDays grows.
    final pendingScrollTarget = ref.read(scrollToDayProvider);
    if (scrollTargetMealId != null) {
      final id = scrollTargetMealId;
      // Skip autoscroll while a bundle scan-session is open. Intermediate
      // saves (barcode → "+ noch einen scannen") would otherwise scroll
      // the diary under the modal - wasted work, leaves the position in a
      // weird intermediate state until the final save runs autoscroll
      // again. The final save naturally fires this dispatcher with the
      // bundle drained.
      final mid = ref.read(pendingScanBundleProvider).isNotEmpty;
      if (!mid) {
        final m = mealsById[id];
        final now = DateTime.now();
        final isToday = m != null &&
            m.createdAt.year == now.year &&
            m.createdAt.month == now.month &&
            m.createdAt.day == now.day;
        // Today + newest: scroll-to-bottom keeps the user anchored on the
        // input bar (chat-style mental model). Today + NOT newest (e.g.
        // backdated 7:30 entry while there's already lunch and dinner):
        // scroll-to-bottom would land on dinner instead of the new entry -
        // wrong. Fall back to scroll-to-meal so the user actually sees
        // what they just added. Past-day saves route through
        // scrollToDayProvider (preferred-meal path) below.
        bool isNewestToday = false;
        if (isToday) {
          isNewestToday = !mealsAll.any((other) =>
              other.id != m.id &&
              other.createdAt.year == m.createdAt.year &&
              other.createdAt.month == m.createdAt.month &&
              other.createdAt.day == m.createdAt.day &&
              other.createdAt.isAfter(m.createdAt));
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (isToday && isNewestToday) {
            _scrollToBottom();
          } else {
            _scrollToNewMeal(id);
          }
        });
      }
    } else if (totalItems > _lastTotalItemCount &&
        _lastTotalItemCount > 0 &&
        newlyRenderedMealIds.isEmpty &&
        pendingScrollTarget == null) {
      // A non-meal thread item was added (typically the coach response).
      // Only follow if user is still near the bottom.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _scroll.hasClients &&
            !_programmaticScroll) {
          final pos = _scroll.position;
          if (pos.maxScrollExtent - pos.pixels < 200) {
            _scrollToBottom();
          }
        }
      });
    }
    _lastTotalItemCount = totalItems;
    _lastThreadMealIds = currentThreadMealIds;

    // scrollToDayProvider in Single-Day-View: a request to "jump to this
    // day" just means flipping focusedDay over. The view re-renders with
    // that day's items; no scroll-key juggling needed. If a freshly-saved
    // meal lives on that day, scroll to it after the focused-day switch
    // has settled.
    final scrollTarget = ref.watch(scrollToDayProvider);
    if (scrollTarget != null && scrollTarget != _handledScrollToDay) {
      _handledScrollToDay = scrollTarget;
      final normalized = DateTime(
          scrollTarget.year, scrollTarget.month, scrollTarget.day);
      String? preferredMealId;
      if (scrollTargetMealId != null) {
        final m = mealsById[scrollTargetMealId];
        if (m != null) {
          final mealDay = DateTime(
              m.createdAt.year, m.createdAt.month, m.createdAt.day);
          if (mealDay == normalized) preferredMealId = scrollTargetMealId;
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        ref.read(focusedDayProvider.notifier).state = normalized;
        // Let the stream emit and the new day's items render before we
        // try to scroll to the new meal.
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (!mounted) return;
        if (preferredMealId != null && _mealKeys.containsKey(preferredMealId)) {
          await _scrollToNewMeal(preferredMealId);
        }
        if (mounted) {
          ref.read(scrollToDayProvider.notifier).state = null;
          _handledScrollToDay = null;
        }
      });
    }

    // Explicit "scroll to bottom" request - currently bumped when the user
    // submits a chat question. Bypasses the ambient "near-bottom-only"
    // heuristic so a question typed while scrolled into yesterday still
    // surfaces the question (and the eventual reply) for the user.
    final scrollBottomBump = ref.watch(scrollToBottomRequestProvider);
    if (_handledScrollToBottomBump == null) {
      _handledScrollToBottomBump = scrollBottomBump;
    } else if (scrollBottomBump != _handledScrollToBottomBump) {
      _handledScrollToBottomBump = scrollBottomBump;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom();
      });
    }

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // The meals-only filter only helps once there's something to filter on
    // the focused day: at least one meal AND at least one coach bubble /
    // question / answer.
    final canFilter =
        focusedDayItems.any((i) => i.type == ThreadItemType.meal) &&
            focusedDayItems.any((i) => i.type != ThreadItemType.meal);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => _pickDate(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_focusedDayTitle(context)),
                const SizedBox(width: 2),
                Icon(Icons.arrow_drop_down, size: 22, color: scheme.outline),
              ],
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          if (canFilter)
          IconButton(
            icon: Icon(_mealsOnly
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
            tooltip: _mealsOnly
                ? AppLocalizations.of(context).diaryFilterShowAll
                : AppLocalizations.of(context).diaryFilterMealsOnly,
            onPressed: () {
              setState(() => _mealsOnly = !_mealsOnly);
              final l10n = AppLocalizations.of(context);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(_mealsOnly
                      ? l10n.diaryFilterOnMsg
                      : l10n.diaryFilterOffMsg),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppLocalizations.of(context).settingsTooltip,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          // Header height varies (~50px without micros, ~75px with).
          // Use a comfortable upper bound - Material clips/handles the
          // actual content height.
          preferredSize: const Size.fromHeight(82),
          child: Material(
            color: scheme.surface,
            elevation: 0,
            child: NutritionHeader(
              onMacroTap: (key) {
                final macro = switch (key) {
                  'kcal' => MacroKey.kcal,
                  'protein' => MacroKey.protein,
                  'carbs' => MacroKey.carbs,
                  'fat' => MacroKey.fat,
                  _ => null,
                };
                if (macro != null) showMacroDetailModal(context, macro);
              },
              onMicroTap: (key) => showMicroDetailModal(context, key),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.opaque,
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: _buildSlivers(
                      context: context,
                      ref: ref,
                      items: focusedDayItems,
                      mealsAll: mealsAll,
                      // IDs of meals whose coach call is currently in flight.
                      // _buildSlivers renders a thinking bubble after each
                      // such meal so multiple parallel calls (rapid logs)
                      // each get their own visible loading state.
                      inFlightMealIds: ref.watch(coachSessionProvider),
                      scheme: scheme,
                      textTheme: textTheme,
                      mealsOnly: _mealsOnly,
                    ),
                  ),
                ),
                if (_scrollDir != null)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      // Stable heroTag per direction so the swap doesn't
                      // throw a duplicate-tag exception during the rebuild.
                      heroTag: _scrollDir == _ScrollDir.up
                          ? 'scroll-top'
                          : 'scroll-bottom',
                      onPressed: _scrollDir == _ScrollDir.up
                          ? () => _scrollToTop()
                          : () {
                              // Dismiss the keyboard first when present -
                              // otherwise maxScrollExtent is measured with
                              // the input area pushed up, and the "bottom"
                              // we scroll to ends up partly hidden behind
                              // the keyboard / suggestion strip. ~280 ms
                              // matches the iOS keyboard collapse so the
                              // layout has settled before we measure again.
                              FocusScope.of(context).unfocus();
                              Future.delayed(
                                const Duration(milliseconds: 280),
                                _scrollToBottom,
                              );
                            },
                      tooltip: _scrollDir == _ScrollDir.up
                          ? AppLocalizations.of(context).homeScrollToTop
                          : AppLocalizations.of(context).homeScrollToBottom,
                      elevation: 2,
                      child: Icon(_scrollDir == _ScrollDir.up
                          ? Icons.arrow_upward
                          : Icons.arrow_downward),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // Coach-thinking banner sits directly above the input bar so the
       // cause / effect chain is visible: user taps send, banner appears
       // right next to where their finger was. Sticky so even if she
       // scrolls away in the diary the signal stays in view.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (coachLoading)
            CoachLoadingBanner(scheme: scheme, textTheme: textTheme),
          const HomeInput(),
        ],
      ),
    );
  }

  // Single-day thread body. Phase 2 of the diary refactor: the diary now
  // renders ONLY the focused day's items, top-to-bottom in chronological
  // order. No DaySeparator (the day is the AppBar title), no
  // EmptyDayRange (only one day visible at a time), no multi-day loop.
  //
  // Past days where the user logged nothing show a quiet empty-state
  // line below the header instead of the previous "Keine Einträge"
  // subtitle on the separator.
  List<Widget> _buildSlivers({
    required BuildContext context,
    required WidgetRef ref,
    required List<ThreadItem> items,
    required List<MealEntry> mealsAll,
    required Set<String> inFlightMealIds,
    required ColorScheme scheme,
    required TextTheme textTheme,
    bool mealsOnly = false,
  }) {
    final widgets = <Widget>[];
    final mealsById = {for (final m in mealsAll) m.id: m};

    // Past-day awareness: the "Coach pausiert" hint used to sit at the
    // top of the thread as a persistent banner. Beta feedback called it
    // "too in-your-face"; the cue now fires as a one-shot snackbar
    // appended to the save confirmation (see ConfirmScreen._appendToThread).
    // We still compute isPast because the empty-state copy varies.
    final focusedDay = ref.read(focusedDayProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPast = focusedDay.isBefore(today);

    // First-launch shortcut: no meals exist anywhere yet, show the
    // EmptyToday welcome card. Phase 5 swaps this for a per-day empty
    // state with paper-styled "Noch nichts geloggt" lettering.
    if (mealsAll.isEmpty) {
      widgets.add(const EmptyToday());
      return widgets;
    }

    if (items.isEmpty) {
      // Focused day has no items but the user has logged elsewhere.
      // Reuse the EmptyToday card so the past-day empty state matches
      // the today-empty visual (dotted border, icon, italic headline),
      // just with past-tense copy via isPast.
      widgets.add(EmptyToday(isPast: isPast));
      return widgets;
    }

    for (final item in items) {
      // Meals-only filter: skip coach bubbles, questions and answers so the
      // day reads as a plain log of what was eaten.
      if (mealsOnly && item.type != ThreadItemType.meal) continue;
      switch (item.type) {
        case ThreadItemType.meal:
          final meal = mealsById[item.mealId];
          if (meal == null) continue;
          widgets.add(KeyedSubtree(
            key: _keyForMeal(meal.id),
            child: ThreadMealCard(
              meal: meal,
              onEdit: () => _editMeal(context, meal),
              onDuplicate: () => _duplicateMeal(ref, meal),
              onDelete: () => _confirmDelete(context, ref, meal),
            ),
          ));
          // In-thread thinking bubble: appears directly after any meal
          // whose coach call is currently in flight. Suppressed in
          // meals-only mode (same as actual coach bubbles) so the
          // filtered view stays a plain log of what was eaten.
          if (!mealsOnly && inFlightMealIds.contains(meal.id)) {
            widgets.add(const CoachThinkingBubble());
          }
        case ThreadItemType.coachResponse:
          widgets.add(CoachBubble(
            text: item.text ?? '',
            isAnswer: false,
            mealId: item.mealId,
          ));
        case ThreadItemType.userQuestion:
          widgets.add(UserBubble(text: item.text ?? ''));
        case ThreadItemType.coachAnswer:
          widgets.add(CoachBubble(
            text: item.text ?? '',
            isAnswer: true,
            mealId: item.mealId,
          ));
      }
    }
    return widgets;
  }
}

enum _ScrollDir { up, down }

MealParseResult _toParseResult(MealEntry meal) => MealParseResult(
      isMeal: true,
      rejectionReason: null,
      summary: meal.summary,
      kcal: meal.kcal,
      proteinG: meal.proteinG,
      carbsG: meal.carbsG,
      fatG: meal.fatG,
      portionAmount: meal.portionAmount,
      portionUnit: meal.portionUnit,
      portionAlias: meal.portionAlias,
      safetyWarnings: meal.safetyWarnings,
    );

void _editMeal(BuildContext context, MealEntry meal) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ConfirmScreen(
        rawText: meal.rawText,
        parsed: _toParseResult(meal),
        existingMealId: meal.id,
        existingCreatedAt: meal.createdAt,
        source: MealEntrySource.edit,
      ),
    ),
  );
}

Future<void> _duplicateMeal(WidgetRef ref, MealEntry meal) async {
  // Anchor the duplicate to the day the user is CURRENTLY viewing - not the
  // original meal's day, not today. That matches the "I want this again"
  // intent: if I'm on Yesterday's diary and duplicate Yesterday's lunch,
  // the duplicate should appear under Yesterday. If I'm on Today, it
  // should appear under Today. With the old `DateTime.now()` default the
  // duplicate would silently land on Today even when the user was viewing
  // a past day, so they saw "nothing happen".
  //
  // For today's diary use the current wall-clock time; for a past day use
  // noon as a neutral anchor (no implicit "now" on a day that's over).
  final now = DateTime.now();
  final focused = ref.read(focusedDayProvider);
  final today = DateTime(now.year, now.month, now.day);
  final isToday = focused.year == today.year &&
      focused.month == today.month &&
      focused.day == today.day;
  final cloneTime = isToday
      ? now
      : DateTime(focused.year, focused.month, focused.day, 12, 0);
  final clone = MealEntry(
    id: now.microsecondsSinceEpoch.toString(),
    createdAt: cloneTime,
    rawText: meal.rawText,
    summary: meal.summary,
    kcal: meal.kcal,
    proteinG: meal.proteinG,
    carbsG: meal.carbsG,
    fatG: meal.fatG,
    portionAmount: meal.portionAmount,
    portionUnit: meal.portionUnit,
    portionAlias: meal.portionAlias,
    safetyWarnings: meal.safetyWarnings,
    // Carry micronutrient estimates - duplicate is semantically "same meal
    // again", not a re-parse. Dropping them would mean the donut sits at
    // half-credit on a double-portion day.
    micronutrients: meal.micronutrients,
  );
  await ref.read(mealRepositoryProvider).save(clone);
  await ref
      .read(threadRepositoryProvider)
      .add(ThreadItem.meal(mealId: clone.id, at: clone.createdAt));
}

Future<void> _confirmDelete(
    BuildContext context, WidgetRef ref, MealEntry meal) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.homeMealDeleteTitle(meal.summary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.commonDelete),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await ref.read(mealRepositoryProvider).delete(meal.id);
    await ref
        .read(threadRepositoryProvider)
        .removeMeal(meal.id, meal.createdAt);
  }
}
