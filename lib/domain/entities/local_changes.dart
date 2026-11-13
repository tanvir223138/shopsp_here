import 'product.dart';

/// Everything the user changed on this device: new items, edits to API items,
/// deleted API items and favorites.
class LocalChanges {
  final List<Product> created;
  final Map<int, Product> edits;
  final Set<int> deleted;
  final Set<int> favorites;

  const LocalChanges({
    this.created = const [],
    this.edits = const {},
    this.deleted = const {},
    this.favorites = const {},
  });

  LocalChanges copyWith({
    List<Product>? created,
    Map<int, Product>? edits,
    Set<int>? deleted,
    Set<int>? favorites,
  }) {
    return LocalChanges(
      created: created ?? this.created,
      edits: edits ?? this.edits,
      deleted: deleted ?? this.deleted,
      favorites: favorites ?? this.favorites,
    );
  }
}
