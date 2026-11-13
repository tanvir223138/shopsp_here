import '../entities/paged_products.dart';
import '../repositories/product_repository.dart';

class GetCachedProducts {
  const GetCachedProducts(this._repo);
  final ProductRepository _repo;

  PagedProducts call() => _repo.getCachedPage();
}
