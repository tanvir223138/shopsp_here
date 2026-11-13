import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../domain/entities/payment_method.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/payment_ui.dart';
import 'order_success_screen.dart';
import 'payment_gateway_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: context.read<AuthProvider>().user?.name);
  late final _phone = TextEditingController(text: context.read<AuthProvider>().user?.phone);
  late final _address = TextEditingController(text: context.read<AuthProvider>().user?.address);
  late String _district = context.read<AuthProvider>().user?.district ?? 'Dhaka';
  PaymentMethod _method = PaymentMethod.bkash;
  bool _placing = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final cart = context.read<CartProvider>();
    final orders = context.read<OrderProvider>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final total = cart.totalFor(_district);
    String? transactionId;

    if (_method.isOnline) {
      final result = await navigator.push<PaymentResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PaymentGatewayScreen(method: _method, amount: total),
        ),
      );
      if (result == null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Payment cancelled. No money was deducted.')),
          );
        return;
      }
      transactionId = result.transactionId;
    }

    if (!mounted) return;
    setState(() => _placing = true);

    final order = await orders.place(
      items: cart.items,
      subtotal: cart.subtotal,
      discount: cart.discount,
      shipping: cart.shippingFor(_district),
      total: total,
      method: _method,
      recipient: _name.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      district: _district,
      transactionId: transactionId,
    );
    await auth.updateProfile(
      name: auth.user?.name ?? _name.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      district: _district,
    );
    await cart.clear();

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: order.id)),
      (route) => route.isFirst,
    );
  }

  Widget _section(String title, Widget child) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(10)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final shipping = cart.shippingFor(_district);
    final total = cart.totalFor(_district);

    Widget row(String l, String v, {Color? color, bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: TextStyle(color: bold ? null : context.mutedText)),
          Text(
            v,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 16 : null,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      bottomNavigationBar: Material(
        color: context.cardBg,
        elevation: 8,
        child: SafeArea(
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total', style: TextStyle(fontSize: 12, color: context.mutedText)),
                          Text(
                            formatBdt(total),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: (_placing || cart.isEmpty) ? null : _placeOrder,
                      child: _placing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_method.isOnline ? 'PAY & PLACE ORDER' : 'PLACE ORDER'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              children: [
                _section(
                  'Delivery address',
                  Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        validator: (v) => Validators.required(v, 'Full name'),
                        decoration: const InputDecoration(labelText: 'Full name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: Validators.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText: '01XXXXXXXXX',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _district,
                        decoration: const InputDecoration(labelText: 'District'),
                        items: [
                          for (final d in ShopConstants.districts)
                            DropdownMenuItem(value: d, child: Text(d)),
                        ],
                        onChanged: (v) => setState(() => _district = v ?? _district),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        maxLines: 2,
                        validator: (v) => Validators.required(v, 'Address'),
                        decoration: const InputDecoration(
                          labelText: 'House, road, area',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                _section(
                  'Your items (${cart.count})',
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final it = cart.items[i];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(width: 64, height: 64, child: AppImage(it.thumbnail)),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(6)),
                                ),
                                child: Text(
                                  'x${it.quantity}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                _section(
                  'Payment method',
                  Column(
                    children: [
                      for (final m in PaymentMethod.values)
                        _MethodTile(
                          method: m,
                          selected: _method == m,
                          onTap: () => setState(() => _method = m),
                        ),
                    ],
                  ),
                ),
                _section(
                  'Order summary',
                  Column(
                    children: [
                      row('Subtotal', formatBdt(cart.subtotal)),
                      if (cart.discount > 0)
                        row(
                          'Voucher discount',
                          '-${formatBdt(cart.discount)}',
                          color: AppColors.success,
                        ),
                      row(
                        'Delivery fee',
                        shipping == 0 ? 'FREE' : formatBdt(shipping),
                        color: shipping == 0 ? AppColors.success : null,
                      ),
                      const Divider(height: 18),
                      row('Total', formatBdt(total), color: AppColors.primary, bold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.method, required this.selected, required this.onTap});
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.withAlpha(90),
            width: selected ? 1.6 : 1,
          ),
          color: selected ? AppColors.primary.withAlpha(14) : null,
        ),
        child: Row(
          children: [
            PaymentBadge(method),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(method.subtitle, style: TextStyle(fontSize: 12, color: context.mutedText)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
