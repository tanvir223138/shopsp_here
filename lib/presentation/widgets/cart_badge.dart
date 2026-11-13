import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../screens/cart_screen.dart';

/// Cart icon with item count. Opens the cart as a separate page.
class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartProvider, int>((c) => c.count);
    return IconButton(
      tooltip: 'Cart',
      onPressed: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: Icon(Icons.shopping_cart_outlined, color: color),
      ),
    );
  }
}
