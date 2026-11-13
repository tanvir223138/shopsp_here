import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/entities/product.dart';
import 'app_image.dart';
import 'product_card.dart';

// ---------------------------------------------------------------- banners

class _Promo {
  const _Promo(this.title, this.subtitle, this.icon, this.colors);
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
}

const _promos = <_Promo>[
  _Promo('Mega Sale', 'Up to 50% off on top brands', Icons.local_fire_department_rounded, [
    Color(0xFF4F46E5),
    Color(0xFF818CF8),
  ]),
  _Promo('Free Delivery', 'On orders over ৳3,000', Icons.local_shipping_rounded, [
    Color(0xFF0D9488),
    Color(0xFF2DD4BF),
  ]),
  _Promo('bKash Cashback', 'Pay with bKash and save more', Icons.account_balance_wallet_rounded, [
    Color(0xFFE2136E),
    Color(0xFFF0508F),
  ]),
];

class PromoBanners extends StatefulWidget {
  const PromoBanners({super.key});

  @override
  State<PromoBanners> createState() => _PromoBannersState();
}

class _PromoBannersState extends State<PromoBanners> {
  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % _promos.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            itemCount: _promos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final p = _promos[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: p.colors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: p.colors.first.withAlpha(70),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -40,
                      child: _Circle(150, Colors.white.withAlpha(30)),
                    ),
                    Positioned(
                      right: 50,
                      bottom: -50,
                      child: _Circle(110, Colors.white.withAlpha(22)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p.subtitle,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Shop now',
                                    style: TextStyle(
                                      color: p.colors.first,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(p.icon, size: 62, color: Colors.white.withAlpha(235)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _promos.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.primary : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle(this.size, this.color);
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

/// Title with a primary-color accent bar, used for every home section.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.icon});
  final String title;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        if (icon != null) ...[Icon(icon, size: 20, color: AppColors.primary), const SizedBox(width: 4)],
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Three trust badges under the banner (delivery, COD, returns).
class ServiceStrip extends StatelessWidget {
  const ServiceStrip({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String title, String sub) => Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: context.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: cardDecoration(context),
      child: Row(
        children: [
          item(Icons.local_shipping_outlined, 'Fast delivery', '2-4 days'),
          item(Icons.payments_outlined, 'Cash on delivery', 'Pay at door'),
          item(Icons.verified_outlined, 'Easy return', '7 days'),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- categories

IconData categoryIcon(String c) {
  final s = c.toLowerCase();
  if (s.contains('smartphone') || s.contains('mobile-acc')) return Icons.smartphone;
  if (s.contains('laptop')) return Icons.laptop;
  if (s.contains('tablet')) return Icons.tablet_mac;
  if (s.contains('beauty') || s.contains('skin') || s.contains('fragrance')) return Icons.spa;
  if (s.contains('furniture') || s.contains('home')) return Icons.chair;
  if (s.contains('kitchen')) return Icons.kitchen;
  if (s.contains('grocer')) return Icons.local_grocery_store;
  if (s.contains('shoe')) return Icons.directions_walk;
  if (s.contains('watch')) return Icons.watch;
  if (s.contains('bag')) return Icons.shopping_bag;
  if (s.contains('sunglass')) return Icons.wb_sunny;
  if (s.contains('motor')) return Icons.two_wheeler;
  if (s.contains('vehicle') || s.contains('automotive')) return Icons.directions_car;
  if (s.contains('sport')) return Icons.sports_soccer;
  if (s.contains('light')) return Icons.lightbulb;
  if (s.contains('jewel')) return Icons.diamond;
  if (s.contains('top') ||
      s.contains('dress') ||
      s.contains('shirt') ||
      s.contains('women') ||
      s.contains('men')) {
    return Icons.checkroom;
  }
  return Icons.category;
}

class CategoryStrip extends StatelessWidget {
  const CategoryStrip({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, IconData icon, bool active, VoidCallback onTap) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 74,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: active ? AppColors.primary : AppColors.primary.withAlpha(28),
                child: Icon(icon, color: active ? Colors.white : AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.only(top: 12),
      decoration: cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SectionHeader(
              'Categories',
              trailing: selected == null
                  ? null
                  : TextButton(onPressed: () => onSelect(null), child: const Text('Clear')),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                item('All', Icons.apps_rounded, selected == null, () => onSelect(null)),
                for (final c in categories)
                  item(
                    prettyCategory(c),
                    categoryIcon(c),
                    selected == c,
                    () => onSelect(selected == c ? null : c),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- flash sale

class FlashSale extends StatefulWidget {
  const FlashSale({super.key, required this.products});
  final List<Product> products;

  @override
  State<FlashSale> createState() => _FlashSaleState();
}

class _FlashSaleState extends State<FlashSale> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _box(String v) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    margin: const EdgeInsets.only(left: 3),
    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
    child: Text(
      v,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final left = DateTime(now.year, now.month, now.day + 1).difference(now);
    String two(int n) => n.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.primary),
              const Text(
                'Flash Sale',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text('Ends in', style: TextStyle(fontSize: 12, color: context.mutedText)),
              _box(two(left.inHours)),
              _box(two(left.inMinutes % 60)),
              _box(two(left.inSeconds % 60)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final p = widget.products[i];
                return InkWell(
                  onTap: () => openDetail(context, p),
                  child: SizedBox(
                    width: 108,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                AppImage(p.thumbnail),
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    color: AppColors.primary,
                                    child: Text(
                                      '-${p.discountPercentage.round()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatBdt(p.bdtSale),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
