import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';

/// Lets any screen switch the bottom tab (0 Home, 1 Cart, 2 Orders, 3 Account).
final ValueNotifier<int> shellTab = ValueNotifier<int>(0);

/// Bottom navigation on phones, side navigation rail on tablets.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _pages = <Widget>[HomeScreen(), CartScreen(), OrdersScreen(), AccountScreen()];

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartProvider, int>((c) => c.count);

    Widget cartIcon(IconData icon) =>
        Badge(isLabelVisible: count > 0, label: Text('$count'), child: Icon(icon));

    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, index, _) {
        final body = IndexedStack(index: index, children: _pages);
        final wide = MediaQuery.of(context).size.width >= 800;

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (i) => shellTab.value = i,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: cartIcon(Icons.shopping_cart_outlined),
                      selectedIcon: cartIcon(Icons.shopping_cart),
                      label: const Text('Cart'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: Text('Orders'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Account'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => shellTab.value = i,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: cartIcon(Icons.shopping_cart_outlined),
                selectedIcon: cartIcon(Icons.shopping_cart),
                label: 'Cart',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Account',
              ),
            ],
          ),
        );
      },
    );
  }
}
