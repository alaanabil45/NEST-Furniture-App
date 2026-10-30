import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nest_theme.dart';
import '../data/product.dart';
import '../state/cart_controller.dart';
import '../widgets/category_style.dart';
import '../widgets/empty_state.dart';
import '../widgets/nest_button.dart';
import '../widgets/nest_image.dart';
import '../widgets/pressable.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/screen_title.dart';
import 'checkout_screen.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: cartController,
        builder: (context, _) {
          final lines = cartController.lines;
          final count = cartController.itemCount;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: ScreenTitle(
                  lead: 'Your',
                  emphasis: 'cart',
                  subtitle: '$count ${count == 1 ? 'piece' : 'pieces'}',
                ),
              ),
              Expanded(
                child: lines.isEmpty
                    ? EmptyState(
                        icon: Icons.shopping_bag_outlined,
                        accent: NestColors.butter,
                        accent2: NestColors.softGreen,
                        lead: 'Your cart is',
                        emphasis: 'empty.',
                        message: 'Good furniture takes a little looking. Start browsing.',
                        actionLabel: 'Browse the shop',
                        onAction: onBrowse,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                        itemCount: lines.length,
                        itemBuilder: (context, i) => _CartLineTile(
                          key: ValueKey<String>(lines[i].product.id),
                          line: lines[i],
                        ),
                      ),
              ),
              if (lines.isNotEmpty)
                _TotalBar(
                  count: count,
                  onCheckout: () =>
                      CheckoutScreen.open(context, onFinished: onBrowse),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.count, required this.onCheckout});

  final int count;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: const BoxDecoration(
        color: NestColors.cobalt,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(56),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL',
                    style: NestText.label.copyWith(color: NestColors.butter),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count ${count == 1 ? 'piece' : 'pieces'}',
                    style: NestText.body.copyWith(color: NestColors.cream),
                  ),
                ],
              ),
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: cartController.subtotal.toDouble()),
                duration: NestMotion.base,
                curve: NestMotion.enter,
                builder: (context, value, _) => Text(
                  formatPrice(value.round()),
                  style: NestText.display(40).copyWith(color: NestColors.cream),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FreeShippingHint(subtotal: cartController.subtotal),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NestButton(
                  label: 'Checkout',
                  background: NestColors.butter,
                  foreground: NestColors.charcoal,
                  icon: Icons.arrow_forward_rounded,
                  onTap: onCheckout,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FreeShippingHint extends StatelessWidget {
  const _FreeShippingHint({required this.subtotal});

  final int subtotal;

  @override
  Widget build(BuildContext context) {
    final unlocked = subtotal >= kFreeShippingFrom;
    final progress = (subtotal / kFreeShippingFrom).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          unlocked
              ? 'Free delivery unlocked'
              : 'Add ${formatPrice(kFreeShippingFrom - subtotal)} more for free delivery',
          style: NestText.body.copyWith(fontSize: 13, color: NestColors.cream),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: 8,
                color: NestColors.cream.withValues(alpha: 0.25),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    height: 8,
                    color: unlocked ? NestColors.butter : NestColors.cream,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartLineTile extends StatefulWidget {
  const _CartLineTile({super.key, required this.line});

  final CartLine line;

  @override
  State<_CartLineTile> createState() => _CartLineTileState();
}

class _CartLineTileState extends State<_CartLineTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: NestMotion.base,
    value: 1,
  );
  late final Animation<double> _size = CurvedAnimation(
    parent: _exit,
    curve: Curves.easeInOut,
  );
  bool _removing = false;

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  Future<void> _remove() async {
    if (_removing) return;
    _removing = true;
    HapticFeedback.mediumImpact();
    await _exit.reverse();
    cartController.remove(widget.line.product.id);
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final product = line.product;
    final heroTag = 'cart-${product.id}';

    return SizeTransition(
      sizeFactor: _size,
      alignment: Alignment.topLeft,
      child: FadeTransition(
        opacity: _exit,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Pressable(
                scale: 0.97,
                onTap: () =>
                    ProductDetailScreen.open(context, product, heroTag),
                child: Hero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                    child: SizedBox(
                      width: 92,
                      height: 112,
                      child: NestImage(
                        asset: product.imageAsset,
                        tone: product.tone,
                        icon: product.category.icon,
                        cacheWidth: 300,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NestText.display(23),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.category.label.toUpperCase()} · ${product.priceLabel}',
                      style: NestText.label.copyWith(
                        fontSize: 10,
                        color: NestColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        QuantityStepper(
                          quantity: line.quantity,
                          canIncrement:
                              line.quantity < CartController.maxQuantity,
                          onDecrement: () {
                            if (line.quantity <= 1) {
                              _remove();
                            } else {
                              HapticFeedback.selectionClick();
                              cartController.setQuantity(
                                product.id,
                                line.quantity - 1,
                              );
                            }
                          },
                          onIncrement: () {
                            HapticFeedback.selectionClick();
                            cartController.add(product.id);
                          },
                        ),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                formatPrice(line.total),
                                style: NestText.bodyStrong.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
