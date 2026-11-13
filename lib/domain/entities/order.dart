import 'cart_item.dart';
import 'payment_method.dart';

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double shipping;
  final double total;
  final PaymentMethod method;
  final String paymentStatus; // Paid / Pay on delivery
  final String? transactionId;
  final String recipient;
  final String phone;
  final String address;
  final String district;
  final DateTime createdAt;
  final bool cancelled;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.total,
    required this.method,
    required this.paymentStatus,
    required this.recipient,
    required this.phone,
    required this.address,
    required this.district,
    required this.createdAt,
    this.transactionId,
    this.cancelled = false,
  });

  static const List<String> steps = ['Placed', 'Packed', 'Shipped', 'Delivered'];

  /// Demo tracking: the order advances one step every minute.
  /// Returns -1 when cancelled.
  int stepAt(DateTime now) {
    if (cancelled) return -1;
    final minutes = now.difference(createdAt).inMinutes;
    return minutes.clamp(0, steps.length - 1);
  }

  String statusAt(DateTime now) {
    final s = stepAt(now);
    return s < 0 ? 'Cancelled' : steps[s];
  }

  bool canCancel(DateTime now) {
    final s = stepAt(now);
    return s >= 0 && s < 2;
  }

  int get itemCount => items.fold(0, (sum, e) => sum + e.quantity);

  Order copyWith({bool? cancelled}) => Order(
    id: id,
    userId: userId,
    items: items,
    subtotal: subtotal,
    discount: discount,
    shipping: shipping,
    total: total,
    method: method,
    paymentStatus: paymentStatus,
    transactionId: transactionId,
    recipient: recipient,
    phone: phone,
    address: address,
    district: district,
    createdAt: createdAt,
    cancelled: cancelled ?? this.cancelled,
  );
}
