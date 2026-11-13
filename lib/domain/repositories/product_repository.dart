import '../entities/local_changes.dart';
import '../entities/paged_products.dart';
import '../entities/product.dart';

/// Contract between the domain and data layers.
/// Mutating methods update the in-memory [LocalChanges] synchronously and
/// persist afterwards, so the UI can react in the same frame.
abstract class ProductRepository {
  Future<PagedProducts> fetchPage(int skip);
  PagedProducts getCachedPage();
  Future<void> cachePage(PagedProducts page);

  LocalChanges getLocalChanges();
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(Product product);
  Future<void> restoreProduct(Product product);
  Future<void> toggleFavorite(int id);
}
