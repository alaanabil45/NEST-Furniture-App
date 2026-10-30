import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/nest_theme.dart';
import '../state/cart_controller.dart';
import '../state/favorites_controller.dart';
import 'pressable.dart';

class _NavItemData {
  const _NavItemData(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class NestNavBar extends StatelessWidget {
  const NestNavBar({super.key, required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  static const List<_NavItemData> _items = [
    _NavItemData(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItemData(Icons.storefront_outlined, Icons.storefront_rounded, 'Shop'),
    _NavItemData(
      Icons.favorite_border_rounded,
      Icons.favorite_rounded,
      'Favorites',
    ),
    _NavItemData(
      Icons.shopping_bag_outlined,
      Icons.shopping_bag_rounded,
      'Cart',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: NestColors.cobalt,
            borderRadius: BorderRadius.circular(32),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([cartController, favoritesController]),
            builder: (context, _) {
              final badges = [
                0,
                0,
                favoritesController.count,
                cartController.itemCount,
              ];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    _NavButton(
                      data: _items[i],
                      selected: i == index,
                      badge: badges[i],
                      onTap: () => onSelected(i),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.data,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.92,
      semanticLabel: [
        data.label,
        if (badge > 0) '$badge items',
        if (selected) 'selected',
      ].join(', '),
      child: AnimatedContainer(
        duration: NestMotion.base,
        curve: NestMotion.enter,
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12),
        decoration: BoxDecoration(
          color: selected ? NestColors.butter : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Pulses whenever the badge number changes.
                TweenAnimationBuilder<double>(
                  key: ValueKey<int>(badge),
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 520),
                  builder: (context, t, child) => Transform.scale(
                    scale: 1 + 0.4 * math.sin(t * math.pi),
                    child: child,
                  ),
                  child: Icon(
                    selected ? data.activeIcon : data.icon,
                    size: 24,
                    color: selected ? NestColors.charcoal : NestColors.cream,
                  ),
                ),
                Positioned(
                  right: -10,
                  top: -10,
                  child: AnimatedScale(
                    scale: badge > 0 ? 1 : 0,
                    duration: NestMotion.base,
                    curve: Curves.easeOutBack,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: NestColors.coral,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: NestText.label.copyWith(
                          fontSize: 10,
                          letterSpacing: 0,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: NestMotion.base,
              curve: NestMotion.enter,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        data.label,
                        maxLines: 1,
                        style: NestText.button.copyWith(fontSize: 13),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
