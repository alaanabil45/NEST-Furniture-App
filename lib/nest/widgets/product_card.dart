import 'package:flutter/material.dart';

import '../core/nest_theme.dart';
import '../data/product.dart';
import '../screens/product_detail_screen.dart';
import 'category_style.dart';
import 'favorite_button.dart';
import 'nest_image.dart';
import 'pressable.dart';

enum CardShape { leaf, arch, soft }

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.shape = CardShape.soft,
    this.imageAspect,
    this.heroScope = 'home',
  });

  final Product product;
  final CardShape shape;

  /// width / height of the image. If null, the image fills the height
  /// it is given (used inside the Shop grid).
  final double? imageAspect;

  /// Each place a card appears needs its own scope, because every tab
  /// stays alive and two Heroes may never share a tag.
  final String heroScope;

  String get _heroTag => '$heroScope-${product.id}';

  BorderRadius get _radius => switch (shape) {
    CardShape.leaf => const BorderRadius.only(
      topLeft: Radius.circular(44),
      bottomRight: Radius.circular(44),
      topRight: Radius.circular(10),
      bottomLeft: Radius.circular(10),
    ),
    CardShape.arch => const BorderRadius.only(
      topLeft: Radius.circular(999),
      topRight: Radius.circular(999),
      bottomLeft: Radius.circular(14),
      bottomRight: Radius.circular(14),
    ),
    CardShape.soft => const BorderRadius.all(Radius.circular(22)),
  };

  @override
  Widget build(BuildContext context) {
    final image = Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: _heroTag,
          child: ClipRRect(
            borderRadius: _radius,
            child: NestImage(
              asset: product.imageAsset,
              tone: product.tone,
              icon: product.category.icon,
            ),
          ),
        ),
        if (product.isNew)
          const Positioned(left: 10, bottom: 10, child: _NewTag()),
        Positioned(
          right: 4,
          top: shape == CardShape.arch ? 44 : 4,
          child: FavoriteButton(productId: product.id, name: product.name),
        ),
      ],
    );

    return Pressable(
      scale: 0.97,
      onTap: () => ProductDetailScreen.open(context, product, _heroTag),
      child: Column(
        mainAxisSize: imageAspect == null ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageAspect == null)
            Expanded(child: image)
          else
            AspectRatio(aspectRatio: imageAspect!, child: image),
          const SizedBox(height: 10),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: NestText.display(21),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.category.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NestText.label.copyWith(
                    fontSize: 10,
                    color: NestColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(product.priceLabel, style: NestText.bodyStrong),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewTag extends StatelessWidget {
  const _NewTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: NestColors.butter,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'NEW',
        style: NestText.label.copyWith(fontSize: 10, letterSpacing: 1.2),
      ),
    );
  }
}
