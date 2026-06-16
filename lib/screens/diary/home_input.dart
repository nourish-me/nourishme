import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models/favorite_meal.dart';
import '../../models/meal_entry.dart';
import '../../models/meal_entry_source.dart';
import '../../models/thread_item.dart';
import '../../providers/meal_providers.dart';
import '../../providers/ui_providers.dart';
import '../../services/claude_client.dart';
import '../../services/coach_session_manager.dart';
import '../../utils/photo_exif.dart';
import '../../utils/weight_trend.dart';
import '../barcode_scanner_screen.dart';
import '../confirm_screen.dart';
import 'history_suggestion_chip.dart';
import 'multi_photo_review_screen.dart';

// Photo-picker bottom-sheet choices (#105). Internal enum kept here
// because the multi-gallery option only exists in this composer surface.
enum _PhotoChoice { camera, gallery, multiGallery }

// The bottom-of-screen composer for the diary: text field + photo +
// barcode + send, with the favourites strip and history-suggestion
// chips stacked above. Also owns the multi-step scan session that
// chains barcode → photo → text steps into one coach reply.
class HomeInput extends ConsumerStatefulWidget {
  const HomeInput({super.key});

  @override
  ConsumerState<HomeInput> createState() => _HomeInputState();
}

class _HomeInputState extends ConsumerState<HomeInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  // EXIF DateTimeOriginal of [_imageBytes] when the picked file carries it
  // (#98). Used as the soft default for the meal's time in the confirm
  // sheet so retro-photo uploads land on when the photo was actually
  // taken instead of when the user got around to tapping send.
  DateTime? _imageExifTimestamp;
  bool _sending = false;
  int _lastFocusRequest = 0;
  int _lastPrefillVersion = 0;
  // Mirror of _controller.text used to drive the history-suggestion chip row.
  // Stored separately so build() can watch it without subscribing to every
  // TextField rebuild path.
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_query == _controller.text) return;
    setState(() => _query = _controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _focusAndOpenKeyboard() async {
    // Schedule on the next frame so we don't fight any in-flight unfocus
    // (e.g. from a route transition). FocusNode.requestFocus on its own
    // brings the iOS keyboard up - when it actually lands. Cold-launch
    // from a meal-reminder push can arrive before the TextField has even
    // attached its FocusNode, so we retry a few times until focus sticks
    // or we give up. The debugPrint trail makes diagnosis from the
    // device console straightforward when it doesn't work.
    for (var attempt = 0; attempt < 5; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      _focusNode.requestFocus();
      if (_focusNode.hasFocus) {
        debugPrint('[Focus] keyboard requested on attempt $attempt');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }
    debugPrint('[Focus] gave up after 5 attempts, focus did not stick');
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
      final exif = await readPhotoExifTimestamp(bytes);
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageExifTimestamp = exif;
      });
      // User intent after picking a food photo is almost always to log it.
      // Pull keyboard up so they can add a quick descriptor without an
      // extra tap on the input bar.
      _focusAndOpenKeyboard();
    } catch (_) {}
  }

  Future<void> _showPhotoPicker() async {
    if (!mounted) return;
    final choice = await showModalBottomSheet<_PhotoChoice>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(AppLocalizations.of(context).homePhotoCamera),
              onTap: () => Navigator.pop(sheetContext, _PhotoChoice.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppLocalizations.of(context).homePhotoGallery),
              onTap: () => Navigator.pop(sheetContext, _PhotoChoice.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.collections_outlined),
              title: Text(AppLocalizations.of(context).homePhotoMultiGallery),
              onTap: () =>
                  Navigator.pop(sheetContext, _PhotoChoice.multiGallery),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case _PhotoChoice.camera:
        await _pickImage(ImageSource.camera);
        break;
      case _PhotoChoice.gallery:
        await _pickImage(ImageSource.gallery);
        break;
      case _PhotoChoice.multiGallery:
        await _doMultiPhotoFlow();
        break;
    }
  }

  // Re-uses a meal from the user's history exactly as it was logged before
  // (same brand, same portion, same macros), skipping the parseMeal call.
  // For products the user repeatedly logs this is more accurate than a
  // generic estimate AND cheaper (one Anthropic call saved per tap).
  Future<void> _useHistoryMatch(MealEntry m) async {
    if (_sending) return;
    ref
        .read(analyticsServiceProvider)
        .capture('history_chip_tapped', properties: {
      'summary_length': m.summary.length,
    });
    final parsed = MealParseResult(
      isMeal: true,
      rejectionReason: null,
      summary: m.summary,
      kcal: m.kcal,
      proteinG: m.proteinG,
      carbsG: m.carbsG,
      fatG: m.fatG,
      portionAmount: m.portionAmount,
      portionUnit: m.portionUnit,
      portionAlias: m.portionAlias,
      safetyWarnings: m.safetyWarnings,
      // Carry micronutrients from the historical entry so re-logging the
      // same meal preserves the original estimate without a fresh parse.
      micronutrients: m.micronutrients,
    );
    await showModalBottomSheet<MealEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ConfirmScreen(
        rawText: m.summary,
        parsed: parsed,
        asSheet: true,
        source: MealEntrySource.history,
      ),
    );
    // Clear the input so it doesn't sit there suggesting the same meal again.
    if (mounted) _controller.clear();
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
      micronutrients: favorite.micronutrients,
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
        source: MealEntrySource.favorite,
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
      // Meal-pattern preference (#108) so the chat coach respects the
      // user's chosen rhythm when she asks open-ended meal-planning
      // questions ("what should I have for lunch?"). Same wire value as
      // the per_meal path uses.
      buffer.writeln(isDe
          ? 'Mahlzeit-Stil-Präferenz: ${profile.mealPattern}'
          : 'Meal-pattern preference: ${profile.mealPattern}');
      // Diet preferences threaded into the chat context too so free-form
      // coach questions ("what should I eat tonight") respect avoid-list.
      final hasDietInfo = profile.dietStyle != 'omnivore' ||
          profile.restrictions.isNotEmpty ||
          profile.dietaryNotes.trim().isNotEmpty;
      if (hasDietInfo) {
        if (isDe) {
          if (profile.dietStyle != 'omnivore') {
            buffer.writeln('Ernährung: ${profile.dietStyle}');
          }
          if (profile.restrictions.isNotEmpty) {
            buffer.writeln('Vermeidet: ${profile.restrictions.join(", ")}');
          }
          if (profile.dietaryNotes.trim().isNotEmpty) {
            buffer.writeln('Hinweis: ${profile.dietaryNotes.trim()}');
          }
        } else {
          if (profile.dietStyle != 'omnivore') {
            buffer.writeln('Diet: ${profile.dietStyle}');
          }
          if (profile.restrictions.isNotEmpty) {
            buffer.writeln('Avoids: ${profile.restrictions.join(", ")}');
          }
          if (profile.dietaryNotes.trim().isNotEmpty) {
            buffer.writeln('Note: ${profile.dietaryNotes.trim()}');
          }
        }
      }
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
    final trend = ref.read(weightTrendProvider);
    if (trend != null) {
      buffer.writeln(formatWeightTrendForCoach(trend, isDe: isDe));
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
    // User just sent a chat question. Bump the scroll request so the diary
    // jumps to the question even if they were reading yesterday's entries -
    // the ambient "only follow if near bottom" rule would otherwise drop
    // both their question and the eventual reply silently below the fold.
    ref.read(scrollToBottomRequestProvider.notifier).state++;
    ref.read(analyticsServiceProvider).capture('coach_chat_sent');
    loadingNotifier.state = true;
    var replyOk = true;

    try {
      final reply = await client.chat(
        history: history,
        todayContext: todayContext,
        locale: locale,
      );
      await threadRepo.add(ThreadItem.coachAnswer(
        text: reply.text.trim(),
        at: DateTime.now(),
        responseType: reply.type,
      ));
    } on CoachApiException catch (e) {
      replyOk = false;
      await threadRepo.add(ThreadItem.coachAnswer(
        text: e.userMessage,
        at: DateTime.now(),
      ));
    } catch (e) {
      replyOk = false;
      await threadRepo.add(ThreadItem.coachAnswer(
        text: mounted
            ? AppLocalizations.of(context).commonGenericError
            : 'Something went wrong. Try again.',
        at: DateTime.now(),
      ));
    } finally {
      // Track chat coach success/failure rate alongside the per-meal one.
      ref.read(analyticsServiceProvider).capture('coach_reply',
          properties: {'kind': 'chat', 'ok': replyOk});
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

  // Thin wrapper so the scanner-icon tap reads naturally. The real loop
  // lives in _runScanSession and can also handle photo / text follow-ups.
  Future<void> _scanBarcode() => _runScanSession(firstType: 'barcode');

  // Multi-step scan-session loop. Each iteration runs one step (barcode /
  // photo / text), shows ConfirmScreen with allowScanAnother:true, and
  // looks at the popped value: 'barcode' / 'photo' / 'text' continues
  // with that next step; anything else (saved meal, null on dismiss)
  // ends the session and the pending bundle gets flushed.
  Future<void> _runScanSession({required String firstType}) async {
    if (_sending) return;
    FocusScope.of(context).unfocus();
    try {
      String? next = firstType;
      while (next != null) {
        if (!mounted) break;
        switch (next) {
          case 'barcode':
            next = await _doBarcodeStep();
            break;
          case 'photo':
            next = await _doPhotoStep();
            break;
          case 'text':
            next = await _doTextStep();
            break;
          default:
            next = null;
        }
        if (mounted) FocusManager.instance.primaryFocus?.unfocus();
      }
    } catch (e, st) {
      debugPrint('Scan session failed: $e\n$st');
      if (mounted) _showSnack(AppLocalizations.of(context).commonSendError);
    } finally {
      if (mounted) setState(() => _sending = false);
      // Belt-and-suspenders: if the user exited via dismiss (swipe down)
      // mid-session, any items already saved into the pending bundle still
      // deserve a coach reply. Flush them.
      if (mounted) {
        final pending = ref.read(pendingScanBundleProvider);
        if (pending.isNotEmpty) {
          ref.read(pendingScanBundleProvider.notifier).state = const [];
          final locale = Localizations.localeOf(context).languageCode;
          final fired = ref
              .read(coachSessionProvider.notifier)
              .submitMealsIfLive(pending, locale);
          if (!fired && mounted) {
            _showSnack(AppLocalizations.of(context)
                .confirmCoachRetroPausedToast);
          }
        }
      }
    }
  }

  Future<String?> _doBarcodeStep() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode == null || !mounted) return null;
    setState(() => _sending = true);
    final product =
        await ref.read(openFoodFactsClientProvider).lookupByBarcode(barcode);
    if (!mounted) return null;
    ref.read(analyticsServiceProvider).capture('barcode_scanned',
        properties: {'found': product != null});
    if (product == null) {
      _showSnack(AppLocalizations.of(context).scanNotFound);
      setState(() => _sending = false);
      return null;
    }
    final profile = ref.read(userProfileProvider).valueOrNull;
    final warnings = await ref.read(claudeClientProvider).safetyCheck(
          productName: product.displaySummary,
          isPregnant: profile?.isPregnant ?? false,
          trimester: profile?.trimester,
          isLactating: (profile?.numChildrenNursing ?? 0) > 0,
          locale: Localizations.localeOf(context).languageCode,
        );
    if (!mounted) return null;
    final amount = product.defaultAmount;
    final f = amount / 100.0;
    final parsed = MealParseResult(
      isMeal: true,
      rejectionReason: null,
      summary: product.displaySummary,
      kcal: (product.kcalPer100 * f).round(),
      proteinG: product.proteinPer100 * f,
      carbsG: product.carbsPer100 * f,
      fatG: product.fatPer100 * f,
      portionAmount: amount,
      portionUnit: product.unit,
      portionAlias: null,
      safetyWarnings: warnings,
    );
    if (mounted) setState(() => _sending = false);
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ConfirmScreen(
        rawText: product.displaySummary,
        parsed: parsed,
        asSheet: true,
        source: MealEntrySource.barcode,
        allowScanAnother: true,
      ),
    );
    return result is String ? result : null;
  }

  // Multi-photo bulk-save flow (#105). Picks N photos, parses each in
  // parallel, shows the MultiPhotoReviewScreen for triage, then on
  // "Save All" persists every kept item to the meal repo + flushes them
  // as a single coach-session bundle so the user gets ONE wrap-up reply
  // instead of N. Per-item edit is deferred to a follow-up task; users
  // can fine-tune saved meals from the diary right after the bulk save.
  Future<void> _doMultiPhotoFlow() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final List<XFile> picked;
    try {
      picked = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1280,
      );
    } catch (e) {
      debugPrint('pickMultiImage failed: $e');
      return;
    }
    if (picked.isEmpty || !mounted) return;
    setState(() => _sending = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      final timeHints = ref.read(mealHistoryByTimeOfDayProvider);
      final client = ref.read(claudeClientProvider);
      // Parse all in parallel; each photo can fail independently and is
      // surfaced as a 'skipped' row rather than aborting the whole bulk.
      final parses = await Future.wait(
        picked.map((file) async {
          try {
            final bytes = await file.readAsBytes();
            final exif = await readPhotoExifTimestamp(bytes);
            final parsed = await client.parseMeal(
              '',
              imageBytes: bytes,
              locale: locale,
              isPregnant: profile?.isPregnant ?? false,
              trimester: profile?.trimester,
              isLactating: (profile?.numChildrenNursing ?? 0) > 0,
              timeOfDayHints: timeHints,
            );
            return MultiPhotoItem(
              bytes: bytes,
              parsed: parsed,
              mealTime: exif ?? DateTime.now(),
              skippedReason: !parsed.isMeal
                  ? (parsed.rejectionReason ?? l10n.multiPhotoNoFoodSkipped)
                  : null,
            );
          } catch (e) {
            debugPrint('Multi-photo parse failed: $e');
            return MultiPhotoItem(
              bytes: await file.readAsBytes(),
              parsed: const MealParseResult.nonMeal(),
              mealTime: DateTime.now(),
              skippedReason: l10n.multiPhotoParsingError,
            );
          }
        }),
      );
      if (!mounted) return;
      setState(() => _sending = false);
      final keepers = await Navigator.of(context).push<List<MultiPhotoItem>>(
        MaterialPageRoute(
          builder: (_) => MultiPhotoReviewScreen(items: parses),
          fullscreenDialog: true,
        ),
      );
      if (!mounted || keepers == null || keepers.isEmpty) return;
      // Persist each kept item to the meal repo with the EXIF/edited
      // mealTime, then hand the whole batch to the coach session as one
      // bundle so the user gets a single coach reply that summarises
      // ALL of today's catch-up entries (not N individual replies).
      final mealRepo = ref.read(mealRepositoryProvider);
      final threadRepo = ref.read(threadRepositoryProvider);
      final savedMeals = <MealEntry>[];
      for (final item in keepers) {
        final id = 'meal-${DateTime.now().microsecondsSinceEpoch}-${savedMeals.length}';
        final meal = MealEntry(
          id: id,
          createdAt: item.mealTime,
          rawText: item.rawText,
          summary: item.parsed.summary,
          kcal: item.parsed.kcal,
          proteinG: item.parsed.proteinG,
          carbsG: item.parsed.carbsG,
          fatG: item.parsed.fatG,
          portionAmount: item.parsed.portionAmount,
          portionUnit: item.parsed.portionUnit,
          portionAlias: item.parsed.portionAlias,
          safetyWarnings: item.parsed.safetyWarnings,
          micronutrients: item.parsed.micronutrients,
        );
        await mealRepo.save(meal);
        await threadRepo
            .add(ThreadItem.meal(mealId: meal.id, at: meal.createdAt));
        savedMeals.add(meal);
      }
      if (!mounted) return;
      final fired = ref
          .read(coachSessionProvider.notifier)
          .submitMealsIfLive(savedMeals, locale);
      ref.read(analyticsServiceProvider).capture('multi_photo_saved',
          properties: {'count': savedMeals.length});
      // Day-switch logic for cross-day bulks. If every saved meal lives
      // on the same day, jump the diary to that day so the user lands on
      // the entries they just saved (otherwise a user uploading three
      // yesterday photos stays on today and sees nothing change). If the
      // bulk spans multiple days (e.g. some yesterday, some today), stay
      // on the focused day and surface a hint so the user knows where to
      // navigate. Also scroll to the LAST saved entry so the user sees
      // something new appear.
      final savedDays = savedMeals
          .map((m) => DateTime(m.createdAt.year, m.createdAt.month,
              m.createdAt.day))
          .toSet();
      final crossDay = savedDays.length > 1;
      if (!crossDay) {
        ref.read(scrollToDayProvider.notifier).state = savedDays.first;
      }
      ref.read(scrollToMealIdProvider.notifier).state = savedMeals.last.id;
      if (!fired) {
        // Multi-photo bulk-save with EXIF timestamps almost always lands
        // in the retro window (user is logging earlier-today or yesterday
        // photos). Show the coach-paused hint instead of the generic
        // "all saved" snack so the user understands why no thinking
        // bubble appears.
        _showSnack(crossDay
            ? l10n.multiPhotoCrossDaySnack(savedMeals.length, savedDays.length)
            : l10n.confirmCoachRetroPausedToast);
      } else {
        _showSnack(l10n.multiPhotoAllSavedSnackWithHint(savedMeals.length));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<String?> _doPhotoStep() async {
    final source = await showModalBottomSheet<_PhotoChoice>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(AppLocalizations.of(context).homePhotoCamera),
              onTap: () => Navigator.pop(sheetCtx, _PhotoChoice.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppLocalizations.of(context).homePhotoGallery),
              onTap: () => Navigator.pop(sheetCtx, _PhotoChoice.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.collections_outlined),
              title: Text(AppLocalizations.of(context).homePhotoMultiGallery),
              onTap: () =>
                  Navigator.pop(sheetCtx, _PhotoChoice.multiGallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return null;
    if (source == _PhotoChoice.multiGallery) {
      await _doMultiPhotoFlow();
      // Multi-photo handles its own bundle save + coach trigger, so end
      // the scan-session loop here regardless of result.
      return null;
    }
    final imageSource = source == _PhotoChoice.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    final picked = await ImagePicker().pickImage(
      source: imageSource,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (picked == null || !mounted) return null;
    // Capture context-derived values BEFORE any async work to avoid the
    // "BuildContext across async gaps" lint - the EXIF read below is a
    // new await that the analyzer treats as a potential dismount point.
    final locale = Localizations.localeOf(context).languageCode;
    final bytes = await picked.readAsBytes();
    if (!mounted) return null;
    // Photo EXIF DateTimeOriginal (#98) so retro-photo uploads default to
    // the time the photo was actually taken, not the time of the tap.
    // null when the file has no EXIF block or the timestamp is out of
    // sensible range; ConfirmScreen falls through to wall-clock now in
    // that case.
    final exifTimestamp = await readPhotoExifTimestamp(bytes);
    if (!mounted) return null;
    setState(() => _sending = true);
    final profile = ref.read(userProfileProvider).valueOrNull;
    // Photo-only path has no typed query for substring-matching, so feed
    // the time-of-day history as a vocabulary anchor (Heidelbeeren vs.
    // Pflaumen ambiguity at breakfast time).
    final timeHints = ref.read(mealHistoryByTimeOfDayProvider);
    final parsed = await ref.read(claudeClientProvider).parseMeal(
          '',
          imageBytes: bytes,
          locale: locale,
          isPregnant: profile?.isPregnant ?? false,
          trimester: profile?.trimester,
          isLactating: (profile?.numChildrenNursing ?? 0) > 0,
          timeOfDayHints: timeHints,
        );
    if (mounted) setState(() => _sending = false);
    if (!mounted || !parsed.isMeal) {
      if (mounted) {
        _showSnack(parsed.rejectionReason ??
            AppLocalizations.of(context).homePhotoNotFoodError);
      }
      return null;
    }
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ConfirmScreen(
        rawText: '',
        parsed: parsed,
        imageBytes: bytes,
        suggestedCreatedAt: exifTimestamp,
        asSheet: true,
        source: MealEntrySource.photo,
        allowScanAnother: true,
      ),
    );
    return result is String ? result : null;
  }

  Future<String?> _doTextStep() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final entered = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.confirmAddTextSheetTitle,
              style: Theme.of(sheetCtx)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 1,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) => Navigator.pop(sheetCtx, v.trim()),
              decoration: InputDecoration(
                hintText: l10n.confirmAddTextSheetHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(sheetCtx, controller.text.trim()),
              child: Text(l10n.confirmAddTextSheetCta),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (entered == null || entered.isEmpty || !mounted) return null;
    setState(() => _sending = true);
    final profile = ref.read(userProfileProvider).valueOrNull;
    final parsed = await ref.read(claudeClientProvider).parseMeal(
          entered,
          locale: Localizations.localeOf(context).languageCode,
          isPregnant: profile?.isPregnant ?? false,
          trimester: profile?.trimester,
          isLactating: (profile?.numChildrenNursing ?? 0) > 0,
        );
    if (mounted) setState(() => _sending = false);
    if (!mounted || !parsed.isMeal) {
      if (mounted) {
        _showSnack(parsed.rejectionReason ?? l10n.commonGenericError);
      }
      return null;
    }
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ConfirmScreen(
        rawText: entered,
        parsed: parsed,
        asSheet: true,
        source: MealEntrySource.text,
        allowScanAnother: true,
      ),
    );
    return result is String ? result : null;
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
      final profile = ref.read(userProfileProvider).valueOrNull;
      // Pull the user's last matching entries (top 3, last 30 days) so
      // the parser anchors on her actual brand+portion values instead
      // of re-estimating a generic Skyr / cereal / takeaway. Only fires
      // for text input.
      final historyHints = text.trim().length >= 2
          ? ref.read(mealHistorySuggestionsProvider(text))
          : const <MealEntry>[];
      // On the photo path (with or without text), also feed the
      // time-of-day history as a vocabulary anchor for the vision model.
      // Cheap: the prompt block is only built when the list is non-empty.
      final timeHints = _imageBytes != null
          ? ref.read(mealHistoryByTimeOfDayProvider)
          : const <MealEntry>[];

      final parsed = await client.parseMeal(
        text,
        imageBytes: _imageBytes,
        locale: Localizations.localeOf(context).languageCode,
        isPregnant: profile?.isPregnant ?? false,
        trimester: profile?.trimester,
        isLactating: (profile?.numChildrenNursing ?? 0) > 0,
        brandHistoryHints: historyHints,
        timeOfDayHints: timeHints,
      );
      if (!mounted) return;
      if (parsed.isMeal) {
        // Time defaults to now; the user can adjust it in the confirm sheet.
        await showModalBottomSheet<MealEntry>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (_) => ConfirmScreen(
            rawText: text,
            parsed: parsed,
            imageBytes: _imageBytes,
            suggestedCreatedAt: _imageExifTimestamp,
            asSheet: true,
            source: _imageBytes != null
                ? MealEntrySource.photo
                : MealEntrySource.text,
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
        // Text input that didn't parse as a meal → coach question. But the
        // coach reads/writes against TODAY's thread; if the user is sitting
        // on a past day the question + reply would silently land in today's
        // bucket and the user would see "nothing happened" on their current
        // view. Block the chat path on past days and surface a hint so they
        // know to switch to Today.
        final focused = ref.read(focusedDayProvider);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final isPast = focused.isBefore(today);
        if (isPast) {
          _showSnack(AppLocalizations.of(context).homeCoachOnlyTodayHint);
        } else {
          await _askAsQuestion(text);
        }
      }
      _controller.clear();
      if (mounted) {
        setState(() {
          _imageBytes = null;
          _imageExifTimestamp = null;
        });
      }
    } on CoachApiException catch (e) {
      // Backend complained for a specific reason: surface as system snackbar,
      // not as a coach bubble (those should feel like dialogue, not errors).
      _showSnack(e.userMessage);
    } catch (e, st) {
      // Anything that isn't a CoachApiException reaches here. Log the real
      // error + stack so an otherwise-invisible failure is diagnosable in
      // the device console instead of just showing a generic snackbar.
      debugPrint('Send failed: $e\n$st');
      if (mounted) _showSnack(AppLocalizations.of(context).commonSendError);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final allFavorites =
        ref.watch(favoritesProvider).valueOrNull ?? const <FavoriteMeal>[];
    // Recent-meal matches for the current typed query (empty list until the
    // user has typed >= 2 chars). Hidden when a photo is attached because the
    // photo flow follows a different mental model - the user is already
    // committed to that meal, not searching for one.
    final historySuggestions = _imageBytes != null
        ? const <MealEntry>[]
        : ref.watch(mealHistorySuggestionsProvider(_query));
    // Hybrid favorites visibility per beta feedback:
    // - Typing (>= 2 chars): filter favorites by substring so they act as
    //   one-tap shortcuts inside the autocomplete flow, same mental model
    //   as history matches.
    // - Empty input + diary has entries: hide favorites entirely so the
    //   chip row doesn't dominate the input area on a busy day.
    // - Empty input + diary still empty: show favorites so a returning
    //   user has a one-tap log path and a new user discovers the feature.
    final focusedDayMeals = ref.watch(focusedDayMealsProvider);
    final query = _query.trim().toLowerCase();
    List<FavoriteMeal> favorites;
    if (_imageBytes != null) {
      favorites = const [];
    } else if (query.length >= 2) {
      final tokens =
          query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      favorites = allFavorites.where((f) {
        final summary = f.summary.toLowerCase();
        return tokens.every(summary.contains);
      }).take(3).toList();
    } else if (_query.isEmpty && focusedDayMeals.isEmpty) {
      favorites = allFavorites;
    } else {
      favorites = const [];
    }

    // Listen for focus requests from the rest of the app (notification tap,
    // onboarding finish, photo-picker from elsewhere). The counter pattern
    // lets repeat requests still trigger focus when the value didn't flip.
    final focusReq = ref.watch(mealInputFocusRequestProvider);
    if (focusReq != _lastFocusRequest) {
      _lastFocusRequest = focusReq;
      if (focusReq > 0) _focusAndOpenKeyboard();
    }

    // Tap on a coach follow-up chip writes a payload here. Pull it into the
    // text field, place the cursor at the end, then clear the provider so a
    // repeat tap with the same label still fires (version counter handles
    // the case where the user wipes the field and taps the same chip again).
    final prefill = ref.watch(mealInputPrefillProvider);
    if (prefill != null && prefill.version != _lastPrefillVersion) {
      _lastPrefillVersion = prefill.version;
      _controller.text = prefill.text;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(mealInputPrefillProvider.notifier).state = null;
        }
      });
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
                                : () => setState(() {
                                      _imageBytes = null;
                                      _imageExifTimestamp = null;
                                    }),
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
                // History suggestions: pulls up to 3 recent matching meals
                // as one-tap chips while the user is typing. Surfaces the
                // exact brand + portion they logged before instead of a
                // generic estimate, and skips a parseMeal API call.
                if (historySuggestions.isNotEmpty) ...[
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: historySuggestions.length,
                      separatorBuilder: (_, i) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final m = historySuggestions[i];
                        return HistorySuggestionChip(
                          meal: m,
                          onTap: () => _useHistoryMatch(m),
                        );
                      },
                    ),
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
                    IconButton(
                      onPressed: _sending ? null : _scanBarcode,
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: AppLocalizations.of(context).scanButton,
                      iconSize: 22,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      visualDensity: VisualDensity.compact,
                      color: scheme.onSurfaceVariant,
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
                          // With a photo attached the prompt shifts: the
                          // photo carries the "what did I eat" signal, so
                          // the textfield's job becomes amount + notes,
                          // not the meal name. Surfacing that in the hint
                          // pushes users towards the more accurate
                          // photo+text combo without an explicit tip.
                          hintText: _imageBytes != null
                              ? AppLocalizations.of(context).homePhotoTextHint
                              : AppLocalizations.of(context)
                                  .homeMainInputHint,
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
