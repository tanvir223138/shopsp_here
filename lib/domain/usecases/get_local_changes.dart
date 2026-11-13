import '../entities/local_changes.dart';
import '../repositories/product_repository.dart';

class GetLocalChanges {
  const GetLocalChanges(this._repo);
  final ProductRepository _repo;

  LocalChanges call() => _repo.getLocalChanges();
}
