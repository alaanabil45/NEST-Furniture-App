import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/product.dart';
import 'product_card.dart';
import 'staggered_in.dart';

/// Responsive product grid. Column count adapts to the available width.
/// Changing [epoch] replays the staggered entrance (used on filter changes).
class ProductSliverGrid extends StatelessWidget {
  const ProductSliverGrid({
    super.key,
    required this.products,
    this.epoch = 0,
    this.heroScope = 'shop',
  });

  final List<Product> products;
  final int epoch;
  final String heroScope;

  @override
  Widget build(BuildContext context) {
    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14)
        .clamp(1.0, 1.5)
        .toDouble();

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        final width = constraints.crossAxisExtent;
        final columns = math.max(2, (width / 190).floor());
        final cardWidth = (width - gap * (columns - 1)) / columns;

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: gap,
            mainAxisSpacing: 22,
            mainAxisExtent: cardWidth * 1.22 + 92 * textScale,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final product = products[i];
              return StaggeredIn(
                key: ValueKey<String>('$epoch-${product.id}'),
                index: i,
                child: ProductCard(
                  product: product,
                  shape: CardShape.values[i % CardShape.values.length],
                  heroScope: heroScope,
                ),
              );
            },
            childCount: products.length,
            findChildIndexCallback: (Key key) {
              if (key is ValueKey<String>) {
                final index = products.indexWhere(
                  (p) => '$epoch-${p.id}' == key.value,
                );
                return index < 0 ? null : index;
              }
              return null;
            },
          ),
        );
      },
    );
  }
}
