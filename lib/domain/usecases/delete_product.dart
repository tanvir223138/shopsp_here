import '../entities/product.dart';
import '../repositories/product_repository.dart';

class DeleteProduct {
  const DeleteProduct(this._repo);
  final ProductRepository _repo;

  Future<void> call(Product product) => _repo.deleteProduct(product);
}
