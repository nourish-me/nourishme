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
    items.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return items;
  }

  List<ThreadItem> getToday() => getForDate(DateTime.now());

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
    items.removeWhere((i) => i.type == ThreadItemType.meal && i.mealId == mealId);
    await _box.put(key, jsonEncode(items.map((i) => i.toJson()).toList()));
  }

  Stream<List<ThreadItem>> watchToday() async* {
    yield getToday();
    await for (final _ in _box.watch()) {
      yield getToday();
    }
  }
}
