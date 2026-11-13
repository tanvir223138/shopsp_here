import 'package:flutter/foundation.dart';

import '../core/money.dart';
import '../domain/entities/local_changes.dart';
import '../domain/entities/paged_products.dart';
import '../domain/entities/product.dart';
import '../domain/failures.dart';
import '../domain/usecases/add_product.dart';
import '../domain/usecases/cache_products.dart';
import '../domain/usecases/delete_product.dart';
import '../domain/usecases/get_cached_products.dart';
import '../domain/usecases/get_local_changes.dart';
import '../domain/usecases/get_products_page.dart';
import '../domain/usecases/restore_product.dart';
import '../domain/usecases/toggle_favorite.dart';
import '../domain/usecases/update_product.dart';

enum SortOption { none, priceLow, priceHigh, rating, title }

class ProductProvider extends ChangeNotifier {
  ProductProvider({
    required GetProductsPage getProductsPage,
    required GetCachedProducts getCachedProducts,
    required CacheProducts cacheProducts,
    required GetLocalChanges getLocalChanges,
    required AddProduct addProductUseCase,
    required UpdateProduct updateProductUseCase,
    required DeleteProduct deleteProductUseCase,
    required RestoreProduct restoreProductUseCase,
    required ToggleFavorite toggleFavoriteUseCase,
  }) : _getProductsPage = getProductsPage,
       _getCachedProducts = getCachedProducts,
       _cacheProducts = cacheProducts,
       _getLocalChanges = getLocalChanges,
       _addProduct = addProductUseCase,
       _updateProduct = updateProductUseCase,
       _deleteProduct = deleteProductUseCase,
       _restoreProduct = restoreProductUseCase,
       _toggleFavorite = toggleFavoriteUseCase;

  final GetProductsPage _getProductsPage;
  final GetCachedProducts _getCachedProducts;
  final CacheProducts _cacheProducts;
  final GetLocalChanges _getLocalChanges;
  final AddProduct _addProduct;
  final UpdateProduct _updateProduct;
  final DeleteProduct _deleteProduct;
  final RestoreProduct _restoreProduct;
  final ToggleFavorite _toggleFavorite;

  List<Product> _remote = [];
  LocalChanges _changes = const LocalChanges();
  int _total = 0;

  bool isLoading = true; // first load with nothing cached
  bool isLoadingMore = false;
  bool loadMoreFailed = false;
  bool offline = false;
  String? errorMessage; // full-screen error (nothing to show)
  String _lastError = '';

  String query = '';
  String? category;
  bool favoritesOnly = false;
  SortOption sort = SortOption.none;

  bool get hasMore => _remote.length < _total;
  Set<int> get favorites => _changes.favorites;
  String get lastError => _lastError;

  List<Product> get all => [
    ..._changes.created,
    ..._remote.where((p) => !_changes.deleted.contains(p.id)).map((p) => _changes.edits[p.id] ?? p),
  ];

  List<String> get categories {
    final list = all.map((p) => p.category).where((c) => c.isNotEmpty).toSet().toList()..sort();
    return list;
  }

  List<Product> get visible {
    final q = query.trim().toLowerCase();
    final list = all.where((p) {
      if (favoritesOnly && !favorites.contains(p.id)) return false;
      if (category != null && p.category != category) return false;
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();

    switch (sort) {
      case SortOption.priceLow:
        list.sort((a, b) => a.bdtSale.compareTo(b.bdtSale));
        break;
      case SortOption.priceHigh:
        list.sort((a, b) => b.bdtSale.compareTo(a.bdtSale));
        break;
      case SortOption.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.title:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.none:
        break;
    }
    return list;
  }

  Product? findById(int id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---------- loading ----------

  Future<void> init() async {
    final cached = _getCachedProducts();
    _remote = cached.items;
    _total = cached.total;
    _changes = _getLocalChanges();
    isLoading = _remote.isEmpty;
    notifyListeners();
    await refresh();
  }

  /// Reloads page 1 from the API. Returns false if it failed.
  Future<bool> refresh() async {
    try {
      final page = await _getProductsPage(0);
      _remote = page.items;
      _total = page.total;
      await _cacheProducts(page);
      offline = false;
      errorMessage = null;
      return true;
    } catch (e) {
      _lastError = _messageFor(e);
      if (_remote.isEmpty) {
        errorMessage = _lastError;
      } else {
        offline = true;
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retryInitial() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    await refresh();
  }

  Future<void> loadMore() async {
    if (isLoadingMore || isLoading || !hasMore) return;
    isLoadingMore = true;
    loadMoreFailed = false;
    notifyListeners();
    try {
      final page = await _getProductsPage(_remote.length);
      final known = _remote.map((p) => p.id).toSet();
      _remote = [..._remote, ...page.items.where((p) => !known.contains(p.id))];
      _total = page.total;
      await _cacheProducts(PagedProducts(_remote, _total));
      offline = false;
    } catch (e) {
      _lastError = _messageFor(e);
      loadMoreFailed = true;
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  String _messageFor(Object e) =>
      e is Failure ? e.message : 'Something went wrong. Please try again.';

  // ---------- filters ----------

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void setCategory(String? c) {
    category = c;
    notifyListeners();
  }

  void setSort(SortOption s) {
    sort = s;
    notifyListeners();
  }

  void toggleFavoritesOnly() {
    favoritesOnly = !favoritesOnly;
    notifyListeners();
  }

  // ---------- CRUD ----------

  /// Runs a use case, refreshes the UI immediately (the repository updates
  /// its in-memory state before its first await), then waits for persistence.
  Future<void> _mutate(Future<void> Function() action) async {
    final pending = action();
    _changes = _getLocalChanges();
    notifyListeners();
    await pending;
  }

  Future<void> toggleFavorite(int id) => _mutate(() => _toggleFavorite(id));

  Future<void> addProduct({
    required String title,
    required String description,
    required String category,
    required String brand,
    required double price,
    required int stock,
    required String imageUrl,
  }) {
    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      description: description,
      category: category,
      brand: brand,
      price: price,
      stock: stock,
      thumbnail: imageUrl,
      images: imageUrl.isEmpty ? [] : [imageUrl],
      isLocal: true,
    );
    return _mutate(() => _addProduct(product));
  }

  Future<void> updateProduct(Product updated) => _mutate(() => _updateProduct(updated));

  Future<void> deleteProduct(Product product) => _mutate(() => _deleteProduct(product));

  /// Undo for delete.
  Future<void> restoreProduct(Product product) => _mutate(() => _restoreProduct(product));
}
