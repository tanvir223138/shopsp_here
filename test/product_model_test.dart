import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/data/models/product_model.dart';

void main() {
  test('fromJson parses API data and tolerates missing fields', () {
    final p = ProductModel.fromJson({'id': 1, 'title': 'Phone', 'price': 99});
    expect(p.id, 1);
    expect(p.title, 'Phone');
    expect(p.price, 99.0);
    expect(p.images, isEmpty);
  });

  test('toJson and fromJson round trip', () {
    const p = ProductModel(
      id: 5,
      title: 'Lamp',
      description: 'd',
      category: 'home',
      brand: 'B',
      thumbnail: 't',
      images: ['a'],
      price: 10.5,
    );
    expect(ProductModel.fromJson(p.toJson()).title, 'Lamp');
  });
}
