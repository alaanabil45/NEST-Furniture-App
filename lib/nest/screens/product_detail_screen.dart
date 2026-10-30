import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nest_theme.dart';
import '../data/product.dart';
import '../state/cart_controller.dart';
import '../widgets/category_style.dart';
import '../widgets/favorite_button.dart';
import '../widgets/nest_button.dart';
import '../widgets/nest_image.dart';
import '../widgets/pressable.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/room_sheets.dart';
import '../widgets/staggered_in.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.heroTag,
  });

  final Product product;
  final String heroTag;

  /// Opens the page with a soft fade; the photo flies in via Hero.
  static Future<void> open(
    BuildContext context,
    Product product,
    String heroTag,
  ) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProductDetailScreen(product: product, heroTag: heroTag),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final imageHeight = (MediaQuery.sizeOf(context).height * 0.46)
        .clamp(300.0, 460.0)
        .toDouble();

    return Scaffold(
      backgroundColor: NestColors.cream,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: topInset + 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Pressable(
                          onTap: () => Navigator.of(context).pop(),
                          semanticLabel: 'Back',
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: NestColors.charcoal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 22,
                              color: NestColors.cream,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          product.category.label.toUpperCase(),
                          style: NestText.label.copyWith(
                            color: NestColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Stack(
                      children: [
                        Hero(
                          tag: heroTag,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(110),
                              topRight: Radius.circular(24),
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(110),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: imageHeight,
                              child: NestImage(
                                asset: product.imageAsset,
                                tone: product.tone,
                                icon: product.category.icon,
                                cacheWidth: 1000,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: FavoriteButton(
                            productId: product.id,
                            name: product.name,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StaggeredIn(
                          index: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: NestText.display(46)),
                              const SizedBox(height: 8),
                              Text(
                                product.priceLabel,
                                style: NestText.display(34)
                                    .copyWith(color: NestColors.cobalt),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        StaggeredIn(
                          index: 2,
                          child: Text(
                            product.description,
                            style: NestText.body.copyWith(
                              fontSize: 16,
                              height: 1.6,
                              color: NestColors.charcoal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        StaggeredIn(
                          index: 3,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoPill(label: product.category.label),
                              if (product.isNew)
                                const _InfoPill(
                                  label: 'New arrival',
                                  color: NestColors.butter,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        StaggeredIn(
                          index: 4,
                          child: Pressable(
                            semanticLabel: 'Plan it in a room',
                            onTap: () => showRoomPickerSheet(
                              context,
                              product,
                              toastBottom: 96,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: NestColors.creamDeep,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: NestColors.coral,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_home_outlined,
                                      size: 22,
                                      color: NestColors.charcoal,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Plan it in a room',
                                          style: NestText.bodyStrong.copyWith(
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Check it against a budget',
                                          style: NestText.body,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                    color: NestColors.charcoal,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _PurchaseBar(product: product),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, this.color = NestColors.creamDeep});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(label, style: NestText.button.copyWith(fontSize: 13)),
    );
  }
}

class _PurchaseBar extends StatelessWidget {
  const _PurchaseBar({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cartController,
      builder: (context, _) {
        final quantity = cartController.quantityOf(product.id);

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: NestColors.cream,
            border: Border(top: BorderSide(color: NestColors.line)),
          ),
          child: SafeArea(
            top: false,
            child: AnimatedSwitcher(
              duration: NestMotion.base,
              switchInCurve: NestMotion.enter,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: quantity == 0
                  ? Row(
                      key: const ValueKey<String>('add'),
                      children: [
                        Expanded(
                          child: NestButton(
                            label: 'Add to cart · ${product.priceLabel}',
                            background: NestColors.cobalt,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              cartController.add(product.id);
                            },
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey<String>('stepper'),
                      children: [
                        QuantityStepper(
                          quantity: quantity,
                          canIncrement: quantity < CartController.maxQuantity,
                          onDecrement: () {
                            HapticFeedback.selectionClick();
                            cartController.setQuantity(
                              product.id,
                              quantity - 1,
                            );
                          },
                          onIncrement: () {
                            HapticFeedback.selectionClick();
                            cartController.add(product.id);
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NestButton(
                            label: 'Keep shopping',
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
