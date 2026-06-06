import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/meal_entry.dart';
import '../models/meal_entry_source.dart';
import '../models/thread_item.dart';
import '../providers/meal_providers.dart';
import '../services/claude_client.dart';
import '../services/coach_session_manager.dart';
import '../utils/date_format.dart';
import '../widgets/empty/empty_today.dart';
import '../widgets/kcal_summary.dart';
import 'confirm_screen.dart';
import 'diary/coach_bubble.dart';
import 'diary/day_separator.dart';
import 'diary/home_input.dart';
import 'diary/past_day_input_sheet.dart';
import 'diary/thread_meal_card.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  final Map<String, GlobalKey> _dayHeaderKeys = {};
  final Map<String, GlobalKey> _mealKeys = {};
  // True while a programmatic scroll is running. Suppresses both the
  // scroll-up-to-load-more trigger and the auto-follow-to-bottom on item add,
  // so a Verlauf-tap or post-save scroll lands cleanly.
  bool _programmaticScroll = false;
  bool _loadingPreviousDay = false;
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

  String _keyStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  GlobalKey _keyForDay(DateTime d) =>
      _dayHeaderKeys.putIfAbsent(_keyStr(d), () => GlobalKey());

  GlobalKey _keyForMeal(String mealId) =>
      _mealKeys.putIfAbsent(mealId, () => GlobalKey());

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    // Trigger auto-load when within 200px of the top, but not during
    // programmatic scrolls (otherwise jumping to an old day starts loading
    // even older days and the user lands somewhere else).
    if (pos.pixels <= 200 &&
        !_loadingPreviousDay &&
        !_programmaticScroll) {
      _loadPreviousDay();
    }
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

  Future<void> _loadPreviousDay() async {
    if (_loadingPreviousDay) return;
    final days = ref.read(loadedDaysProvider);
    if (days.isEmpty) return;

    // Stop auto-loading once we've walked back past the user's earliest
    // logged meal: the empty-day collapse means the new days don't push
    // the viewport down much, so the near-top trigger would re-fire in a
    // tight loop and the list visibly flickers.
    final mealsAll = ref.read(mealsProvider).valueOrNull ?? const [];
    if (mealsAll.isEmpty) return;
    final earliestMealDay = mealsAll
        .map((m) =>
            DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    // Allow a single 7-day grace window past the earliest meal so the user
    // can scroll back a bit further for context, then stop.
    final stopAt = earliestMealDay.subtract(const Duration(days: 7));
    if (!days.first.isAfter(stopAt)) return;

    // Also hard-cap at 60 days of loaded history so we don't grow the list
    // unboundedly. Older days are reachable via the Verlauf tap-into-day.
    if (days.length >= 60) return;

    _loadingPreviousDay = true;
    final prevMax = _scroll.position.maxScrollExtent;
    final prevOffset = _scroll.offset;
    const batch = 7;
    final oldest = days.first;
    final newDays = <DateTime>[
      for (int i = batch; i >= 1; i--) oldest.subtract(Duration(days: i)),
    ];
    ref.read(loadedDaysProvider.notifier).state = [...newDays, ...days];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) {
        _loadingPreviousDay = false;
        return;
      }
      final newMax = _scroll.position.maxScrollExtent;
      final delta = newMax - prevMax;
      if (delta > 0) {
        _scroll.jumpTo(prevOffset + delta);
      }
      // Hold the loading flag for a short cooldown so a near-top scroll
      // listener can't immediately re-fire while the user is still pulling.
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _loadingPreviousDay = false;
      });
    });
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

  Future<void> _scrollToDay(DateTime d) => _scrollKeyToTop(_keyForDay(d));

  Future<void> _scrollToNewMeal(String mealId) async {
    final key = _mealKeys[mealId];
    if (key == null) return;
    await _scrollKeyToTop(key);
  }

  // Bottom sheet listing every day in a collapsed empty-day range. Tapping
  // a day routes through the normal _logForDay path (past-day input sheet
  // with a time picker), so the user lands on the meal entry with the
  // correct day + time without going through the global calendar.
  Future<void> _pickDayInRange(DateTime start, DateTime end) async {
    final days = <DateTime>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => EmptyRangePickerSheet(days: days),
    );
    if (picked != null && mounted) {
      await _logForDay(picked);
    }
  }

  // Opens a small input sheet to log a meal for a specific (past) day.
  // The created meal's createdAt is overridden to noon of that day.
  Future<void> _logForDay(DateTime day) async {
    final controller = TextEditingController();
    final entry =
        await showModalBottomSheet<({String text, TimeOfDay time})?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return PastDayInputSheet(
          controller: controller,
          day: day,
        );
      },
    );
    controller.dispose();
    if (entry == null || entry.text.trim().isEmpty || !mounted) return;
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      final parsed = await ref.read(claudeClientProvider).parseMeal(
            entry.text,
            locale: Localizations.localeOf(context).languageCode,
            isPregnant: profile?.isPregnant ?? false,
            trimester: profile?.trimester,
            isLactating: (profile?.numChildrenNursing ?? 0) > 0,
          );
      if (!mounted || !parsed.isMeal) return;
      final createdAt = DateTime(
          day.year, day.month, day.day, entry.time.hour, entry.time.minute);
      if (!mounted) return;
      await showModalBottomSheet<MealEntry>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => ConfirmScreen(
          rawText: entry.text,
          parsed: parsed,
          existingCreatedAt: createdAt,
          asSheet: true,
          source: MealEntrySource.quickAdd,
        ),
      );
    } on CoachApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.userMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).commonGenericError)),
      );
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final loaded = ref.read(loadedDaysProvider);
    final initial = loaded.isNotEmpty ? loaded.last : now;
    final l10n = AppLocalizations.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      helpText: l10n.homeOpenDayHelp,
      cancelText: l10n.commonCancel,
      confirmText: 'OK',
    );
    if (picked == null) return;
    final normalized = DateTime(picked.year, picked.month, picked.day);
    final today = DateTime(now.year, now.month, now.day);
    final currentLoaded = ref.read(loadedDaysProvider);
    final hasDay = currentLoaded.any((d) =>
        d.year == normalized.year &&
        d.month == normalized.month &&
        d.day == normalized.day);
    if (!hasDay) {
      // Build contiguous range from picked day to today.
      final days = <DateTime>[];
      var cursor = normalized;
      while (!cursor.isAfter(today)) {
        days.add(cursor);
        cursor = cursor.add(const Duration(days: 1));
      }
      ref.read(loadedDaysProvider.notifier).state = days;
    }
    // Route through the same build-driven scroll handler that Verlauf uses.
    // Setting the provider triggers HomeScreen.build → schedules a
    // post-frame _scrollToDay with retries, which works regardless of
    // whether loadedDays just changed or not.
    ref.read(scrollToDayProvider.notifier).state = normalized;
  }

  @override
  Widget build(BuildContext context) {
    final loadedDays = ref.watch(loadedDaysProvider);
    final threadByDay =
        ref.watch(loadedThreadProvider).valueOrNull ?? const {};
    final coachLoading = ref.watch(insightLoadingProvider);
    final mealsAll = ref.watch(mealsProvider).valueOrNull ?? const [];
    final targetKcal = ref.watch(calorieTargetProvider);
    final macroTargets = ref.watch(macroTargetsProvider);

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final todayMeals = mealsAll
        .where((m) => m.createdAt.isAfter(todayDate))
        .toList();
    final totalKcal = todayMeals.fold<int>(0, (s, m) => s + m.kcal);
    final totalProtein =
        todayMeals.fold<double>(0, (s, m) => s + m.proteinG);
    final totalCarbs = todayMeals.fold<double>(0, (s, m) => s + m.carbsG);
    final totalFat = todayMeals.fold<double>(0, (s, m) => s + m.fatG);

    // Detect genuinely-new meals by looking at the thread itself: we collect
    // all meal IDs currently rendered and diff against the previous snapshot.
    // This catches the moment the new meal's ThreadItem lands in
    // loadedThreadProvider (the mealsAll stream often fires earlier, before
    // the card is actually in the tree, so scrolling then would miss the key).
    final currentThreadMealIds = <String>{};
    for (final items in threadByDay.values) {
      for (final item in items) {
        if (item.type == ThreadItemType.meal && item.mealId != null) {
          currentThreadMealIds.add(item.mealId!);
        }
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
    final totalItems = threadByDay.values.fold<int>(0, (s, l) => s + l.length);
    // Peek scroll-to-day target before the autoscroll heuristics fire so a
    // pending day-jump from Verlauf doesn't get overridden by the
    // "follow new bottom" autoscroll when loadedDays grows.
    final pendingScrollTarget = ref.read(scrollToDayProvider);
    if (scrollTargetMealId != null) {
      final id = scrollTargetMealId;
      // Skip autoscroll while a bundle scan-session is open. Intermediate
      // saves (barcode → "+ noch einen scannen") would otherwise scroll
      // the diary under the modal — wasted work, leaves the position in a
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
        // scroll-to-bottom would land on dinner instead of the new entry —
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
            !_loadingPreviousDay &&
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

    // Watch (not listen) the scroll-to-day signal so the schedule lives inside
    // the same build cycle as the loadedDays change. The post-frame fires
    // after this build's render, when the day header's GlobalKey is attached.
    final scrollTarget = ref.watch(scrollToDayProvider);
    if (scrollTarget != null && scrollTarget != _handledScrollToDay) {
      _handledScrollToDay = scrollTarget;
      // Pick the scroll destination on the target day.
      //   - Past-day SAVE: a freshly-rendered meal landed in that day
      //     (scrollTargetMealId from newlyRenderedMealIds above). Prefer
      //     it so the user lands on the entry they just added, not on
      //     the day's earliest meal that happens to share the date.
      //   - Calendar/Verlauf TAP: no new meal involved → fall back to
      //     first-of-day so the user starts at the breakfast end.
      //   - Empty day: scroll to the day separator itself.
      String? preferredMealId;
      if (scrollTargetMealId != null) {
        final m = mealsById[scrollTargetMealId];
        if (m != null) {
          final mealDay = DateTime(
              m.createdAt.year, m.createdAt.month, m.createdAt.day);
          if (mealDay == scrollTarget) preferredMealId = scrollTargetMealId;
        }
      }
      String? targetMealId = preferredMealId;
      if (targetMealId == null) {
        final dayItems = threadByDay[scrollTarget] ?? const <ThreadItem>[];
        targetMealId = dayItems
            .firstWhere(
              (i) => i.type == ThreadItemType.meal,
              orElse: () => ThreadItem.userQuestion(text: '', at: DateTime(0)),
            )
            .mealId;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        debugPrint('scrollToDay: target=$scrollTarget targetMealId=$targetMealId '
            'preferredFromNewMeal=${preferredMealId != null} '
            'mealKeyKnown=${targetMealId != null && _mealKeys.containsKey(targetMealId)} '
            'dayKeyCtx=${_keyForDay(scrollTarget).currentContext != null}');
        if (targetMealId != null && _mealKeys.containsKey(targetMealId)) {
          await _scrollToNewMeal(targetMealId);
        } else {
          await _scrollToDay(scrollTarget);
        }
        if (mounted) {
          ref.read(scrollToDayProvider.notifier).state = null;
          _handledScrollToDay = null;
        }
      });
    }

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // The meals-only filter only helps once there's something to filter: at
    // least one meal AND at least one coach bubble / question / answer.
    final allThreadItems = threadByDay.values.expand((l) => l);
    final canFilter =
        allThreadItems.any((i) => i.type == ThreadItemType.meal) &&
            allThreadItems.any((i) => i.type != ThreadItemType.meal);

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
                Text(AppLocalizations.of(context).todayHeader),
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
          preferredSize: const Size.fromHeight(72),
          child: Material(
            color: scheme.surface,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: KcalSummary(
                totalKcal: totalKcal,
                targetKcal: targetKcal,
                protein: totalProtein,
                carbs: totalCarbs,
                fat: totalFat,
                macroTargets: macroTargets,
              ),
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
                      loadedDays: loadedDays,
                      threadByDay: threadByDay,
                      mealsAll: mealsAll,
                      coachLoading: coachLoading,
                      // Id of the most recent meal in the current coach
                      // session bundle, if any. Used by _buildSlivers to
                      // inject the in-thread thinking bubble right after
                      // that meal so the loading state is visible exactly
                      // where the user just confirmed an entry.
                      // IDs of meals whose coach call is currently in flight.
                      // _buildSlivers renders a thinking bubble after each
                      // such meal, so multiple parallel calls (rapid logs)
                      // each get their own visible loading state.
                      inFlightMealIds: ref.watch(coachSessionProvider),
                      scheme: scheme,
                      textTheme: textTheme,
                      mealsOnly: _mealsOnly,
                      // A day jumped-to from Verlauf / DatePicker stays
                      // expanded as its own day separator + empty row even
                      // if it has no entries, so the user can land on it
                      // and add a meal.
                      expandedEmptyDay: scrollTarget,
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
                              // Dismiss the keyboard first when present —
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

  List<Widget> _buildSlivers({
    required BuildContext context,
    required WidgetRef ref,
    required List<DateTime> loadedDays,
    required Map<DateTime, List<ThreadItem>> threadByDay,
    required List<MealEntry> mealsAll,
    required bool coachLoading,
    required Set<String> inFlightMealIds,
    required ColorScheme scheme,
    required TextTheme textTheme,
    bool mealsOnly = false,
    DateTime? expandedEmptyDay,
  }) {
    // Loaded days are stored newest-last (today at the end). Render top-down
    // so older days are above, today is at the bottom.
    final sortedDays = [...loadedDays]..sort((a, b) => a.compareTo(b));
    final widgets = <Widget>[];

    // Auto-load happens within a frame or two from Hive, so the spinner
    // just flickers briefly the first time the user pulls up, removed
    // for less visual noise. The empty-day-collapse divider already
    // signals the boundary.

    final mealsById = {for (final m in mealsAll) m.id: m};

    // First-launch shortcut: no meals exist anywhere yet. Show the
    // prominent EmptyToday welcome card once instead of stacking day
    // separators + small inline "Keine Einträge" rows for every loaded
    // empty day.
    if (mealsAll.isEmpty) {
      widgets.add(const EmptyToday());
      return widgets;
    }

    // Collapse consecutive empty days into a single discreet range row so the
    // scroll-back through long empty stretches doesn't fill the screen with
    // repeated "Keine Einträge" rows. Today is always shown explicitly so the
    // user can still log into it via the input bar.
    DateTime? emptyRunStart;
    DateTime? emptyRunEnd;

    void flushEmptyRun() {
      if (emptyRunStart == null) return;
      final rangeStart = emptyRunStart!;
      final rangeEnd = emptyRunEnd!;
      widgets.add(EmptyDayRange(
        start: rangeStart,
        end: rangeEnd,
        scheme: scheme,
        textTheme: textTheme,
        onTap: () => _pickDayInRange(rangeStart, rangeEnd),
      ));
      widgets.add(const SizedBox(height: 4));
      emptyRunStart = null;
      emptyRunEnd = null;
    }

    for (final day in sortedDays) {
      final items = threadByDay[day] ?? const <ThreadItem>[];
      final isToday = isSameDay(day, DateTime.now());
      final isExpanded =
          expandedEmptyDay != null && isSameDay(day, expandedEmptyDay);

      if (items.isEmpty && !isToday && !isExpanded) {
        // Extend the current empty run rather than rendering a full row.
        emptyRunStart ??= day;
        emptyRunEnd = day;
        continue;
      }

      // We hit a day with content (or today). Flush any pending empty run
      // first, then render the day separator + content normally.
      flushEmptyRun();
      widgets.add(DaySeparator(
        key: _keyForDay(day),
        day: day,
        scheme: scheme,
        textTheme: textTheme,
      ));
      if (items.isEmpty) {
        // Today's row still gets the quick-add affordance.
        widgets.add(EmptyDay(
          scheme: scheme,
          textTheme: textTheme,
          onAdd: () => _logForDay(day),
        ));
        widgets.add(const SizedBox(height: 8));
        continue;
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
              widgets.add(const SizedBox(height: 8));
              widgets.add(const CoachThinkingBubble());
            }
          case ThreadItemType.coachResponse:
            widgets.add(CoachBubble(text: item.text ?? '', isAnswer: false));
          case ThreadItemType.userQuestion:
            widgets.add(UserBubble(text: item.text ?? ''));
          case ThreadItemType.coachAnswer:
            widgets.add(CoachBubble(text: item.text ?? '', isAnswer: true));
        }
        widgets.add(const SizedBox(height: 8));
      }
    }
    // If the entire range ended on empty days (most common when paging back),
    // flush whatever's left.
    flushEmptyRun();
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
  final clone = MealEntry(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    createdAt: DateTime.now(),
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
