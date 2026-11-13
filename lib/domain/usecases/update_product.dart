import '../entities/product.dart';
import '../repositories/product_repository.dart';

class UpdateProduct {
  const UpdateProduct(this._repo);
  final ProductRepository _repo;

  Future<void> call(Product product) => _repo.updateProduct(product);
}
