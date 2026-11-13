import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shopsphere/data/datasource/shop_local_datasource.dart';
import 'package:shopsphere/domain/entities/product.dart';
import 'package:shopsphere/providers/auth_provider.dart';
import 'package:shopsphere/providers/cart_provider.dart';

const _phone = Product(
  id: 1,
  title: 'Phone',
  description: 'smart',
  category: 'tech',
  brand: 'A',
  thumbnail: '',
  images: [],
  price: 10,
  discountPercentage: 0,
  stock: 3,
); // 10 USD -> 1200 BDT

void main() {
  late ShopLocalDataSource ds;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('shop_test');
    Hive.init(dir.path);
    final box = await Hive.openBox('t_${DateTime.now().microsecondsSinceEpoch}');
    ds = ShopLocalDataSource(box);
  });

  test('cart totals, stock limit, vouchers and shipping', () async {
    final cart = CartProvider(ds)..bind('u1');
    expect(await cart.add(_phone, quantity: 2), isNull);
    expect(cart.count, 2);
    expect(cart.subtotal, 2400);
    expect(cart.shippingFor('Dhaka'), 60);
    expect(cart.shippingFor('Sylhet'), 120);

    expect(await cart.add(_phone, quantity: 2), isNotNull); // only 3 in stock

    expect(cart.applyVoucher('nope'), isNotNull);
    expect(cart.applyVoucher('welcome10'), isNull);
    expect(cart.discount, 240);
    cart.applyVoucher('FREESHIP');
    expect(cart.shippingFor('Sylhet'), 0);

    await cart.setQuantity(1, 0);
    expect(cart.isEmpty, isTrue);
  });

  test('cart is saved per user', () async {
    final a = CartProvider(ds)..bind('u1');
    await a.add(_phone);
    final b = CartProvider(ds)..bind('u1');
    expect(b.count, 1);
    final c = CartProvider(ds)..bind('u2');
    expect(c.count, 0);
  });

  test('register, verify email, logout and login', () async {
    final auth = AuthProvider(ds); // email service not configured -> demo mode
    expect(
      await auth.register(
        name: 'Rahim',
        phone: '01711111111',
        email: 'r@x.com',
        password: 'secret1',
      ),
      isNull,
    );
    // not logged in until the email is verified
    expect(auth.isLoggedIn, isFalse);
    expect(await auth.login('r@x.com', 'secret1'), AuthProvider.needsVerification);

    final sent = await auth.sendVerificationCode('r@x.com');
    expect(sent.devCode, isNotNull);
    expect(await auth.verifyEmail('r@x.com', '000000'), isNotNull); // wrong code
    expect(auth.isLoggedIn, isFalse);
    expect(await auth.verifyEmail('r@x.com', sent.devCode!), isNull);
    expect(auth.isLoggedIn, isTrue);

    expect(
      await auth.register(name: 'Dup', phone: '01722222222', email: 'R@x.com', password: 'secret1'),
      isNotNull,
    );
    await auth.logout();
    expect(auth.isLoggedIn, isFalse);
    expect(await auth.login('r@x.com', 'wrong'), isNotNull);
    expect(await auth.login('01711111111', 'secret1'), isNull);
    expect(auth.user!.name, 'Rahim');
  });
}
