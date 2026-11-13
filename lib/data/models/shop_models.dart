import '../../domain/entities/app_user.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/payment_method.dart';

// JSON (de)serialization for the shop entities (stored in Hive as JSON text).

extension AppUserJson on AppUser {
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'passwordHash': passwordHash,
    'address': address,
    'district': district,
    'emailVerified': emailVerified,
  };
}

AppUser appUserFromJson(Map<String, dynamic> j) => AppUser(
  id: j['id'] as String,
  name: j['name'] as String,
  email: j['email'] as String,
  phone: j['phone'] as String,
  passwordHash: j['passwordHash'] as String,
  address: (j['address'] as String?) ?? '',
  district: (j['district'] as String?) ?? 'Dhaka',
  // accounts created before email verification existed count as verified
  emailVerified: (j['emailVerified'] as bool?) ?? true,
);

extension CartItemJson on CartItem {
  Map<String, dynamic> toJson() => {
    'productId': productId,
    'title': title,
    'thumbnail': thumbnail,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'stock': stock,
  };
}

CartItem cartItemFromJson(Map<String, dynamic> j) => CartItem(
  productId: (j['productId'] as num).toInt(),
  title: j['title'] as String,
  thumbnail: (j['thumbnail'] as String?) ?? '',
  unitPrice: (j['unitPrice'] as num).toDouble(),
  quantity: (j['quantity'] as num).toInt(),
  stock: (j['stock'] as num?)?.toInt() ?? 0,
);

extension OrderJson on Order {
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'items': items.map((e) => e.toJson()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'shipping': shipping,
    'total': total,
    'method': method.name,
    'paymentStatus': paymentStatus,
    'transactionId': transactionId,
    'recipient': recipient,
    'phone': phone,
    'address': address,
    'district': district,
    'createdAt': createdAt.toIso8601String(),
    'cancelled': cancelled,
  };
}

Order orderFromJson(Map<String, dynamic> j) => Order(
  id: j['id'] as String,
  userId: j['userId'] as String,
  items: (j['items'] as List)
      .map<CartItem>((e) => cartItemFromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  subtotal: (j['subtotal'] as num).toDouble(),
  discount: (j['discount'] as num).toDouble(),
  shipping: (j['shipping'] as num).toDouble(),
  total: (j['total'] as num).toDouble(),
  method: PaymentMethod.values.byName(j['method'] as String),
  paymentStatus: j['paymentStatus'] as String,
  transactionId: j['transactionId'] as String?,
  recipient: j['recipient'] as String,
  phone: j['phone'] as String,
  address: j['address'] as String,
  district: j['district'] as String,
  createdAt: DateTime.parse(j['createdAt'] as String),
  cancelled: j['cancelled'] == true,
);
