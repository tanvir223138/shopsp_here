import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/state_views.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProductProvider>();
    final items = p.all.where((e) => p.favorites.contains(e.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: items.isEmpty
          ? const EmptyView(icon: Icons.favorite_border, message: 'Your wishlist is empty.')
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.66,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => ProductGridCard(product: items[i]),
            ),
    );
  }
}
