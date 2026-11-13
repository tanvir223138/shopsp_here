import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/money.dart';
import '../data/datasource/shop_local_datasource.dart';
import '../domain/entities/cart_item.dart';
import '../domain/entities/product.dart';

class CartProvider extends ChangeNotifier {
  CartProvider(this._ds);
  final ShopLocalDataSource _ds;

  String? _userId;
  List<CartItem> _items = [];
  String? voucher;

  List<CartItem> get items => _items;
  bool get isEmpty => _items.isEmpty;
  int get count => _items.fold(0, (sum, e) => sum + e.quantity);
  double get subtotal => _items.fold(0, (sum, e) => sum + e.lineTotal);

  /// Called by the ProxyProvider whenever the logged in user changes.
  void bind(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _items = userId == null ? [] : _ds.readCart(userId);
    voucher = null;
    scheduleMicrotask(notifyListeners); // never notify while the tree is building
  }

  // ----- price rules -----

  double get discount => voucher == 'WELCOME10' ? min(subtotal * 0.10, 500) : 0;

  double shippingFor(String district) {
    if (_items.isEmpty) return 0;
    if (voucher == 'FREESHIP' || subtotal - discount >= ShopConstants.freeShippingFrom) return 0;
    return district.toLowerCase() == 'dhaka'
        ? ShopConstants.shippingInsideDhaka
        : ShopConstants.shippingOutsideDhaka;
  }

  double totalFor(String district) => subtotal - discount + shippingFor(district);

  /// Returns an error message or null.
  String? applyVoucher(String raw) {
    final code = raw.trim().toUpperCase();
    if (code == 'WELCOME10' || code == 'FREESHIP') {
      voucher = code;
      notifyListeners();
      return null;
    }
    return 'Invalid voucher code';
  }

  void removeVoucher() {
    voucher = null;
    notifyListeners();
  }

  // ----- cart operations -----

  /// Returns an error message or null.
  Future<String?> add(Product p, {int quantity = 1}) async {
    if (p.stock <= 0) return 'This product is out of stock';
    final unit = p.bdtSale;
    final i = _items.indexWhere((e) => e.productId == p.id);
    if (i >= 0) {
      final next = _items[i].quantity + quantity;
      if (next > p.stock) return 'Only ${p.stock} left in stock';
      _items = [..._items]
        ..[i] = _items[i].copyWith(quantity: next, unitPrice: unit, stock: p.stock);
    } else {
      if (quantity > p.stock) return 'Only ${p.stock} left in stock';
      _items = [
        ..._items,
        CartItem(
          productId: p.id,
          title: p.title,
          thumbnail: p.thumbnail,
          unitPrice: unit,
          quantity: quantity,
          stock: p.stock,
        ),
      ];
    }
    notifyListeners();
    await _save();
    return null;
  }

  Future<void> setQuantity(int productId, int quantity) async {
    if (quantity <= 0) return remove(productId);
    _items = _items.map((e) {
      if (e.productId != productId) return e;
      final capped = e.stock > 0 ? min(quantity, e.stock) : quantity;
      return e.copyWith(quantity: capped);
    }).toList();
    notifyListeners();
    await _save();
  }

  Future<void> remove(int productId) async {
    _items = _items.where((e) => e.productId != productId).toList();
    notifyListeners();
    await _save();
  }

  Future<void> clear() async {
    _items = [];
    voucher = null;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final id = _userId;
    if (id != null) await _ds.saveCart(id, _items);
  }
}
