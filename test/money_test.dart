import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/money.dart';

void main() {
  test('formatBdt groups thousands', () {
    expect(formatBdt(0), '৳0');
    expect(formatBdt(999), '৳999');
    expect(formatBdt(1299), '৳1,299');
    expect(formatBdt(1234567), '৳1,234,567');
  });

  test('usdToBdt converts with the fixed rate', () {
    expect(usdToBdt(10), 10 * kUsdToBdt);
  });

  test('groceries get a realistic Bangladeshi price (chicken ~165-170 tk)', () {
    final bdt = usdToLocalBdt(9.99, 'groceries', 'Chicken Meat');
    expect(bdt, inInclusiveRange(150, 190));
  });

  test('unknown categories keep the plain exchange rate', () {
    expect(priceFactor('something-new'), 1.0);
  });
}
