import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/entities/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/cart_badge.dart';
import '../widgets/price_tag.dart';
import '../widgets/product_card.dart' show FavoriteButton, heroTagFor, prettyCategory;
import 'cart_screen.dart';
import 'product_form_screen.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.productId});
  final int productId;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Product? _last; // keeps the content visible while the page animates out after delete
  int _qty = 1;

  Future<void> _confirmDelete(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${product.title}" will be removed from your list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final provider = context.read<ProductProvider>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    provider.deleteProduct(product);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${product.title}" deleted'),
          action: SnackBarAction(label: 'Undo', onPressed: () => provider.restoreProduct(product)),
        ),
      );
  }

  /// Returns true when the item was added.
  Future<bool> _addToCart(Product product) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<CartProvider>().add(product, quantity: _qty);
    messenger.hideCurrentSnackBar();
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return false;
    }
    return true;
  }

  Future<void> _onAddToCart(Product product) async {
    final messenger = ScaffoldMessenger.of(context);
    if (await _addToCart(product)) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Added to cart'),
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ),
      );
    }
  }

  Future<void> _onBuyNow(Product product) async {
    if (await _addToCart(product) && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
    }
  }

  Widget _card(BuildContext context, {required Widget child, EdgeInsets? margin}) => Container(
    width: double.infinity,
    margin: margin ?? const EdgeInsets.fromLTRB(8, 8, 8, 0),
    padding: const EdgeInsets.all(14),
    decoration: cardDecoration(context),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final current = provider.findById(widget.productId);
    if (current != null) _last = current;
    final product = current ?? _last;
    if (product == null) return const Scaffold();

    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final images = product.images.isNotEmpty
        ? product.images
        : (product.thumbnail.isNotEmpty ? [product.thumbnail] : <String>[]);
    final inStock = product.stock > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          const CartIconButton(),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
                );
              } else {
                _confirmDelete(product);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit product')),
              PopupMenuItem(value: 'delete', child: Text('Delete product')),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: context.cardBg,
        elevation: 8,
        child: SafeArea(
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    FavoriteButton(product.id, size: 26),
                    const SizedBox(width: 4),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: inStock ? () => _onAddToCart(product) : null,
                        child: const Text('Add to Cart'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: inStock ? () => _onBuyNow(product) : null,
                        child: const Text('Buy Now'),
                      ),
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
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              Container(
                color: context.cardBg,
                child: _Gallery(
                  images: images,
                  heroTag: heroTagFor(product.id),
                  discount: product.hasDiscount ? product.discountPercentage.round() : 0,
                ),
              ),
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand.isNotEmpty) ...[
                      Text(
                        product.brand.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    PriceTag(product, big: true),
                    const SizedBox(height: 8),
                    Text(
                      product.title,
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (product.rating > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 20, color: AppColors.star),
                              Text(
                                ' ${product.rating.toStringAsFixed(1)} / 5',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: inStock ? AppColors.success : scheme.error,
                          ),
                          label: Text(inStock ? '${product.stock} in stock' : 'Out of stock'),
                        ),
                        if (product.isLocal)
                          const Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text('Added by you'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _card(
                context,
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    IconButton.outlined(
                      onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '$_qty',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton.outlined(
                      onPressed: _qty < product.stock ? () => setState(() => _qty++) : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              _card(
                context,
                child: Column(
                  children: [
                    _ServiceRow(
                      icon: Icons.local_shipping_outlined,
                      title: 'Standard delivery · 2-4 days',
                      subtitle:
                          '${formatBdt(ShopConstants.shippingInsideDhaka)} inside Dhaka, ${formatBdt(ShopConstants.shippingOutsideDhaka)} outside. Free over ${formatBdt(ShopConstants.freeShippingFrom)}',
                    ),
                    const Divider(height: 20),
                    const _ServiceRow(
                      icon: Icons.payments_outlined,
                      title: 'Cash on delivery available',
                      subtitle: 'Or pay with bKash, Nagad, Rocket, card or bank',
                    ),
                    const Divider(height: 20),
                    const _ServiceRow(
                      icon: Icons.assignment_return_outlined,
                      title: '7 days easy return',
                      subtitle: 'Change of mind is not applicable',
                    ),
                  ],
                ),
              ),
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product details', style: text.titleMedium),
                    const SizedBox(height: 6),
                    Text(product.description.isEmpty ? 'No description.' : product.description),
                  ],
                ),
              ),
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Specifications', style: text.titleMedium),
                    const SizedBox(height: 6),
                    _InfoRow('Product ID', product.isLocal ? 'Local' : '${product.id}'),
                    _InfoRow('Brand', product.brand.isEmpty ? 'No brand' : product.brand),
                    _InfoRow('Category', prettyCategory(product.category)),
                    _InfoRow('Discount', '${product.discountPercentage.toStringAsFixed(1)}%'),
                    _InfoRow('Stock', '${product.stock}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12.5, color: context.mutedText)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.mutedText)),
          Flexible(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.images, required this.heroTag, this.discount = 0});
  final List<String> images;
  final String heroTag;
  final int discount;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isEmpty ? [''] : widget.images;
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final img = AppImage(images[i], fit: BoxFit.contain);
                  // Only the first image flies in from the list (Hero animation).
                  return i == 0 ? Hero(tag: widget.heroTag, child: img) : img;
                },
              ),
              if (widget.discount > 0)
                Positioned(
                  left: 0,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                    child: Text(
                      '-${widget.discount}% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              if (images.length > 1)
                Positioned(
                  right: 12,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_page + 1}/${images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (images.length > 1)
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = i == _page;
                return GestureDetector(
                  onTap: () => _controller.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 52,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? AppColors.primary : context.borderColor,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: AppImage(images[i]),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
