import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/entities/order.dart';
import '../../providers/order_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/state_views.dart';
import 'main_shell.dart';
import 'order_detail_screen.dart';

Color statusColor(String status) {
  switch (status) {
    case 'Cancelled':
      return Colors.red;
    case 'Delivered':
      return AppColors.success;
    default:
      return AppColors.primary;
  }
}

String formatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${months[d.month - 1]} ${d.year}, $h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Order status advances with time (demo tracking), so refresh regularly.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: orders.isEmpty
          ? EmptyView(
              icon: Icons.receipt_long_outlined,
              message: "You haven't placed any orders yet.",
              action: FilledButton(
                onPressed: () => shellTab.value = 0,
                child: const Text('Start shopping'),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: orders.length,
                  itemBuilder: (_, i) => _OrderCard(order: orders[i], now: now),
                ),
              ),
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.now});
  final Order order;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final status = order.statusAt(now);
    final shown = order.items.take(4).toList();
    final extra = order.items.length - shown.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor(status).withAlpha(28),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor(status),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                formatDate(order.createdAt),
                style: TextStyle(fontSize: 12, color: context.mutedText),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final it in shown)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(width: 52, height: 52, child: AppImage(it.thumbnail)),
                      ),
                    ),
                  if (extra > 0) Text('+$extra more', style: TextStyle(color: context.mutedText)),
                ],
              ),
              const Divider(height: 22),
              Row(
                children: [
                  Text(
                    '${order.itemCount} item(s) · ${order.method.label}',
                    style: TextStyle(fontSize: 12.5, color: context.mutedText),
                  ),
                  const Spacer(),
                  Text(
                    formatBdt(order.total),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
