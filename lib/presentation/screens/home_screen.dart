import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../domain/entities/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/cart_badge.dart';
import '../widgets/home_sections.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer.dart';
import '../widgets/state_views.dart';
import 'product_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
        context.read<ProductProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) context.read<ProductProvider>().setQuery(value);
    });
    setState(() {}); // refresh the clear (x) button
  }

  // Grid: as many columns as fit (2 on phones, 4+ on tablets). List: 1-2 columns.
  SliverGridDelegate _delegate(bool isGrid) => isGrid
      ? const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          childAspectRatio: 0.66,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        )
      : const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 560,
          mainAxisExtent: 140,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        );

  void _deleteWithUndo(Product item) {
    final provider = context.read<ProductProvider>();
    provider.deleteProduct(item);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${item.title}" deleted'),
          action: SnackBarAction(label: 'Undo', onPressed: () => provider.restoreProduct(item)),
        ),
      );
  }

  Widget _swipeable(Product item) {
    return Dismissible(
      key: ValueKey('dismiss-${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteWithUndo(item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: ProductCard(product: item),
    );
  }

  Widget _searchField(ProductProvider p) {
    OutlineInputBorder none() => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearch,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search products, brands and categories',
          hintStyle: const TextStyle(color: Colors.black45, fontSize: 13.5),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: none(),
          enabledBorder: none(),
          focusedBorder: none(),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: Colors.black38, size: 20),
                  onPressed: () {
                    _debounce?.cancel();
                    _searchCtrl.clear();
                    p.setQuery('');
                    setState(() {});
                  },
                ),
        ),
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required bool active,
    Color? activeColor,
  }) {
    final color = active ? (activeColor ?? AppColors.primary) : context.mutedText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? color.withAlpha(24) : context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? color : context.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  String _sortLabel(SortOption s) {
    switch (s) {
      case SortOption.priceLow:
        return 'Price: low to high';
      case SortOption.priceHigh:
        return 'Price: high to low';
      case SortOption.rating:
        return 'Top rated';
      case SortOption.title:
        return 'Name (A-Z)';
      case SortOption.none:
        return 'Sort';
    }
  }

  Widget _toolbar(ProductProvider p, SettingsProvider settings, bool filtering) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 0, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SectionHeader(
              filtering ? '${p.visible.length} results' : 'Just For You',
              trailing: Text(
                '${p.all.length} items',
                style: TextStyle(fontSize: 12, color: context.mutedText),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                PopupMenuButton<SortOption>(
                  tooltip: 'Sort',
                  initialValue: p.sort,
                  onSelected: p.setSort,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    for (final o in SortOption.values)
                      PopupMenuItem(
                        value: o,
                        child: Text(o == SortOption.none ? 'Default' : _sortLabel(o)),
                      ),
                  ],
                  child: _actionChip(
                    icon: Icons.swap_vert_rounded,
                    label: _sortLabel(p.sort),
                    active: p.sort != SortOption.none,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: p.toggleFavoritesOnly,
                  child: _actionChip(
                    icon: p.favoritesOnly ? Icons.favorite : Icons.favorite_border,
                    label: 'Wishlist',
                    active: p.favoritesOnly,
                    activeColor: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: settings.toggleView,
                  child: _actionChip(
                    icon: settings.isGridView
                        ? Icons.view_agenda_outlined
                        : Icons.grid_view_rounded,
                    label: settings.isGridView ? 'List view' : 'Grid view',
                    active: false,
                  ),
                ),
                if (p.category != null) ...[
                  const SizedBox(width: 8),
                  InputChip(
                    label: Text(prettyCategory(p.category!)),
                    onDeleted: () => p.setCategory(null),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _offlineBanner(ProductProvider p) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "You're offline. Showing saved products.",
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: p.refresh,
            style: TextButton.styleFrom(foregroundColor: scheme.onErrorContainer),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProductProvider>();
    final settings = context.watch<SettingsProvider>();
    final isGrid = settings.isGridView;
    final filtering = p.query.trim().isNotEmpty || p.category != null || p.favoritesOnly;

    final flash =
        (p.all.where((e) => e.hasDiscount).toList()
              ..sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage)))
            .take(10)
            .toList();

    if (p.errorMessage != null && p.all.isEmpty && !p.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('ShopSphere')),
        body: ErrorView(message: p.errorMessage!, onRetry: p.retryInitial),
      );
    }

    final items = p.visible;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-product-fab',
        tooltip: 'Add product',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Sell'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final ok = await p.refresh();
          if (!ok && mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(p.lastError)));
          }
        },
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 68,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              titleSpacing: 12,
              flexibleSpace: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
              ),
              title: _searchField(p),
              actions: const [
                CartIconButton(color: Colors.white),
                SizedBox(width: 4),
              ],
            ),
            if (p.offline) SliverToBoxAdapter(child: _offlineBanner(p)),
            if (!filtering)
              const SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.only(top: 8), child: PromoBanners()),
              ),
            if (!filtering) const SliverToBoxAdapter(child: ServiceStrip()),
            if (p.categories.isNotEmpty)
              SliverToBoxAdapter(
                child: CategoryStrip(
                  categories: p.categories,
                  selected: p.category,
                  onSelect: p.setCategory,
                ),
              ),
            if (!filtering && flash.isNotEmpty)
              SliverToBoxAdapter(child: FlashSale(products: flash)),
            SliverToBoxAdapter(child: _toolbar(p, settings, filtering)),
            if (p.isLoading)
              SliverToBoxAdapter(
                child: Shimmer(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    gridDelegate: _delegate(isGrid),
                    itemCount: 8,
                    itemBuilder: (_, __) =>
                        isGrid ? const SkeletonGridCard() : const SkeletonListCard(),
                  ),
                ),
              )
            else if (items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyView(
                    message: p.favoritesOnly ? 'Your wishlist is empty.' : 'No products found.',
                    action: p.hasMore
                        ? OutlinedButton(
                            onPressed: p.loadMore,
                            child: const Text('Load more products'),
                          )
                        : null,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                sliver: SliverGrid(
                  gridDelegate: _delegate(isGrid),
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final item = items[i];
                    return isGrid ? ProductGridCard(product: item) : _swipeable(item);
                  }, childCount: items.length),
                ),
              ),
            if (!p.isLoading && items.isNotEmpty) SliverToBoxAdapter(child: _footer(p)),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
    );
  }

  Widget _footer(ProductProvider p) {
    if (p.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (p.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(p.lastError, textAlign: TextAlign.center),
            TextButton(onPressed: p.loadMore, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (p.hasMore) {
      return Center(
        child: TextButton.icon(
          onPressed: p.loadMore,
          icon: const Icon(Icons.expand_more),
          label: const Text('Load more'),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: Text("You've reached the end")),
    );
  }
}
