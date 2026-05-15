import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/meal_entry.dart';

class MealRepository {
  static const _boxName = 'meals';
  final Box<String> _box;

  MealRepository(this._box);

  static Future<MealRepository> open() async {
    final box = await Hive.openBox<String>(_boxName);
    return MealRepository(box);
  }

  Future<void> save(MealEntry meal) async {
    await _box.put(meal.id, jsonEncode(meal.toJson()));
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  List<MealEntry> all() {
    final entries = _box.values
        .map((raw) => MealEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Stream<List<MealEntry>> watch() async* {
    yield all();
    await for (final _ in _box.watch()) {
      yield all();
    }
  }
}
