import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/entities/local_changes.dart';
import '../../domain/entities/paged_products.dart';
import '../../domain/entities/product.dart';
import '../../domain/failures.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasource/local_datasource.dart';
import '../datasource/remote_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({required this.remote, required this.local});
  final RemoteDataSource remote;
  final LocalDataSource local;

  // In-memory copy of the user's local changes (loaded once from Hive).
  LocalChanges? _changes;

  // ---------- API + cache ----------

  @override
  Future<PagedProducts> fetchPage(int skip) async {
    try {
      return await remote.fetchProducts(skip: skip);
    } on DioException catch (e) {
      final noNet =
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.error is SocketException;
      if (noNet) throw const NetworkFailure();
      throw ServerFailure(
        'Server error (${e.response?.statusCode ?? 'unknown'}). Please try again.',
      );
    } catch (_) {
      throw const UnknownFailure();
    }
  }

  @override
  PagedProducts getCachedPage() => PagedProducts(local.readRemote(), local.readTotal());

  @override
  Future<void> cachePage(PagedProducts page) async {
    await local.saveRemote(page.items);
    await local.saveTotal(page.total);
  }

  // ---------- local changes ----------
  // Each method below changes `_changes` BEFORE its first `await`, so callers
  // can read the new state synchronously right after calling it.

  @override
  LocalChanges getLocalChanges() => _changes ??= LocalChanges(
    created: local.readCreated(),
    edits: local.readEdits(),
    deleted: local.readDeleted(),
    favorites: local.readFavorites(),
  );

  @override
  Future<void> addProduct(Product product) async {
    final c = getLocalChanges();
    final next = c.copyWith(created: [product, ...c.created]);
    _changes = next;
    await local.saveCreated(next.created);
    unawaited(_safe(() => remote.create(ProductModel.fromEntity(product).toJson())));
  }

  @override
  Future<void> updateProduct(Product product) async {
    final c = getLocalChanges();
    if (product.isLocal) {
      final next = c.copyWith(
        created: c.created.map((p) => p.id == product.id ? product : p).toList(),
      );
      _changes = next;
      await local.saveCreated(next.created);
    } else {
      final next = c.copyWith(edits: {...c.edits, product.id: product});
      _changes = next;
      await local.saveEdits(next.edits);
      unawaited(_safe(() => remote.update(product.id, ProductModel.fromEntity(product).toJson())));
    }
  }

  @override
  Future<void> deleteProduct(Product product) async {
    final c = getLocalChanges();
    if (product.isLocal) {
      final next = c.copyWith(created: c.created.where((p) => p.id != product.id).toList());
      _changes = next;
      await local.saveCreated(next.created);
    } else {
      final next = c.copyWith(
        deleted: {...c.deleted, product.id},
        edits: {...c.edits}..remove(product.id),
      );
      _changes = next;
      await local.saveDeleted(next.deleted);
      await local.saveEdits(next.edits);
      unawaited(_safe(() => remote.delete(product.id)));
    }
  }

  @override
  Future<void> restoreProduct(Product product) async {
    final c = getLocalChanges();
    if (product.isLocal) {
      final next = c.copyWith(created: [product, ...c.created]);
      _changes = next;
      await local.saveCreated(next.created);
    } else {
      final next = c.copyWith(
        deleted: {...c.deleted}..remove(product.id),
        edits: {...c.edits, product.id: product},
      );
      _changes = next;
      await local.saveDeleted(next.deleted);
      await local.saveEdits(next.edits);
    }
  }

  @override
  Future<void> toggleFavorite(int id) async {
    final c = getLocalChanges();
    final favs = {...c.favorites};
    if (!favs.remove(id)) favs.add(id);
    _changes = c.copyWith(favorites: favs);
    await local.saveFavorites(favs);
  }

  // Calls to the real API are best-effort: local data always wins.
  Future<void> _safe(Future<void> Function() call) async {
    try {
      await call();
    } catch (_) {}
  }
}
