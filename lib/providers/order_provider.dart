import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/datasource/shop_local_datasource.dart';
import '../domain/entities/cart_item.dart';
import '../domain/entities/order.dart';
import '../domain/entities/payment_method.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(this._ds);
  final ShopLocalDataSource _ds;

  String? _userId;
  List<Order> _orders = [];

  /// Newest first.
  List<Order> get orders => _orders;

  Order? byId(String id) {
    for (final o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  void bind(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _orders = userId == null ? [] : _ds.readOrders(userId);
    scheduleMicrotask(notifyListeners);
  }

  Future<Order> place({
    required List<CartItem> items,
    required double subtotal,
    required double discount,
    required double shipping,
    required double total,
    required PaymentMethod method,
    required String recipient,
    required String phone,
    required String address,
    required String district,
    String? transactionId,
  }) async {
    final stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final order = Order(
      id: 'SS${stamp.substring(stamp.length - 9)}',
      userId: _userId ?? '',
      items: List.of(items),
      subtotal: subtotal,
      discount: discount,
      shipping: shipping,
      total: total,
      method: method,
      paymentStatus: method.isOnline ? 'Paid' : 'Pay on delivery',
      transactionId: transactionId,
      recipient: recipient,
      phone: phone,
      address: address,
      district: district,
      createdAt: DateTime.now(),
    );
    _orders = [order, ..._orders];
    notifyListeners();
    await _save();
    return order;
  }

  Future<void> cancel(String id) async {
    _orders = _orders.map((o) => o.id == id ? o.copyWith(cancelled: true) : o).toList();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final id = _userId;
    if (id != null) await _ds.saveOrders(id, _orders);
  }
}
