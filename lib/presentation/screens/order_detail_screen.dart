import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/entities/order.dart';
import '../../providers/order_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/payment_ui.dart';
import 'orders_screen.dart' show formatDate, statusColor;

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cancel(Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel order?'),
        content: Text(
          order.method.isOnline
              ? 'Your payment of ${formatBdt(order.total)} will be refunded (demo).'
              : 'This order will be cancelled.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep order')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) context.read<OrderProvider>().cancel(order.id);
  }

  Widget _card(String title, Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(10)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );

  Widget _row(String l, String v, {Color? color, bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(color: bold ? null : context.mutedText)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 16 : null,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().byId(widget.orderId);
    if (order == null) return const Scaffold();

    final now = DateTime.now();
    final step = order.stepAt(now);
    final status = order.statusAt(now);

    return Scaffold(
      appBar: AppBar(title: Text('Order #${order.id}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
            children: [
              _card(
                'Order status',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.cancelled)
                      Row(
                        children: [
                          const Icon(Icons.cancel, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'This order was cancelled',
                            style: TextStyle(
                              color: statusColor(status),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    else
                      _Tracker(step: step),
                    const SizedBox(height: 8),
                    Text(
                      'Placed on ${formatDate(order.createdAt)}',
                      style: TextStyle(fontSize: 12, color: context.mutedText),
                    ),
                  ],
                ),
              ),
              _card(
                'Items',
                Column(
                  children: [
                    for (final it in order.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(width: 56, height: 56, child: AppImage(it.thumbnail)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(it.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  Text(
                                    '${formatBdt(it.unitPrice)} × ${it.quantity}',
                                    style: TextStyle(fontSize: 12, color: context.mutedText),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatBdt(it.lineTotal),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              _card(
                'Delivery address',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.recipient, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(order.phone),
                    Text('${order.address}, ${order.district}'),
                  ],
                ),
              ),
              _card(
                'Payment',
                Column(
                  children: [
                    Row(
                      children: [
                        PaymentBadge(order.method, size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            order.method.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          order.paymentStatus,
                          style: TextStyle(
                            color: order.method.isOnline ? AppColors.success : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (order.transactionId != null) ...[
                      const SizedBox(height: 8),
                      _row('Transaction ID', order.transactionId!),
                    ],
                    const Divider(height: 22),
                    _row('Subtotal', formatBdt(order.subtotal)),
                    if (order.discount > 0)
                      _row('Discount', '-${formatBdt(order.discount)}', color: AppColors.success),
                    _row('Delivery fee', order.shipping == 0 ? 'FREE' : formatBdt(order.shipping)),
                    const Divider(height: 18),
                    _row('Total', formatBdt(order.total), color: AppColors.primary, bold: true),
                  ],
                ),
              ),
              if (order.canCancel(now))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () => _cancel(order),
                    child: const Text('CANCEL ORDER'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tracker extends StatelessWidget {
  const _Tracker({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.receipt_long,
      Icons.inventory_2_outlined,
      Icons.local_shipping_outlined,
      Icons.home_outlined,
    ];
    return Row(
      children: [
        for (var i = 0; i < Order.steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: i <= step ? AppColors.success : Colors.grey.withAlpha(60),
                  child: Icon(
                    i < step ? Icons.check : icons[i],
                    size: 20,
                    color: i <= step ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Order.steps[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: i == step ? FontWeight.w800 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
