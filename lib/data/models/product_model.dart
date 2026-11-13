import '../../domain/entities/product.dart';

/// Product + JSON (de)serialization.
class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.brand,
    required super.thumbnail,
    required super.images,
    required super.price,
    super.discountPercentage,
    super.rating,
    super.stock,
    super.isLocal,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      brand: json['brand']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isLocal: json['isLocal'] == true,
    );
  }

  factory ProductModel.fromEntity(Product p) => ProductModel(
    id: p.id,
    title: p.title,
    description: p.description,
    category: p.category,
    brand: p.brand,
    thumbnail: p.thumbnail,
    images: p.images,
    price: p.price,
    discountPercentage: p.discountPercentage,
    rating: p.rating,
    stock: p.stock,
    isLocal: p.isLocal,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'brand': brand,
    'thumbnail': thumbnail,
    'images': images,
    'price': price,
    'discountPercentage': discountPercentage,
    'rating': rating,
    'stock': stock,
    'isLocal': isLocal,
  };
}
