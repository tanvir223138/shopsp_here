import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/domain/entities/local_changes.dart';
import 'package:shopsphere/domain/entities/paged_products.dart';
import 'package:shopsphere/domain/entities/product.dart';
import 'package:shopsphere/domain/repositories/product_repository.dart';
import 'package:shopsphere/domain/usecases/add_product.dart';
import 'package:shopsphere/domain/usecases/cache_products.dart';
import 'package:shopsphere/domain/usecases/delete_product.dart';
import 'package:shopsphere/domain/usecases/get_cached_products.dart';
import 'package:shopsphere/domain/usecases/get_local_changes.dart';
import 'package:shopsphere/domain/usecases/get_products_page.dart';
import 'package:shopsphere/domain/usecases/restore_product.dart';
import 'package:shopsphere/domain/usecases/toggle_favorite.dart';
import 'package:shopsphere/domain/usecases/update_product.dart';
import 'package:shopsphere/providers/product_provider.dart';

const _phone = Product(
  id: 1,
  title: 'Phone',
  description: 'smart',
  category: 'tech',
  brand: 'A',
  thumbnail: '',
  images: [],
  price: 100,
);
const _shirt = Product(
  id: 2,
  title: 'Shirt',
  description: 'cotton',
  category: 'clothes',
  brand: 'B',
  thumbnail: '',
  images: [],
  price: 20,
);

class FakeRepo implements ProductRepository {
  LocalChanges changes = const LocalChanges();

  @override
  Future<PagedProducts> fetchPage(int skip) async => const PagedProducts([_phone, _shirt], 2);
  @override
  PagedProducts getCachedPage() => const PagedProducts([], 0);
  @override
  Future<void> cachePage(PagedProducts page) async {}
  @override
  LocalChanges getLocalChanges() => changes;
  @override
  Future<void> addProduct(Product p) async =>
      changes = changes.copyWith(created: [p, ...changes.created]);
  @override
  Future<void> updateProduct(Product p) async =>
      changes = changes.copyWith(edits: {...changes.edits, p.id: p});
  @override
  Future<void> deleteProduct(Product p) async =>
      changes = changes.copyWith(deleted: {...changes.deleted, p.id});
  @override
  Future<void> restoreProduct(Product p) async =>
      changes = changes.copyWith(deleted: {...changes.deleted}..remove(p.id));
  @override
  Future<void> toggleFavorite(int id) async {
    final f = {...changes.favorites};
    if (!f.remove(id)) f.add(id);
    changes = changes.copyWith(favorites: f);
  }
}

ProductProvider _build(FakeRepo r) => ProductProvider(
  getProductsPage: GetProductsPage(r),
  getCachedProducts: GetCachedProducts(r),
  cacheProducts: CacheProducts(r),
  getLocalChanges: GetLocalChanges(r),
  addProductUseCase: AddProduct(r),
  updateProductUseCase: UpdateProduct(r),
  deleteProductUseCase: DeleteProduct(r),
  restoreProductUseCase: RestoreProduct(r),
  toggleFavoriteUseCase: ToggleFavorite(r),
);

void main() {
  test('loads products and filters by search', () async {
    final p = _build(FakeRepo());
    await p.init();
    expect(p.visible.length, 2);
    p.setQuery('phone');
    expect(p.visible.single.title, 'Phone');
  });

  test('delete updates the list immediately and undo restores it', () async {
    final p = _build(FakeRepo());
    await p.init();
    final pending = p.deleteProduct(_phone);
    expect(p.visible.length, 1); // synchronous, needed for swipe-to-delete
    await pending;
    await p.restoreProduct(_phone);
    expect(p.visible.length, 2);
  });

  test('add and favorite', () async {
    final p = _build(FakeRepo());
    await p.init();
    await p.addProduct(
      title: 'Lamp',
      description: 'light',
      category: 'home',
      brand: '',
      price: 9,
      stock: 1,
      imageUrl: '',
    );
    expect(p.all.length, 3);
    await p.toggleFavorite(_shirt.id);
    p.toggleFavoritesOnly();
    expect(p.visible.single.id, _shirt.id);
  });
}
