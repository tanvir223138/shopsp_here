import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../models/shop_models.dart';

/// Hive storage for accounts, the login session, carts and orders.
class ShopLocalDataSource {
  ShopLocalDataSource(this._box);
  final Box _box;

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) parse) {
    final raw = _box.get(key);
    if (raw is! String) return <T>[];
    try {
      return (jsonDecode(raw) as List)
          .map<T>((e) => parse(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> list) =>
      _box.put(key, jsonEncode(list));

  // accounts + session
  List<AppUser> readUsers() => _readList('users', appUserFromJson);
  Future<void> saveUsers(List<AppUser> users) =>
      _writeList('users', users.map((e) => e.toJson()).toList());

  String? readSession() => _box.get('session_uid') as String?;
  Future<void> saveSession(String? userId) =>
      userId == null ? _box.delete('session_uid') : _box.put('session_uid', userId);

  // pending email verification code (one per user)
  Map<String, dynamic>? readVerification(String userId) {
    final raw = _box.get('verify_$userId');
    if (raw is! String) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveVerification(String userId, Map<String, dynamic>? data) =>
      data == null ? _box.delete('verify_$userId') : _box.put('verify_$userId', jsonEncode(data));

  // cart (one per user)
  List<CartItem> readCart(String userId) => _readList('cart_$userId', cartItemFromJson);
  Future<void> saveCart(String userId, List<CartItem> items) =>
      _writeList('cart_$userId', items.map((e) => e.toJson()).toList());

  // orders (one list per user)
  List<Order> readOrders(String userId) => _readList('orders_$userId', orderFromJson);
  Future<void> saveOrders(String userId, List<Order> orders) =>
      _writeList('orders_$userId', orders.map((e) => e.toJson()).toList());
}
