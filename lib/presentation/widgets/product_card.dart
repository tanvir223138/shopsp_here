import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../domain/entities/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../screens/detail_screen.dart';
import 'app_image.dart';
import 'price_tag.dart';

String heroTagFor(int productId) => 'product-image-$productId';

void openDetail(BuildContext context, Product product) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(productId: product.id)));
}

String prettyCategory(String c) {
  final s = c.replaceAll('-', ' ').trim();
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

String _subtitle(Product p) =>
    [if (p.brand.isNotEmpty) p.brand, prettyCategory(p.category)].join(' • ');

class FavoriteButton extends StatelessWidget {
  const FavoriteButton(this.productId, {super.key, this.size = 22});
  final int productId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isFav = context.select<ProductProvider, bool>((p) => p.favorites.contains(productId));
    return IconButton(
      visualDensity: VisualDensity.compact,
      iconSize: size,
      tooltip: isFav ? 'Remove from wishlist' : 'Add to wishlist',
      onPressed: () => context.read<ProductProvider>().toggleFavorite(productId),
      icon: Icon(
        isFav ? Icons.favorite : Icons.favorite_border,
        color: isFav ? Colors.redAccent : null,
      ),
    );
  }
}

class _Rating extends StatelessWidget {
  const _Rating(this.product);
  final Product product;

  @override
  Widget build(BuildContext context) {
    if (product.rating <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 15, color: AppColors.star),
        const SizedBox(width: 2),
        Text(
          product.rating.toStringAsFixed(1),
          style: TextStyle(fontSize: 11.5, color: context.mutedText),
        ),
      ],
    );
  }
}

/// Adds one unit to the cart and shows a snackbar with the result.
Future<void> quickAddToCart(BuildContext context, Product product) async {
  final messenger = ScaffoldMessenger.of(context);
  final err = await context.read<CartProvider>().add(product);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(err ?? 'Added to cart')));
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge(this.percent);
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: const BoxDecoration(
        color: AppColors.sale,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(10)),
      ),
      child: Text(
        '-$percent%',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton(this.product);
  final Product product;

  @override
  Widget build(BuildContext context) {
    final enabled = product.stock > 0;
    return Material(
      color: enabled ? AppColors.primary : Colors.grey,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? () => quickAddToCart(context, product) : null,
        child: const Padding(
          padding: EdgeInsets.all(7),
          child: Icon(Icons.add_shopping_cart_rounded, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

/// Vertical card (marketplace grid).
class ProductGridCard extends StatelessWidget {
  const ProductGridCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final lowStock = product.stock > 0 && product.stock <= 10;
    return Material(
      color: context.cardBg,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.borderColor),
      ),
      child: InkWell(
        onTap: () => openDetail(context, product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(tag: heroTagFor(product.id), child: AppImage(product.thumbnail)),
                  if (product.hasDiscount)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: _DiscountBadge(product.discountPercentage.round()),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: context.cardBg.withAlpha(225),
                      child: FavoriteButton(product.id, size: 18),
                    ),
                  ),
                  if (product.stock <= 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: const Text(
                          'Out of stock',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.25, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: PriceTag(product, showBadge: false)),
                      const SizedBox(width: 6),
                      _QuickAddButton(product),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _Rating(product),
                      if (lowStock) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Only ${product.stock} left',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.sale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

/// Horizontal card (list mode). Supports swipe-to-delete from the home screen.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: context.cardBg,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.borderColor),
      ),
      child: InkWell(
        onTap: () => openDetail(context, product),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(tag: heroTagFor(product.id), child: AppImage(product.thumbnail)),
                  if (product.hasDiscount)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: _DiscountBadge(product.discountPercentage.round()),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _subtitle(product),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Text(
                        product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ),
                    PriceTag(product, showBadge: false),
                    Row(
                      children: [
                        _Rating(product),
                        const Spacer(),
                        FavoriteButton(product.id, size: 20),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          iconSize: 20,
                          tooltip: 'Add to cart',
                          icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
                          onPressed: product.stock > 0
                              ? () => quickAddToCart(context, product)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
