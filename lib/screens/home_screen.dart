import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../l10n/app_localizations.dart';
import '../models/coach_response_type.dart';
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
import '../widgets/diary/month_calendar_popover.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dayFlipController;

  final _scroll = ScrollController();
  // Timestamp of the most-recent _scrollToBottom dispatch. Used to
  // coalesce rapid sequential scroll-to-bottom calls during the meal
  // save flow (meal-entry insert + coach-thinking bubble + coach reply
  // fire 3-4 scroll-to-bottom calls inside 500 ms, each animating 250 ms
  // → visible flicker). 300 ms cooldown collapses these into one.
  DateTime? _lastScrollDispatchAt;
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
  // Last scroll-to-meal target we already scheduled a scroll for.
  String? _handledScrollToMealId;
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
  // Direction of the most recent day-flip swipe. Drives the page-slide
  // animation on focusedDay change: swipe left (forward in time) makes
  // the new day slide in from the right; swipe right (back in time) from
  // the left. AppBar-picker / Today-button jumps default to no swipe
  // direction (treated as forward).
  _ScrollDir? _lastSwipeDir;
  double _lastScrollPixels = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _dayFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1.0, // start fully visible, no entrance animation
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _dayFlipController.dispose();
    super.dispose();
  }

  // Trigger the YAZIO-style page-slide on a day-flip: the body slides
  // in from the swipe direction. Single ListView, single ScrollController
  // (so no multi-position conflict like a two-child AnimatedSwitcher
  // would create); only the existing visual is re-animated as the new
  // day's items come in.
  void _runDayFlipAnimation() {
    _dayFlipController.forward(from: 0);
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

  void _scrollToBottom({bool animate = true, bool force = false}) {
    if (!_scroll.hasClients) return;
    // Coalesce rapid sequential scroll-to-bottoms (multi-bubble save
    // flow). If we just dispatched a scroll within the last 300 ms,
    // skip this one - the existing scroll is enough, and stacking
    // animations on top of each other reads as flicker. Callers that
    // need to bypass (e.g. user-triggered tab switch) can pass force.
    if (!force) {
      final now = DateTime.now();
      if (_lastScrollDispatchAt != null &&
          now.difference(_lastScrollDispatchAt!) <
              const Duration(milliseconds: 300)) {
        return;
      }
      _lastScrollDispatchAt = now;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(
          pos,
          duration: const Duration(milliseconds: 180),
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
          // Build +35 follow-up: ensureVisible occasionally NO-OPs on
          // iOS when the item is inside a SlideTransition + nested
          // ListView (tester report: "lands on yesterday but not at
          // the entry"). Verify the scroll actually positioned the
          // item near the top; if not, fall back to a manual
          // animateTo that computes the offset from the item's
          // RenderBox vs the viewport.
          if (renderObject.attached && _scroll.hasClients) {
            final viewportTop = _scroll.position.pixels;
            final viewportHeight = _scroll.position.viewportDimension;
            final itemTopInViewport =
                renderObject.localToGlobal(Offset.zero).dy;
            final itemAbsoluteOffset = viewportTop + itemTopInViewport;
            // If the item's top isn't within 60 px of the viewport
            // top after ensureVisible, force-animate.
            if (itemTopInViewport < -10 ||
                itemTopInViewport > viewportHeight * 0.4) {
              final target = itemAbsoluteOffset.clamp(
                0.0,
                _scroll.position.maxScrollExtent,
              );
              await _scroll.animateTo(
                target,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          }
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
  // True when the diary is sitting on today (the most common case). Drives
  // the conditional Today-jump button in the AppBar - hidden when there's
  // nowhere to jump back to.
  bool _isFocusedOnToday(WidgetRef ref) {
    final focused = ref.watch(focusedDayProvider);
    final now = DateTime.now();
    return focused.year == now.year &&
        focused.month == now.month &&
        focused.day == now.day;
  }

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

  // Opens the disclaimer bottom-sheet (Task #88.6). Reuses the same body
  // text shown in the onboarding disclaimer step so the legal surface
  // stays single-source. Once the standalone disclaimer page (#88.9) is
  // live we'll add a "Mehr dazu" link to it here.
  void _showDisclaimerSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.coachDisclaimerSheetTitle,
                style: Theme.of(sheetCtx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.onboardingDisclaimerBody,
                style: Theme.of(sheetCtx)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurface, height: 1.45),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: Text(l10n.coachDisclaimerSheetClose),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = ref.read(focusedDayProvider);
    // Pull the meal-day index off mealsByDayProvider so the popover can
    // render an amber dot under each day that has at least one entry.
    final mealsByDay = ref.read(mealsByDayProvider);
    final mealDays = mealsByDay.keys.toSet();
    final picked = await showMonthCalendarPopover(
      context,
      focused: initial,
      mealDays: mealDays,
      firstSelectable: DateTime(now.year - 1, now.month, now.day),
      lastSelectable: DateTime(now.year, now.month, now.day),
    );
    if (picked == null) return;
    final normalized = DateTime(picked.year, picked.month, picked.day);
    // Drives the Single-Day-View: NutritionHeader, thread body and AppBar
    // title all rebind to this day.
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
        } else {
          // Build +36-9 (Isabella): when switching days via the AppBar
          // date-picker (no specific meal target), jump to the top of
          // the new day's content so the user sees the start of that
          // day's chat, not whatever scroll position the previous day
          // was at (which was usually "end of today's chat"). jumpTo
          // instead of animateTo because the day-flip slide animation
          // already provides the transition cue.
          if (_scroll.hasClients) {
            _scroll.jumpTo(0);
          }
        }
        if (mounted) {
          ref.read(scrollToDayProvider.notifier).state = null;
          _handledScrollToDay = null;
        }
      });
    }

    // scrollToMealIdProvider: an explicit "scroll to THIS meal" request,
    // independent of the "60s recent" autoscroll heuristic. Set by retro
    // saves where the meal's stored time is far in the past (e.g. log a
    // breakfast at 16:00 for 08:00). Without this the autoscroll skips
    // the entry and the user sees the day's old top entry instead.
    final pendingMealScrollId = ref.watch(scrollToMealIdProvider);
    if (pendingMealScrollId != null &&
        pendingMealScrollId != _handledScrollToMealId) {
      _handledScrollToMealId = pendingMealScrollId;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        // Build +35 follow-up #2: a single 80ms wait was too tight when
        // the scroll-to-meal request rides alongside a day-switch
        // (past-day save). New approach: self-contained. The handler
        //  1) locates the meal in the latest mealsProvider snapshot,
        //  2) makes sure focusedDay matches the meal's day (does the
        //     switch itself if needed, instead of relying on a parallel
        //     scrollToDayProvider handler),
        //  3) waits in a retry loop until _mealKeys has the entry.
        // Up to ~2s total. The scrollToDayProvider handler may also
        // fire in parallel; that's fine - setting focusedDay twice to
        // the same value is a no-op.
        final mealsAll =
            ref.read(mealsProvider).valueOrNull ?? const <MealEntry>[];
        final meal = mealsAll.cast<MealEntry?>().firstWhere(
              (m) => m?.id == pendingMealScrollId,
              orElse: () => null,
            );
        if (meal != null) {
          final mealDay = DateTime(
              meal.createdAt.year, meal.createdAt.month, meal.createdAt.day);
          final focusedNow = ref.read(focusedDayProvider);
          final focusedKey =
              DateTime(focusedNow.year, focusedNow.month, focusedNow.day);
          if (mealDay != focusedKey) {
            ref.read(focusedDayProvider.notifier).state = mealDay;
          }
        }
        bool scrolled = false;
        for (var i = 0; i < 10; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          if (!mounted) return;
          if (_mealKeys.containsKey(pendingMealScrollId)) {
            await _scrollToNewMeal(pendingMealScrollId);
            scrolled = true;
            break;
          }
        }
        if (!scrolled) {
          debugPrint(
              'scrollToMealId: meal key never mounted for $pendingMealScrollId after 2s');
        }
        // Build +35 follow-up: trigger a 1.5 s highlight pulse on the
        // target meal card as a belt-and-braces visual anchor. Even if
        // the scroll didn't move the viewport as expected, the user
        // can see WHERE her new entry is.
        if (mounted) {
          ref.read(highlightedMealIdProvider.notifier).state =
              pendingMealScrollId;
          Future.delayed(const Duration(milliseconds: 1800), () {
            if (!mounted) return;
            final current = ref.read(highlightedMealIdProvider);
            if (current == pendingMealScrollId) {
              ref.read(highlightedMealIdProvider.notifier).state = null;
            }
          });
        }
        if (mounted) {
          ref.read(scrollToMealIdProvider.notifier).state = null;
          _handledScrollToMealId = null;
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
        title: Builder(
          builder: (ctx) {
            // Date IS the screen title (per Build +36 design rework).
            // On today: bare titleLarge + caret. On a past day: a
            // labelSmall Mono eyebrow ("VERGANGENER TAG") above, plus a
            // primaryContainer "Heute" chip next to the date as the
            // one-tap reset. Tap on the title/caret still opens the
            // date picker via _pickDate.
            final isToday = _isFocusedOnToday(ref);
            final l10nLocal = AppLocalizations.of(ctx);
            final dayTitle = _focusedDayTitle(ctx);
            final dateTrigger = InkWell(
              onTap: () => _pickDate(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayTitle,
                      style: textTheme.titleLarge?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: scheme.outline,
                      size: 22,
                    ),
                  ],
                ),
              ),
            );
            if (isToday) return dateTrigger;
            // Past day: eyebrow + date (no inline "Heute"-Chip). The
            // back-to-today TextButton lives in actions (right side) to
            // match the Apple/Google Calendar pattern - clearer action
            // affordance + no tap-target competition with the date tap.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10nLocal.diaryPastDayEyebrow.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                dateTrigger,
              ],
            );
          },
        ),
        centerTitle: false,
        actions: [
          // Today-jump: on past days, a single tap returns to today
          // (Apple/Google Calendar pattern). Hidden when already on today
          // so the action cluster stays calm. Build +36 v2: moved from
          // the title row back to actions per re-test feedback - the
          // inline chip read as a label, not an action.
          if (!_isFocusedOnToday(ref))
            TextButton(
              onPressed: () {
                final now = DateTime.now();
                ref.read(focusedDayProvider.notifier).state =
                    DateTime(now.year, now.month, now.day);
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 36),
                foregroundColor: scheme.primary,
              ),
              child: Text(AppLocalizations.of(context).todayHeader),
            ),
          // Disclaimer (Task #88.6). Sits at the LEFT of the action cluster
          // so the user's eye reaches it before the filter/settings group.
          // lock_outline is the most-generic "security/safety" glyph we
          // could pick - shield_outlined still read as a "warning" cue to
          // Vanessa; the lock is calm and doesn't suggest danger.
          //
          // Hidden on past days (today is the primary logging surface).
          if (_isFocusedOnToday(ref))
            IconButton(
              icon: const Icon(Icons.lock_outline),
              tooltip: AppLocalizations.of(context).coachDisclaimerBadge,
              onPressed: () => _showDisclaimerSheet(context),
            ),
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
                  // Horizontal swipe between days: a fast flick changes
                  // focusedDay by one. Slidable rows have their own
                  // horizontal-drag recognizer that wins inside their
                  // hit area, so meal-row swipe-actions keep working;
                  // this handler fires only on the empty space, the
                  // header overlap, and coach rows that aren't
                  // Slidable. Future days are blocked (no future logs
                  // in this MVP).
                  onHorizontalDragEnd: (details) {
                    final v = details.primaryVelocity ?? 0;
                    if (v.abs() < 250) return;
                    final focused = ref.read(focusedDayProvider);
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    if (v < 0) {
                      // Swipe left → forward in time (newer day). Cap
                      // at today.
                      final next = focused.add(const Duration(days: 1));
                      if (!next.isAfter(today)) {
                        HapticFeedback.lightImpact();
                        _lastSwipeDir = _ScrollDir.up;
                        ref.read(focusedDayProvider.notifier).state = next;
                        _runDayFlipAnimation();
                      }
                    } else {
                      // Swipe right → back in time (older day).
                      HapticFeedback.lightImpact();
                      _lastSwipeDir = _ScrollDir.down;
                      ref.read(focusedDayProvider.notifier).state =
                          focused.subtract(const Duration(days: 1));
                      _runDayFlipAnimation();
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SlideTransition(
                    // YAZIO-style page slide: the body slides in from
                    // the swipe direction whenever focusedDay flips.
                    // Begin offset: +x for swipe-left (new day comes
                    // from the right), -x for swipe-right. End at 0.
                    // Controller's `value: 1.0` initial means no
                    // entrance animation on first render.
                    position: Tween<Offset>(
                      begin: Offset(
                          _lastSwipeDir == _ScrollDir.down ? -1.0 : 1.0,
                          0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _dayFlipController,
                      curve: Curves.easeOutCubic,
                    )),
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
            responseType: item.responseType ?? CoachResponseType.normal,
          ));
        case ThreadItemType.userQuestion:
          widgets.add(UserBubble(text: item.text ?? ''));
        case ThreadItemType.coachAnswer:
          widgets.add(CoachBubble(
            text: item.text ?? '',
            isAnswer: true,
            mealId: item.mealId,
            responseType: item.responseType ?? CoachResponseType.normal,
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
