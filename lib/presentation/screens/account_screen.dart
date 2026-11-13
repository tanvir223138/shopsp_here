import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import 'auth/login_screen.dart';
import 'favorites_screen.dart';
import 'main_shell.dart';
import 'product_form_screen.dart';
import 'profile_edit_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to place orders.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    await context.read<AuthProvider>().logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final settings = context.watch<SettingsProvider>();
    final orders = context.watch<OrderProvider>().orders.length;
    final cart = context.watch<CartProvider>().count;
    final wishlist = context.select<ProductProvider, int>((p) => p.favorites.length);

    Widget stat(String label, int value, VoidCallback onTap) => Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12, color: context.mutedText)),
            ],
          ),
        ),
      ),
    );

    Widget tile(
      IconData icon,
      String title,
      VoidCallback onTap, {
      Widget? trailing,
      Color? color,
    }) => ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(title, style: TextStyle(color: color)),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 24, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Text(
                    (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Guest',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '', style: const TextStyle(color: Colors.white70)),
                      Text(user?.phone ?? '', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        stat('Orders', orders, () => shellTab.value = 2),
                        stat(
                          'Wishlist',
                          wishlist,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                          ),
                        ),
                        stat('In cart', cart, () => shellTab.value = 1),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        tile(Icons.receipt_long_outlined, 'My orders', () => shellTab.value = 2),
                        tile(
                          Icons.favorite_border,
                          'My wishlist',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                          ),
                        ),
                        tile(
                          Icons.edit_outlined,
                          'Edit profile & address',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                          ),
                        ),
                        tile(
                          Icons.add_business_outlined,
                          'Sell a product',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                          title: const Text('Dark mode'),
                          value: settings.isDark,
                          activeColor: AppColors.primary,
                          onChanged: (_) => settings.toggleTheme(),
                        ),
                        tile(Icons.info_outline, 'About ShopSphere', () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'ShopSphere',
                            applicationVersion: '2.0.0',
                            applicationIcon: const Icon(
                              Icons.shopping_bag_rounded,
                              color: AppColors.primary,
                              size: 40,
                            ),
                            children: const [
                              Text(
                                'A demo shopping app built with Flutter.\n'
                                'Products from the DummyJSON API. Payments are simulated; no real money is used.',
                              ),
                            ],
                          );
                        }),
                        tile(
                          Icons.logout,
                          'Log out',
                          () => _logout(context),
                          color: Colors.red,
                          trailing: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
