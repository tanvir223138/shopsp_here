import '../domain/entities/product.dart';

/// DummyJSON prices are in USD. The app shows everything in Bangladeshi Taka.
const double kUsdToBdt = 120;

double usdToBdt(double usd) => (usd * kUsdToBdt).roundToDouble();

/// 1234567 -> ৳1,234,567
String formatBdt(num amount) {
  final n = amount.round();
  final digits = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${n < 0 ? '-' : ''}৳$buf';
}

/// DummyJSON prices are US-market prices, so a flat x120 makes groceries absurdly
/// expensive in Bangladesh (chicken 1,199/kg). Each category gets a local-market
/// factor so shelf prices look like local Bangladeshi shop prices.
const Map<String, double> _categoryFactor = {
  'groceries': 0.14,
  'beauty': 0.6,
  'skin-care': 0.6,
  'fragrances': 0.8,
  'furniture': 0.8,
  'home-decoration': 0.6,
  'kitchen-accessories': 0.6,
  'laptops': 0.6,
  'smartphones': 0.7,
  'tablets': 0.7,
  'mobile-accessories': 0.7,
  'mens-shirts': 0.5,
  'tops': 0.5,
  'womens-dresses': 0.5,
  'mens-shoes': 0.5,
  'womens-shoes': 0.5,
  'mens-watches': 0.5,
  'womens-watches': 0.5,
  'womens-bags': 0.5,
  'womens-jewellery': 0.5,
  'sunglasses': 0.5,
  'sports-accessories': 0.6,
  'motorcycle': 0.45,
  'vehicle': 0.8,
};

/// A few grocery items that need their own factor to match the local market
/// (checked against the product title, lower case).
const Map<String, double> _titleFactor = {
  'beef': 0.5,
  'fish': 0.4,
  'protein': 1.6,
  'honey': 0.5,
  'cooking oil': 0.5,
  'rice': 0.55,
  'nescafe': 0.4,
  'egg': 0.42,
  'ice cream': 0.3,
  'milk': 0.2,
  'potato': 0.2,
  'water': 0.15,
};

/// Local-market multiplier applied on top of [kUsdToBdt].
double priceFactor(String category, [String title = '']) {
  final c = category.trim().toLowerCase();
  if (c == 'groceries') {
    final t = title.toLowerCase();
    for (final e in _titleFactor.entries) {
      if (t.contains(e.key)) return e.value;
    }
  }
  return _categoryFactor[c] ?? 1.0;
}

/// Converts a USD amount of a product to a realistic Bangladeshi price.
double usdToLocalBdt(double usd, String category, [String title = '']) =>
    (usd * kUsdToBdt * priceFactor(category, title)).roundToDouble();

extension ProductBdtPrice on Product {
  /// Original price in ৳.
  double get bdtPrice => usdToLocalBdt(price, category, title);

  /// Price after discount in ৳.
  double get bdtSale => usdToLocalBdt(salePrice, category, title);
}
