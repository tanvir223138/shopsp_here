import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../providers/order_provider.dart';
import 'main_shell.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.orderId});
  final String orderId;

  void _goTo(BuildContext context, int tab) {
    shellTab.value = tab;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final order = context.read<OrderProvider>().byId(orderId);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(context, 0);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.elasticOut,
                      builder: (_, v, child) => Transform.scale(scale: v, child: child),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 110,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Order placed!',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thank you for shopping with ShopSphere.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.mutedText),
                    ),
                    const SizedBox(height: 24),
                    if (order != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _row(context, 'Order ID', '#${order.id}'),
                            _row(context, 'Items', '${order.itemCount}'),
                            _row(context, 'Payment', order.method.label),
                            if (order.transactionId != null)
                              _row(context, 'Transaction ID', order.transactionId!),
                            _row(context, 'Status', order.paymentStatus),
                            const Divider(height: 20),
                            _row(context, 'Total', formatBdt(order.total), bold: true),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _goTo(context, 2),
                        child: const Text('VIEW MY ORDERS'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _goTo(context, 0),
                        child: const Text('CONTINUE SHOPPING'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String l, String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(color: context.mutedText)),
        Flexible(
          child: Text(
            v,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.primary : null,
              fontSize: bold ? 18 : null,
            ),
          ),
        ),
      ],
    ),
  );
}
