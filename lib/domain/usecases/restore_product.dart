import '../entities/product.dart';
import '../repositories/product_repository.dart';

class RestoreProduct {
  const RestoreProduct(this._repo);
  final ProductRepository _repo;

  Future<void> call(Product product) => _repo.restoreProduct(product);
}
