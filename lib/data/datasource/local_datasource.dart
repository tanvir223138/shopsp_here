import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/product.dart';
import '../models/product_model.dart';

/// Hive-backed storage: cached API pages, user-created items, edits,
/// deletions, favorites and UI settings.
class LocalDataSource {
  LocalDataSource(this._box);
  final Box _box;

  List<Product> _readList(String key) {
    final raw = _box.get(key);
    if (raw is! String) return <Product>[];
    try {
      return (jsonDecode(raw) as List)
          .map<Product>((e) => ProductModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return <Product>[];
    }
  }

  Future<void> _writeList(String key, List<Product> list) =>
      _box.put(key, jsonEncode(list.map((e) => ProductModel.fromEntity(e).toJson()).toList()));

  Set<int> _readIds(String key) =>
      ((_box.get(key, defaultValue: <dynamic>[]) as List).map((e) => e as int)).toSet();

  Future<void> _writeIds(String key, Set<int> ids) => _box.put(key, ids.toList());

  List<Product> readRemote() => _readList('remote');
  Future<void> saveRemote(List<Product> l) => _writeList('remote', l);

  int readTotal() => _box.get('total', defaultValue: 0) as int;
  Future<void> saveTotal(int t) => _box.put('total', t);

  List<Product> readCreated() => _readList('created');
  Future<void> saveCreated(List<Product> l) => _writeList('created', l);

  Map<int, Product> readEdits() => <int, Product>{for (final p in _readList('edits')) p.id: p};
  Future<void> saveEdits(Map<int, Product> m) => _writeList('edits', m.values.toList());

  Set<int> readDeleted() => _readIds('deleted');
  Future<void> saveDeleted(Set<int> s) => _writeIds('deleted', s);

  Set<int> readFavorites() => _readIds('favorites');
  Future<void> saveFavorites(Set<int> s) => _writeIds('favorites', s);

  bool get isDark => _box.get('dark', defaultValue: false) as bool;
  Future<void> setDark(bool v) => _box.put('dark', v);

  bool get isGridView => _box.get('grid', defaultValue: true) as bool;
  Future<void> setGridView(bool v) => _box.put('grid', v);
}
