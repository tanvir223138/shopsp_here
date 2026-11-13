import '../entities/paged_products.dart';
import '../repositories/product_repository.dart';

class GetProductsPage {
  const GetProductsPage(this._repo);
  final ProductRepository _repo;

  Future<PagedProducts> call(int skip) => _repo.fetchPage(skip);
}
