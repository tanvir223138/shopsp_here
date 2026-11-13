import '../repositories/product_repository.dart';

class ToggleFavorite {
  const ToggleFavorite(this._repo);
  final ProductRepository _repo;

  Future<void> call(int id) => _repo.toggleFavorite(id);
}
