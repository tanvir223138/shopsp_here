import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/entities/product.dart';

/// Sale price (primary color), old price (struck through) and a discount badge.
class PriceTag extends StatelessWidget {
  const PriceTag(this.product, {super.key, this.big = false, this.showBadge = true});
  final Product product;
  final bool big;

  /// Hide the "-20%" pill when the discount is already shown elsewhere.
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final sale = formatBdt(product.bdtSale);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        Text(
          sale,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: big ? 26 : 15,
          ),
        ),
        if (product.hasDiscount) ...[
          Text(
            formatBdt(product.bdtPrice),
            style: TextStyle(
              color: context.mutedText,
              fontSize: big ? 15 : 11.5,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          if (showBadge)
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.sale.withAlpha(28),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-${product.discountPercentage.round()}%',
              style: TextStyle(
                color: AppColors.sale,
                fontWeight: FontWeight.w700,
                fontSize: big ? 13 : 10.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
