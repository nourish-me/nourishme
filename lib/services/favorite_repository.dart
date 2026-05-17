import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/favorite_meal.dart';

class FavoriteRepository {
  static const _boxName = 'favorites';
  final Box<String> _box;

  FavoriteRepository(this._box);

  static Future<FavoriteRepository> open() async {
    final box = await Hive.openBox<String>(_boxName);
    return FavoriteRepository(box);
  }

  Future<void> save(FavoriteMeal favorite) async {
    await _box.put(favorite.id, jsonEncode(favorite.toJson()));
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  List<FavoriteMeal> all() {
    final entries = _box.values
        .map((raw) =>
            FavoriteMeal.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
    entries.sort((a, b) => a.summary.compareTo(b.summary));
    return entries;
  }

  Stream<List<FavoriteMeal>> watch() async* {
    yield all();
    await for (final _ in _box.watch()) {
      yield all();
    }
  }
}
