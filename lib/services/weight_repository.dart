import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/weight_entry.dart';

// Tracks every weight reading the user enters in Settings or onboarding,
// so the Trends tab can show the trajectory over time. Pregnancy/post-
// partum guidance is intentionally NOT part of this layer: we only
// persist the numbers and the date the user recorded them.
class WeightRepository {
  static const _boxName = 'weights';
  final Box<String> _box;

  WeightRepository(this._box);

  static Future<WeightRepository> open() async {
    final box = await Hive.openBox<String>(_boxName);
    return WeightRepository(box);
  }

  Future<void> save(WeightEntry entry) async {
    await _box.put(entry.id, jsonEncode(entry.toJson()));
  }

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clearAll() => _box.clear();

  List<WeightEntry> all() {
    final entries = _box.values
        .map((raw) =>
            WeightEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
    entries.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return entries;
  }

  Stream<List<WeightEntry>> watch() async* {
    yield all();
    await for (final _ in _box.watch()) {
      yield all();
    }
  }
}
