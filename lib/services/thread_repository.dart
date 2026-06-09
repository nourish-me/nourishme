import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/thread_item.dart';

class ThreadRepository {
  static const _boxName = 'threads';
  final Box<String> _box;

  ThreadRepository(this._box);

  static Future<ThreadRepository> open() async {
    final box = await Hive.openBox<String>(_boxName);
    return ThreadRepository(box);
  }

  String _keyFor(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<ThreadItem> getForDate(DateTime d) {
    final raw = _box.get(_keyFor(d));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    final items = list
        .map((j) => ThreadItem.fromJson(j as Map<String, dynamic>))
        .toList();

    // Build a quick lookup of meal-item timestamps by id so we can anchor
    // their coach response next to them, even if the response arrived
    // after the user interleaved a question on a different topic. The
    // meal's timestamp + 1µs is used as the sort key so the response
    // always lands immediately after its meal.
    final mealTs = <String, DateTime>{
      for (final i in items)
        if (i.type == ThreadItemType.meal && i.mealId != null)
          i.mealId!: i.timestamp,
    };
    DateTime sortKey(ThreadItem i) {
      if (i.type == ThreadItemType.coachResponse && i.mealId != null) {
        final anchor = mealTs[i.mealId!];
        if (anchor != null) {
          return anchor.add(const Duration(microseconds: 1));
        }
      }
      return i.timestamp;
    }

    items.sort((a, b) => sortKey(a).compareTo(sortKey(b)));
    return items;
  }

  List<ThreadItem> getToday() => getForDate(DateTime.now());

  Stream<List<ThreadItem>> watchForDate(DateTime d) async* {
    yield getForDate(d);
    await for (final _ in _box.watch()) {
      yield getForDate(d);
    }
  }

  Future<void> add(ThreadItem item) async {
    final key = _keyFor(item.timestamp);
    final existing = getForDate(item.timestamp);
    existing.add(item);
    await _box.put(
      key,
      jsonEncode(existing.map((i) => i.toJson()).toList()),
    );
  }

  Future<void> removeMeal(String mealId, DateTime day) async {
    final key = _keyFor(day);
    final items = getForDate(day);
    // Remove both the meal item and any coach response that was linked to it.
    items.removeWhere((i) =>
        (i.type == ThreadItemType.meal && i.mealId == mealId) ||
        (i.type == ThreadItemType.coachResponse && i.mealId == mealId));
    await _box.put(key, jsonEncode(items.map((i) => i.toJson()).toList()));
  }

  // Removes only the coach response linked to a meal, leaving the meal item
  // itself intact. Used when a meal is edited and we want to regenerate
  // the coach feedback.
  Future<void> removeCoachResponseForMeal(String mealId, DateTime day) async {
    final key = _keyFor(day);
    final items = getForDate(day);
    items.removeWhere((i) =>
        i.type == ThreadItemType.coachResponse && i.mealId == mealId);
    await _box.put(key, jsonEncode(items.map((i) => i.toJson()).toList()));
  }

  // Moves a meal's ThreadItem (and any orphaned coach response on the old
  // day) to a new timestamp / day. Called when an edit changes the meal's
  // createdAt: without this the entry visually stays at the old time, and
  // for cross-day edits in the wrong day bucket entirely.
  //
  // If the meal item isn't found at oldAt (already moved by a previous
  // edit, or createdAt drifted), the call is a silent no-op rather than
  // throwing - defensive against any state we missed.
  Future<void> updateMealItemTime(
      String mealId, DateTime oldAt, DateTime newAt) async {
    final sameDay = oldAt.year == newAt.year &&
        oldAt.month == newAt.month &&
        oldAt.day == newAt.day;
    final oldKey = _keyFor(oldAt);
    final oldItems = getForDate(oldAt);
    final mealIdx = oldItems.indexWhere(
        (i) => i.type == ThreadItemType.meal && i.mealId == mealId);
    if (mealIdx == -1) return;

    if (sameDay) {
      // In-place timestamp swap on the same day's bucket.
      oldItems[mealIdx] = ThreadItem.meal(mealId: mealId, at: newAt);
      await _box.put(
          oldKey, jsonEncode(oldItems.map((i) => i.toJson()).toList()));
      return;
    }

    // Cross-day move: pull the meal item (and any coach response anchored
    // to it) out of the old day, then re-add them into the new day's
    // bucket. The coach response migrates with the meal so an old-day
    // bubble doesn't end up orphaned next to a now-empty slot.
    final coachIdx = oldItems.indexWhere((i) =>
        i.type == ThreadItemType.coachResponse && i.mealId == mealId);
    final coachItem = coachIdx == -1 ? null : oldItems[coachIdx];
    oldItems.removeWhere((i) =>
        (i.type == ThreadItemType.meal && i.mealId == mealId) ||
        (i.type == ThreadItemType.coachResponse && i.mealId == mealId));
    await _box.put(
        oldKey, jsonEncode(oldItems.map((i) => i.toJson()).toList()));

    await add(ThreadItem.meal(mealId: mealId, at: newAt));
    if (coachItem != null) {
      // Keep the coach response anchored to the new meal time + 1 min so
      // it still sorts immediately after the meal in the new day's view.
      await add(ThreadItem.coachResponse(
        mealId: mealId,
        text: coachItem.text ?? '',
        at: newAt.add(const Duration(minutes: 1)),
      ));
    }
  }

  Future<void> clearAll() => _box.clear();

  Stream<List<ThreadItem>> watchToday() async* {
    yield getToday();
    await for (final _ in _box.watch()) {
      yield getToday();
    }
  }

  // Fires on any thread change so consumers can re-read multiple days at once.
  Stream<void> watchAllChanges() async* {
    yield null;
    await for (final _ in _box.watch()) {
      yield null;
    }
  }
}
