import '../entities/product.dart';
import '../repositories/product_repository.dart';

class AddProduct {
  const AddProduct(this._repo);
  final ProductRepository _repo;

  Future<void> call(Product product) => _repo.addProduct(product);
}
