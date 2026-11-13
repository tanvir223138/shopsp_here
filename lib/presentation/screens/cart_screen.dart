import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/entities/cart_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/state_views.dart';
import 'checkout_screen.dart';
import 'main_shell.dart';

/// Works both as a bottom-nav tab and as a pushed page.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _voucher = TextEditingController();

  @override
  void dispose() {
    _voucher.dispose();
    super.dispose();
  }

  void _applyVoucher() {
    final cart = context.read<CartProvider>();
    final error = cart.applyVoucher(_voucher.text);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? 'Voucher applied')));
    if (error == null) _voucher.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final district = context.watch<AuthProvider>().user?.district ?? 'Dhaka';

    return Scaffold(
      appBar: AppBar(
        title: Text(cart.isEmpty ? 'My Cart' : 'My Cart (${cart.count})'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear cart?'),
                    content: const Text('All items will be removed from your cart.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) context.read<CartProvider>().clear();
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? EmptyView(
              icon: Icons.shopping_cart_outlined,
              message: 'Your cart is empty.',
              action: FilledButton(
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  shellTab.value = 0;
                },
                child: const Text('Start shopping'),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    for (final item in cart.items) _CartTile(item: item),
                    _voucherCard(context, cart),
                    _summaryCard(context, cart, district),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Material(
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
                                Text(
                                  'Total',
                                  style: TextStyle(fontSize: 12, color: context.mutedText),
                                ),
                                Text(
                                  formatBdt(cart.totalFor(district)),
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
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                            ),
                            child: Text('CHECKOUT (${cart.count})'),
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

  Widget _voucherCard(BuildContext context, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(10)),
      child: cart.voucher != null
          ? Row(
              children: [
                const Icon(Icons.local_offer_rounded, color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Voucher ${cart.voucher} applied',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(onPressed: cart.removeVoucher, child: const Text('Remove')),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _voucher,
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _applyVoucher(),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Enter voucher code',
                          prefixIcon: Icon(Icons.local_offer_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(onPressed: _applyVoucher, child: const Text('Apply')),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Try WELCOME10 (10% off, max ৳500) or FREESHIP',
                  style: TextStyle(fontSize: 12, color: context.mutedText),
                ),
              ],
            ),
    );
  }

  Widget _summaryCard(BuildContext context, CartProvider cart, String district) {
    final shipping = cart.shippingFor(district);
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
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          row('Subtotal (${cart.count} items)', formatBdt(cart.subtotal)),
          if (cart.discount > 0)
            row('Voucher discount', '-${formatBdt(cart.discount)}', color: AppColors.success),
          row(
            'Delivery to $district',
            shipping == 0 ? 'FREE' : formatBdt(shipping),
            color: shipping == 0 ? AppColors.success : null,
          ),
          const Divider(height: 18),
          row('Total', formatBdt(cart.totalFor(district)), color: AppColors.primary, bold: true),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Dismissible(
      key: ValueKey('cart-${item.productId}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => cart.remove(item.productId),
      background: Container(
        margin: const EdgeInsets.only(top: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 84, height: 84, child: AppImage(item.thumbnail)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.25),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatBdt(item.unitPrice),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _QtyButton(
                        icon: Icons.remove,
                        onTap: () => cart.setQuantity(item.productId, item.quantity - 1),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _QtyButton(
                        icon: Icons.add,
                        onTap: item.quantity < item.stock
                            ? () => cart.setQuantity(item.productId, item.quantity + 1)
                            : null,
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => cart.remove(item.productId),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: onTap == null ? Colors.black12 : Colors.black38),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: onTap == null ? Colors.black26 : null),
      ),
    );
  }
}
