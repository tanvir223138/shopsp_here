/// A product snapshot inside the cart. Prices are in BDT.
class CartItem {
  final int productId;
  final String title;
  final String thumbnail;
  final double unitPrice;
  final int quantity;
  final int stock;

  const CartItem({
    required this.productId,
    required this.title,
    required this.thumbnail,
    required this.unitPrice,
    required this.quantity,
    required this.stock,
  });

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity, double? unitPrice, int? stock}) => CartItem(
    productId: productId,
    title: title,
    thumbnail: thumbnail,
    unitPrice: unitPrice ?? this.unitPrice,
    quantity: quantity ?? this.quantity,
    stock: stock ?? this.stock,
  );
}
