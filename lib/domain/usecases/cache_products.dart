import '../entities/paged_products.dart';
import '../repositories/product_repository.dart';

class CacheProducts {
  const CacheProducts(this._repo);
  final ProductRepository _repo;

  Future<void> call(PagedProducts page) => _repo.cachePage(page);
}
