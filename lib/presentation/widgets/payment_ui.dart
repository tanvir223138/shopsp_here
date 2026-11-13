import 'package:flutter/material.dart';

import '../../domain/entities/payment_method.dart';

extension PaymentMethodUi on PaymentMethod {
  Color get color => switch (this) {
    PaymentMethod.bkash => const Color(0xFFE2136E),
    PaymentMethod.nagad => const Color(0xFFF26B21),
    PaymentMethod.rocket => const Color(0xFF8C3494),
    PaymentMethod.card => const Color(0xFF1A4FA0),
    PaymentMethod.bank => const Color(0xFF0B7A5B),
    PaymentMethod.cod => const Color(0xFF546E7A),
  };

  IconData get icon => switch (this) {
    PaymentMethod.bkash ||
    PaymentMethod.nagad ||
    PaymentMethod.rocket => Icons.account_balance_wallet_rounded,
    PaymentMethod.card => Icons.credit_card_rounded,
    PaymentMethod.bank => Icons.account_balance_rounded,
    PaymentMethod.cod => Icons.payments_rounded,
  };
}

/// Small coloured badge used in the checkout list and order pages.
class PaymentBadge extends StatelessWidget {
  const PaymentBadge(this.method, {super.key, this.size = 40});
  final PaymentMethod method;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: method.color, borderRadius: BorderRadius.circular(10)),
      child: Icon(method.icon, color: Colors.white, size: size * 0.55),
    );
  }
}
