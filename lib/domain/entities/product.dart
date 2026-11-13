/// Pure business object. It knows nothing about JSON, Hive or Flutter.
class Product {
  final int id;
  final String title;
  final String description;
  final String category;
  final String brand;
  final String thumbnail;
  final List<String> images;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final bool isLocal; // created by the user inside the app

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.brand,
    required this.thumbnail,
    required this.images,
    required this.price,
    this.discountPercentage = 0,
    this.rating = 0,
    this.stock = 0,
    this.isLocal = false,
  });

  bool get hasDiscount => discountPercentage > 0;

  /// Price after discount (USD, as returned by the API).
  double get salePrice => hasDiscount ? price * (1 - discountPercentage / 100) : price;

  Product copyWith({
    String? title,
    String? description,
    String? category,
    String? brand,
    String? thumbnail,
    List<String>? images,
    double? price,
    int? stock,
  }) {
    return Product(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      thumbnail: thumbnail ?? this.thumbnail,
      images: images ?? this.images,
      price: price ?? this.price,
      discountPercentage: discountPercentage,
      rating: rating,
      stock: stock ?? this.stock,
      isLocal: isLocal,
    );
  }
}
