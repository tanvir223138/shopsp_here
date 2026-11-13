import 'product.dart';

class PagedProducts {
  final List<Product> items;
  final int total;
  const PagedProducts(this.items, this.total);
}
