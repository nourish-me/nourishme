import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/favorite_meal.dart';
import '../models/meal_entry.dart';
import '../models/thread_item.dart';
import '../providers/meal_providers.dart';
import '../services/claude_client.dart';
import '../utils/date_format.dart';
import '../utils/number_format.dart';
import '../widgets/empty/empty_today.dart';
import '../widgets/kcal_summary.dart';
import 'confirm_screen.dart';
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
      builder: (sheetContext) => _EmptyRangePickerSheet(days: days),
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
        return _PastDayInputSheet(
          controller: controller,
          day: day,
        );
      },
    );
    controller.dispose();
    if (entry == null || entry.text.trim().isEmpty || !mounted) return;
    try {
      final parsed = await ref.read(claudeClientProvider).parseMeal(
            entry.text,
            locale: Localizations.localeOf(context).languageCode,
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToNewMeal(id);
      });
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
      // Prefer scrolling to the EARLIEST meal of the tapped day (so the
      // user lands on breakfast, not dinner). thread items are already
      // sorted ascending by timestamp in the repository, so the first
      // ThreadItemType.meal entry is the day's earliest. Fall back to
      // the day-separator key when the day has no logged meals yet.
      final dayItems = threadByDay[scrollTarget] ?? const <ThreadItem>[];
      final firstMealId = dayItems
          .firstWhere(
            (i) => i.type == ThreadItemType.meal,
            orElse: () => ThreadItem.userQuestion(text: '', at: DateTime(0)),
          )
          .mealId;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (firstMealId != null && _mealKeys.containsKey(firstMealId)) {
          await _scrollToNewMeal(firstMealId);
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
                      scheme: scheme,
                      textTheme: textTheme,
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
                          : () => _scrollToBottom(),
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
            _CoachLoadingBanner(scheme: scheme, textTheme: textTheme),
          const _HomeInput(),
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
    required ColorScheme scheme,
    required TextTheme textTheme,
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
      widgets.add(_EmptyDayRange(
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
      widgets.add(_DaySeparator(
        key: _keyForDay(day),
        day: day,
        scheme: scheme,
        textTheme: textTheme,
      ));
      if (items.isEmpty) {
        // Today's row still gets the quick-add affordance.
        widgets.add(_EmptyDay(
          scheme: scheme,
          textTheme: textTheme,
          onAdd: () => _logForDay(day),
        ));
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      for (final item in items) {
        switch (item.type) {
          case ThreadItemType.meal:
            final meal = mealsById[item.mealId];
            if (meal == null) continue;
            widgets.add(KeyedSubtree(
              key: _keyForMeal(meal.id),
              child: _ThreadMealCard(
                meal: meal,
                onEdit: () => _editMeal(context, meal),
                onDuplicate: () => _duplicateMeal(ref, meal),
                onDelete: () => _confirmDelete(context, ref, meal),
              ),
            ));
          case ThreadItemType.coachResponse:
            widgets.add(_CoachBubble(text: item.text ?? '', isAnswer: false));
          case ThreadItemType.userQuestion:
            widgets.add(_UserBubble(text: item.text ?? ''));
          case ThreadItemType.coachAnswer:
            widgets.add(_CoachBubble(text: item.text ?? '', isAnswer: true));
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

class _CoachLoadingBanner extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _CoachLoadingBanner({required this.scheme, required this.textTheme});

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

class _DaySeparator extends StatelessWidget {
  final DateTime day;
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _DaySeparator({
    super.key,
    required this.day,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final label = formatDayHeader(context, day);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: scheme.outlineVariant, thickness: 0.5),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: scheme.outline,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: scheme.outlineVariant, thickness: 0.5),
          ),
        ],
      ),
    );
  }
}

// Compact summary line for a run of consecutive empty days when scrolling
// back through history. Shows "9. bis 18. Mai · keine Einträge" instead of
// stacking individual day separators with empty rows.
class _EmptyDayRange extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback? onTap;
  const _EmptyDayRange({
    required this.start,
    required this.end,
    required this.scheme,
    required this.textTheme,
    this.onTap,
  });

  String _format(DateTime d, BuildContext context) {
    // Use the platform-localised short month name. intl ships with the
    // localisation data via flutter_localizations.
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final monthName = DateFormat.MMM(localeTag).format(d);
    return '${d.day}. $monthName';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dayCount = end.difference(start).inDays + 1;
    final fromLabel = _format(start, context);
    final toLabel = _format(end, context);
    final label = dayCount == 1 ? fromLabel : null;
    final inner = Row(
      children: [
        Expanded(
          child: Container(height: 1, color: scheme.outlineVariant),
        ),
        const SizedBox(width: 10),
        Text(
          dayCount == 1
              ? l10n.homeEmptyRangeSingle(label!)
              : l10n.homeEmptyRangeMulti(fromLabel, toLabel, dayCount),
          style: textTheme.labelSmall?.copyWith(
            color: scheme.outline,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1, color: scheme.outlineVariant),
        ),
      ],
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: inner,
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback onAdd;
  const _EmptyDay({
    required this.scheme,
    required this.textTheme,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context).homeEmptyDayText,
              style: textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(width: 8),
            Icon(Icons.add, size: 16, color: scheme.primary),
            const SizedBox(width: 2),
            Text(
              AppLocalizations.of(context).homeEmptyDayAdd,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Picker shown when the user taps a collapsed empty-day range. Lists
// each day in the range so the user can choose which one to log into,
// then the parent routes to the regular past-day input sheet.
class _EmptyRangePickerSheet extends StatelessWidget {
  final List<DateTime> days;
  const _EmptyRangePickerSheet({required this.days});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weekdayFmt = DateFormat('EEEE', locale);
    final dayFmt = DateFormat('d MMM', locale);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeEmptyRangePickerTitle,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.homeEmptyRangePickerHint,
                style: textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: days.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: scheme.outlineVariant, height: 1),
                  itemBuilder: (_, i) {
                    final day = days[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        weekdayFmt.format(day),
                        style: textTheme.bodyLarge,
                      ),
                      trailing: Text(
                        dayFmt.format(day),
                        style: textTheme.bodyMedium
                            ?.copyWith(color: scheme.outline),
                      ),
                      onTap: () => Navigator.pop(context, day),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PastDayInputSheet extends StatefulWidget {
  final TextEditingController controller;
  final DateTime day;
  const _PastDayInputSheet({required this.controller, required this.day});

  @override
  State<_PastDayInputSheet> createState() => _PastDayInputSheetState();
}

class _PastDayInputSheetState extends State<_PastDayInputSheet> {
  // Defaults to noon so the entry lands somewhere reasonable if the user
  // doesn't bother to set a time.
  TimeOfDay _time = const TimeOfDay(hour: 12, minute: 0);

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: AppLocalizations.of(context).homeTimePickerHelp,
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    Navigator.of(context).pop(
      (text: widget.controller.text, time: _time),
    );
  }

  String _formatTime(TimeOfDay t, String suffix) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}$suffix';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homePastDayHeader(formatDayHeader(context, widget.day)),
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                l10n.homePastDayBody,
                style: textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: widget.controller,
                autofocus: true,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: l10n.homePastDayInputHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_outlined,
                          size: 18, color: scheme.outline),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(_time, l10n.homeTimeSuffix),
                        style: textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurface),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit_outlined,
                          size: 14, color: scheme.outline),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(l10n.homeContinue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadMealCard extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _ThreadMealCard({
    required this.meal,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final time = TimeOfDay.fromDateTime(meal.createdAt);
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Slidable(
      key: ValueKey('home-${meal.id}'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.55,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            icon: Icons.edit_outlined,
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
          ),
          SlidableAction(
            onPressed: (_) => onDuplicate(),
            icon: Icons.copy_outlined,
            backgroundColor: scheme.tertiaryContainer,
            foregroundColor: scheme.onTertiaryContainer,
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            icon: Icons.delete_outline,
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.onErrorContainer,
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: scheme.surfaceContainerLow,
        child: ListTile(
          title: Text(meal.summary),
          subtitle: Text(timeLabel),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (meal.safetyWarnings.isNotEmpty) ...[
                _WarningIconButton(warnings: meal.safetyWarnings),
                const SizedBox(width: 4),
              ],
              Text(
                '${formatKcal(meal.kcal)} kcal',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningIconButton extends StatelessWidget {
  final List<String> warnings;
  const _WarningIconButton({required this.warnings});

  void _show(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, color: scheme.tertiary),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).homeMealHintsHeader,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...warnings.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: scheme.outline)),
                      Expanded(
                        child: Text(w,
                            style: textTheme.bodyMedium?.copyWith(height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.warning_amber, size: 20),
      color: Theme.of(context).colorScheme.tertiary,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'Hinweis ansehen',
      onPressed: () => _show(context),
    );
  }
}

class _CoachBubble extends StatelessWidget {
  final String text;
  final bool isAnswer;
  const _CoachBubble({required this.text, required this.isAnswer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Light mode keeps the warm amber-container chip look. Dark mode uses
    // a quieter neutral surface with an amber left rule, otherwise the
    // saturated dark-amber container reads as heavy/dominant against the
    // ink background.
    final bg = isDark ? scheme.surfaceContainerLow : scheme.secondaryContainer;
    final fg = isDark ? scheme.onSurface : scheme.onSecondaryContainer;
    final iconColor = scheme.secondary;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border(left: BorderSide(color: scheme.secondary, width: 3))
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
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
              data: text,
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
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

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

class _HomeInput extends ConsumerStatefulWidget {
  const _HomeInput();

  @override
  ConsumerState<_HomeInput> createState() => _HomeInputState();
}

class _HomeInputState extends ConsumerState<_HomeInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _sending = false;
  int _lastFocusRequest = 0;
  // Override timestamp for the next meal save. Null = use DateTime.now()
  // at send time. Used when the user logs e.g. breakfast in the evening.
  // Resets to null after each successful send.
  TimeOfDay? _customTime;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _focusAndOpenKeyboard() {
    // Schedule on the next frame so we don't fight any in-flight unfocus
    // (e.g. from a route transition). FocusNode.requestFocus on its own
    // brings the iOS keyboard up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickCustomTime() async {
    final initial = _customTime ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: AppLocalizations.of(context).homeTimePickerHelp,
    );
    if (picked != null && mounted) {
      setState(() => _customTime = picked);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
      // User intent after picking a food photo is almost always to log it.
      // Pull keyboard up so they can add a quick descriptor without an
      // extra tap on the input bar.
      _focusAndOpenKeyboard();
    } catch (_) {}
  }

  Future<void> _showPhotoPicker() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(AppLocalizations.of(context).homePhotoCamera),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppLocalizations.of(context).homePhotoGallery),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useFavorite(FavoriteMeal favorite) async {
    if (_sending) return;
    final parsed = MealParseResult(
      isMeal: true,
      rejectionReason: null,
      summary: favorite.summary,
      kcal: favorite.kcal,
      proteinG: favorite.proteinG,
      carbsG: favorite.carbsG,
      fatG: favorite.fatG,
      portionAmount: favorite.portionAmount,
      portionUnit: favorite.portionUnit,
      portionAlias: null,
      safetyWarnings: favorite.safetyWarnings,
    );
    await showModalBottomSheet<MealEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ConfirmScreen(
        rawText: '',
        parsed: parsed,
        asSheet: true,
      ),
    );
  }

  Future<void> _confirmDeleteFavorite(FavoriteMeal favorite) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.favoriteRemoveTitle(favorite.summary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.favoriteRemoveConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(favoriteRepositoryProvider).delete(favorite.id);
    }
  }

  List<ChatTurn> _buildHistory(
    List<ThreadItem> thread,
    Map<String, MealEntry> mealsById,
  ) {
    final turns = <ChatTurn>[];
    for (final item in thread) {
      switch (item.type) {
        case ThreadItemType.meal:
          final m = mealsById[item.mealId];
          if (m == null) continue;
          turns.add(ChatTurn(
            isUser: true,
            text:
                'Eintrag um ${_formatTime(m.createdAt)}: ${m.summary} (${m.kcal} kcal, Protein ${m.proteinG.toStringAsFixed(0)} g, KH ${m.carbsG.toStringAsFixed(0)} g, Fett ${m.fatG.toStringAsFixed(0)} g).',
          ));
        case ThreadItemType.coachResponse:
        case ThreadItemType.coachAnswer:
          if ((item.text ?? '').isEmpty) continue;
          turns.add(ChatTurn(isUser: false, text: item.text!));
        case ThreadItemType.userQuestion:
          if ((item.text ?? '').isEmpty) continue;
          turns.add(ChatTurn(isUser: true, text: item.text!));
      }
    }
    return turns;
  }

  String _buildContext({required String locale}) {
    final isDe = locale.toLowerCase().startsWith('de');
    final meals = ref.read(todayMealsProvider);
    final target = ref.read(calorieTargetProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;
    final total = meals.fold<int>(0, (s, m) => s + m.kcal);
    final protein = meals.fold<double>(0, (s, m) => s + m.proteinG);
    final carbs = meals.fold<double>(0, (s, m) => s + m.carbsG);
    final fat = meals.fold<double>(0, (s, m) => s + m.fatG);
    final remaining = target - total;
    final hour = DateTime.now().hour;
    final buffer = StringBuffer();
    if (profile != null) {
      if (isDe) {
        buffer
          ..writeln('=== Profil der Nutzerin ===')
          ..writeln(
              'Alter: ${profile.currentAge} Jahre · Größe: ${profile.heightCm.toStringAsFixed(0)} cm · Gewicht: ${profile.weightKg.toStringAsFixed(1)} kg')
          ..writeln('Aktivitätsfaktor: ${profile.activityFactor} (PAL)');
        if (profile.isPregnant) {
          buffer.writeln(
              'Phase: schwanger, ${profile.trimester ?? 1}. Trimester');
        }
        if (profile.numChildrenNursing > 0) {
          final volume = profile.dailyMilkVolumeMl > 0
              ? '${profile.dailyMilkVolumeMl} ml/Tag'
              : 'unbekannt';
          buffer.writeln(
              'Phase: Stillzeit, ${profile.numChildrenNursing} Kind(er), Milchvolumen ca. $volume, Anteil ${profile.milkSharePercent}%');
        }
      } else {
        buffer
          ..writeln('=== User profile ===')
          ..writeln(
              'Age: ${profile.currentAge} years · Height: ${profile.heightCm.toStringAsFixed(0)} cm · Weight: ${profile.weightKg.toStringAsFixed(1)} kg')
          ..writeln('Activity factor: ${profile.activityFactor} (PAL)');
        if (profile.isPregnant) {
          buffer.writeln(
              'Phase: pregnant, trimester ${profile.trimester ?? 1}');
        }
        if (profile.numChildrenNursing > 0) {
          final volume = profile.dailyMilkVolumeMl > 0
              ? '${profile.dailyMilkVolumeMl} ml/day'
              : 'unknown';
          buffer.writeln(
              'Phase: producing milk, ${profile.numChildrenNursing} child(ren), milk volume ~$volume, share ${profile.milkSharePercent}%');
        }
      }
      buffer.writeln(ClaudeClient.describeProfile(
        profile.numChildrenNursing,
        profile.milkSharePercent,
        locale: locale,
      ));
    }
    if (isDe) {
      buffer
        ..writeln('=== Tageskontext ===')
        ..writeln('Aktuelle Uhrzeit: $hour Uhr.')
        ..writeln(
            'Tagesziel: $target kcal. Bisher heute: $total kcal. Verbleibend: $remaining kcal.')
        ..writeln(
            'Makros heute: Protein ${protein.toStringAsFixed(0)} g · KH ${carbs.toStringAsFixed(0)} g · Fett ${fat.toStringAsFixed(0)} g.')
        ..writeln('Anzahl Einträge heute: ${meals.length}.');
    } else {
      buffer
        ..writeln('=== Daily context ===')
        ..writeln('Current time: $hour:00.')
        ..writeln(
            'Daily target: $target kcal. So far today: $total kcal. Remaining: $remaining kcal.')
        ..writeln(
            'Macros today: protein ${protein.toStringAsFixed(0)} g · carbs ${carbs.toStringAsFixed(0)} g · fat ${fat.toStringAsFixed(0)} g.')
        ..writeln('Entries logged today: ${meals.length}.');
    }
    return buffer.toString();
  }

  Future<void> _askAsQuestion(String text) async {
    final threadRepo = ref.read(threadRepositoryProvider);
    final client = ref.read(claudeClientProvider);
    final loadingNotifier = ref.read(insightLoadingProvider.notifier);
    final meals = ref.read(todayMealsProvider);
    final mealsById = {for (final m in meals) m.id: m};
    final priorThread = ref.read(todayThreadProvider).valueOrNull ?? [];

    final locale = Localizations.localeOf(context).languageCode;
    final history = _buildHistory(priorThread, mealsById)
      ..add(ChatTurn(isUser: true, text: text));
    final todayContext = _buildContext(locale: locale);

    await threadRepo
        .add(ThreadItem.userQuestion(text: text, at: DateTime.now()));
    loadingNotifier.state = true;

    try {
      final reply = await client.chat(
        history: history,
        todayContext: todayContext,
        locale: locale,
      );
      await threadRepo.add(ThreadItem.coachAnswer(
        text: reply.trim(),
        at: DateTime.now(),
      ));
    } on CoachApiException catch (e) {
      await threadRepo.add(ThreadItem.coachAnswer(
        text: e.userMessage,
        at: DateTime.now(),
      ));
    } catch (e) {
      await threadRepo.add(ThreadItem.coachAnswer(
        text: mounted
            ? AppLocalizations.of(context).commonGenericError
            : 'Something went wrong. Try again.',
        at: DateTime.now(),
      ));
    } finally {
      loadingNotifier.state = false;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final hasImage = _imageBytes != null;
    if (text.isEmpty && !hasImage) return;
    if (_sending) return;

    setState(() => _sending = true);
    FocusScope.of(context).unfocus();

    try {
      final client = ref.read(claudeClientProvider);

      final parsed = await client.parseMeal(
        text,
        imageBytes: _imageBytes,
        locale: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      if (parsed.isMeal) {
        // If the user picked a custom time, override createdAt to today at
        // that time. Otherwise let ConfirmScreen default to DateTime.now().
        final now = DateTime.now();
        final createdAt = _customTime == null
            ? null
            : DateTime(now.year, now.month, now.day,
                _customTime!.hour, _customTime!.minute);
        await showModalBottomSheet<MealEntry>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (_) => ConfirmScreen(
            rawText: text,
            parsed: parsed,
            imageBytes: _imageBytes,
            existingCreatedAt: createdAt,
            asSheet: true,
          ),
        );
        // Aggressively close the keyboard if anything in the sheet (or the
        // route transition) left a focused TextField. Without this, iOS keeps
        // the keyboard shown and the new entry view is half the screen.
        FocusManager.instance.primaryFocus?.unfocus();
      } else if (text.isEmpty && hasImage) {
        // Image-only input that didn't parse as a meal, almost always a
        // non-food photo. Surface as a snackbar so it's clearly a system
        // hint, not a coach response.
        _showSnack(
          parsed.rejectionReason ??
              AppLocalizations.of(context).homePhotoNotFoodError,
        );
      } else {
        // Text input that didn't parse as a meal, treat as a coach question.
        await _askAsQuestion(text);
      }
      _controller.clear();
      if (mounted) {
        setState(() {
          _imageBytes = null;
          _customTime = null;
        });
      }
    } on CoachApiException catch (e) {
      // Backend complained for a specific reason: surface as system snackbar,
      // not as a coach bubble (those should feel like dialogue, not errors).
      _showSnack(e.userMessage);
    } catch (_) {
      if (mounted) _showSnack(AppLocalizations.of(context).commonSendError);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final favorites =
        ref.watch(favoritesProvider).valueOrNull ?? const <FavoriteMeal>[];

    // Listen for focus requests from the rest of the app (notification tap,
    // onboarding finish, photo-picker from elsewhere). The counter pattern
    // lets repeat requests still trigger focus when the value didn't flip.
    final focusReq = ref.watch(mealInputFocusRequestProvider);
    if (focusReq != _lastFocusRequest) {
      _lastFocusRequest = focusReq;
      if (focusReq > 0) _focusAndOpenKeyboard();
    }

    return Material(
      color: scheme.surfaceContainer,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (favorites.isNotEmpty) ...[
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: favorites.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final f = favorites[i];
                        final menge = f.portionAmount > 0
                            ? ', ${f.portionAmount.toStringAsFixed(0)} ${f.portionUnit}'
                            : '';
                        // No outer GestureDetector: it was blocking the chip's
                        // own tap recognizer. Edit moved to Settings →
                        // "Favoriten verwalten".
                        return InputChip(
                          avatar: Icon(Icons.star_rounded,
                              size: 14, color: scheme.secondary),
                          label: Text(
                            '${f.summary}$menge',
                            style: textTheme.labelSmall,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onPressed:
                              _sending ? null : () => _useFavorite(f),
                          onDeleted: () => _confirmDeleteFavorite(f),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          deleteButtonTooltipMessage:
                              'Aus Favoriten entfernen',
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (_imageBytes != null) ...[
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _imageBytes!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _sending
                                ? null
                                : () => setState(() => _imageBytes = null),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.close,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _sending ? null : _showPhotoPicker,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      tooltip: AppLocalizations.of(context).homePhotoButton,
                      iconSize: 22,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      visualDensity: VisualDensity.compact,
                      color: scheme.onSurfaceVariant,
                    ),
                    // Time-override chip. Default state = clock icon, meal
                    // saves with DateTime.now(). When the user taps and picks
                    // a time, the chip turns primary-tinted with HH:MM and
                    // the next meal save uses today at that time. Resets
                    // after each send.
                    Material(
                      color: _customTime != null
                          ? scheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _sending ? null : _pickCustomTime,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: _customTime != null ? 10 : 6,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 20,
                                color: _customTime != null
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurfaceVariant,
                              ),
                              if (_customTime != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  _formatTimeOfDay(_customTime!),
                                  style: textTheme.labelMedium?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).homeMainInputHint,
                          hintStyle: TextStyle(color: scheme.outline),
                          isDense: true,
                          filled: true,
                          fillColor: scheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: scheme.outlineVariant,
                              width: 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: scheme.outlineVariant,
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: scheme.primary,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: IconButton.filled(
                        onPressed: _sending ? null : _send,
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
