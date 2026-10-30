import 'package:flutter/material.dart';

import '../core/nest_theme.dart';
import '../data/catalog.dart';
import '../data/product.dart';
import '../state/cart_controller.dart';
import '../state/favorites_controller.dart';
import '../widgets/category_style.dart';
import '../widgets/header_icon_button.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/nest_button.dart';
import '../widgets/nest_image.dart';
import '../widgets/pressable.dart';
import '../widgets/product_card.dart';
import '../widgets/staggered_in.dart';
import 'room_board_screen.dart';
import 'style_quiz_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onSearch,
    required this.onCategory,
    required this.onSeeAll,
    required this.onFavorites,
    required this.onCart,
  });

  final VoidCallback onSearch;
  final ValueChanged<ProductCategory> onCategory;
  final VoidCallback onSeeAll;
  final VoidCallback onFavorites;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        cacheExtent: 60,
        slivers: [
          SliverList.list(
            children: [
              _Header(
                onSearch: onSearch,
                onFavorites: onFavorites,
                onCart: onCart,
              ),
              const SizedBox(height: 16),
              _Hero(onShop: onSeeAll),
              const SizedBox(height: 40),
              StaggeredIn(child: _Categories(onCategory: onCategory)),
              const SizedBox(height: 44),
              _Curated(onSeeAll: onSeeAll),
              const SizedBox(height: 44),
              StaggeredIn(
                child: StyleQuizPromo(
                  onOpen: () => StyleQuizScreen.open(context),
                ),
              ),
              const SizedBox(height: 44),
              StaggeredIn(
                child: _RoomBoardPromo(
                  onOpen: () => RoomBoardScreen.open(context),
                ),
              ),
              const SizedBox(height: 44),
              StaggeredIn(
                child: _SeatingEdit(
                  onShop: () => onCategory(ProductCategory.seating),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- header

class _Header extends StatelessWidget {
  const _Header({
    required this.onSearch,
    required this.onFavorites,
    required this.onCart,
  });

  final VoidCallback onSearch;
  final VoidCallback onFavorites;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              const Entrance(
                child: Text.rich(
                  TextSpan(
                    text: 'nest',
                    children: [
                      TextSpan(
                        text: '.',
                        style: TextStyle(color: NestColors.coral),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    fontFamily: 'InstrumentSerif',
                    fontSize: 38,
                    height: 1.1,
                    letterSpacing: -0.8,
                    color: NestColors.charcoal,
                  ),
                ),
              ),
              const Spacer(),
              ListenableBuilder(
                listenable: Listenable.merge([
                  favoritesController,
                  cartController,
                ]),
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Entrance(
                      kind: EntranceKind.pop,
                      delay: const Duration(milliseconds: 250),
                      duration: const Duration(milliseconds: 900),
                      child: HeaderIconButton(
                        icon: Icons.favorite_border_rounded,
                        label: 'Favorites',
                        count: favoritesController.count,
                        onTap: onFavorites,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Entrance(
                      kind: EntranceKind.pop,
                      delay: const Duration(milliseconds: 350),
                      duration: const Duration(milliseconds: 900),
                      child: HeaderIconButton(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Cart',
                        count: cartController.itemCount,
                        color: NestColors.butter,
                        onTap: onCart,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Entrance(
            delay: const Duration(milliseconds: 200),
            child: Pressable(
              onTap: onSearch,
              semanticLabel: 'Search furniture',
              scale: 0.97,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: NestColors.creamDeep,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: NestColors.charcoal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search furniture',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NestText.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ hero

class _HeroLine extends StatelessWidget {
  const _HeroLine({
    required this.text,
    required this.size,
    required this.delayMs,
    this.italic = false,
    this.color = NestColors.cream,
  });

  final String text;
  final double size;
  final int delayMs;
  final bool italic;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Entrance(
      delay: Duration(milliseconds: delayMs),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          style: NestText.display(size).copyWith(
            height: 1.05,
            color: color,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = (w * 1.42).clamp(440.0, 560.0).toDouble();
          final headline = (w * 0.13).clamp(38.0, 56.0).toDouble();
          final imageW = (w * 0.50).clamp(150.0, 260.0).toDouble();
          final imageH = h * 0.54;
          final textW = w - imageW - 18 - 24 - 14;

          return SizedBox(
            height: h,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(96),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: ColoredBox(
                color: NestColors.cobalt,
                child: Stack(
                  children: [
                    Positioned(
                      right: 26,
                      top: 34,
                      child: Entrance(
                        kind: EntranceKind.pop,
                        delay: const Duration(milliseconds: 500),
                        duration: const Duration(milliseconds: 1000),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: NestColors.coral,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 32,
                      top: 54,
                      child: Entrance(
                        delay: const Duration(milliseconds: 350),
                        child: Text(
                          'AUTUMN EDIT 26',
                          style: NestText.label.copyWith(
                            color: NestColors.butter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      top: 78,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroLine(
                            text: 'Make room',
                            size: headline,
                            delayMs: 450,
                          ),
                          _HeroLine(
                            text: 'for something',
                            size: headline,
                            delayMs: 560,
                          ),
                          _HeroLine(
                            text: 'bright.',
                            size: headline,
                            delayMs: 670,
                            italic: true,
                            color: NestColors.butter,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 18,
                      bottom: 18,
                      width: imageW,
                      height: imageH,
                      child: Entrance(
                        delay: const Duration(milliseconds: 700),
                        duration: const Duration(milliseconds: 1000),
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(imageW / 2),
                            bottom: const Radius.circular(18),
                          ),
                          child: const NestImage(
                            asset: Catalog.heroImage,
                            tone: NestColors.butter,
                            icon: Icons.weekend_outlined,
                            cacheWidth: 900,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      bottom: 96,
                      width: textW,
                      child: Entrance(
                        delay: const Duration(milliseconds: 1000),
                        child: Text(
                          'Sculptural pieces & a little joy.',
                          style: NestText.body.copyWith(
                            fontSize: 13,
                            color: NestColors.cream,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      bottom: 24,
                      child: Entrance(
                        kind: EntranceKind.pop,
                        delay: const Duration(milliseconds: 1100),
                        duration: const Duration(milliseconds: 1000),
                        child: Pressable(
                          onTap: onShop,
                          semanticLabel: 'Shop the edit',
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: NestColors.butter,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: NestColors.charcoal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------ categories

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.eyebrow,
    required this.lead,
    required this.emphasis,
  });

  final String eyebrow;
  final String lead;
  final String emphasis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: NestText.label.copyWith(color: NestColors.cobalt)),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: '$lead ',
            children: [
              TextSpan(
                text: emphasis,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          style: NestText.display(36),
        ),
      ],
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.onCategory});

  final ValueChanged<ProductCategory> onCategory;

  @override
  Widget build(BuildContext context) {
    const categories = ProductCategory.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _SectionTitle(
            eyebrow: 'SHOP BY PIECE',
            lead: 'Start with',
            emphasis: 'a shape',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, i) => Entrance(
              kind: EntranceKind.pop,
              delay: Duration(milliseconds: 150 + i * 90),
              duration: const Duration(milliseconds: 1000),
              child: _CategoryTile(
                category: categories[i],
                shapeIndex: i,
                onTap: () => onCategory(categories[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.shapeIndex,
    required this.onTap,
  });

  final ProductCategory category;
  final int shapeIndex;
  final VoidCallback onTap;

  static const List<BorderRadius> _shapes = [
    BorderRadius.only(
      topLeft: Radius.circular(66),
      topRight: Radius.circular(66),
      bottomLeft: Radius.circular(14),
      bottomRight: Radius.circular(14),
    ),
    BorderRadius.only(
      topLeft: Radius.circular(50),
      bottomRight: Radius.circular(50),
      topRight: Radius.circular(12),
      bottomLeft: Radius.circular(12),
    ),
    BorderRadius.all(Radius.circular(28)),
    BorderRadius.only(
      topRight: Radius.circular(50),
      bottomLeft: Radius.circular(50),
      topLeft: Radius.circular(12),
      bottomRight: Radius.circular(12),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final fg = category.foreground;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Shop ${category.label}',
      child: Container(
        width: 132,
        padding: const EdgeInsets.fromLTRB(18, 34, 18, 18),
        decoration: BoxDecoration(
          color: category.background,
          borderRadius: _shapes[shapeIndex % _shapes.length],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(category.icon, size: 30, color: fg),
            const Spacer(),
            Text(
              category.label,
              style: NestText.display(26).copyWith(color: fg),
            ),
            const SizedBox(height: 2),
            Text(
              '${Catalog.countIn(category)} PIECES',
              style: NestText.label.copyWith(
                fontSize: 10,
                color: fg.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- curated

class _Curated extends StatelessWidget {
  const _Curated({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final items = Catalog.curated;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredIn(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: _SectionTitle(
                    eyebrow: 'CURATED THIS WEEK',
                    lead: "Pieces we'd move",
                    emphasis: 'in with',
                  ),
                ),
                Pressable(
                  onTap: onSeeAll,
                  semanticLabel: 'See all products',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ALL',
                          style: NestText.label.copyWith(
                            color: NestColors.cobalt,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: NestColors.cobalt,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    StaggeredIn(
                      index: 1,
                      child: ProductCard(
                        product: items[0],
                        shape: CardShape.leaf,
                        imageAspect: 0.8,
                      ),
                    ),
                    const SizedBox(height: 24),
                    StaggeredIn(
                      index: 3,
                      child: ProductCard(
                        product: items[1],
                        shape: CardShape.soft,
                        imageAspect: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 44),
                    StaggeredIn(
                      index: 2,
                      child: ProductCard(
                        product: items[2],
                        shape: CardShape.arch,
                        imageAspect: 1.0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    StaggeredIn(
                      index: 4,
                      child: ProductCard(
                        product: items[3],
                        shape: CardShape.leaf,
                        imageAspect: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------- room board promo

class _RoomBoardPromo extends StatelessWidget {
  const _RoomBoardPromo({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Pressable(
        scale: 0.98,
        onTap: onOpen,
        semanticLabel: 'Open Room Board',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: NestColors.coral,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(110),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NEW · ROOM BOARD', style: NestText.label),
              const SizedBox(height: 12),
              Text.rich(
                const TextSpan(
                  text: 'Plan the room.\n',
                  children: [
                    TextSpan(
                      text: 'Keep the budget.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                style: NestText.display(38),
              ),
              const SizedBox(height: 10),
              Text(
                'Collect pieces for a room and see the total against your budget.',
                style: NestText.body.copyWith(color: NestColors.charcoal),
              ),
              const SizedBox(height: 20),
              const _MiniMeter(),
              const SizedBox(height: 20),
              NestButton(
                label: 'Open Room Board',
                background: NestColors.cobalt,
                icon: Icons.arrow_forward_rounded,
                onTap: onOpen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMeter extends StatelessWidget {
  const _MiniMeter();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LIVING ROOM · EXAMPLE',
          style: NestText.label.copyWith(fontSize: 10),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('\$1,800', style: NestText.display(34)),
            const SizedBox(width: 8),
            Text(
              'of \$2,500',
              style: NestText.body.copyWith(color: NestColors.charcoal),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                height: 12,
                color: NestColors.charcoal.withValues(alpha: 0.15),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 0.72),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(height: 12, color: NestColors.cobalt),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------- seating edit

class _SeatingEdit extends StatelessWidget {
  const _SeatingEdit({required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final sofa = Catalog.byId('oslo-sofa');
    final chair = Catalog.byId('miro-chair');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: NestColors.butter,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(110),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('THE SEATING EDIT', style: NestText.label),
            const SizedBox(height: 12),
            Text.rich(
              const TextSpan(
                text: 'Soft shapes for ',
                children: [
                  TextSpan(
                    text: 'slow Sundays.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              style: NestText.display(38),
            ),
            const SizedBox(height: 12),
            Text(
              'Rounded arms, boucle textures and colors that feel like a deep breath.',
              style: NestText.body.copyWith(color: NestColors.charcoal),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Entrance(
                  delay: const Duration(milliseconds: 300),
                  duration: const Duration(milliseconds: 1000),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(65),
                      bottom: Radius.circular(14),
                    ),
                    child: SizedBox(
                      width: 130,
                      height: 170,
                      child: NestImage(
                        asset: sofa.imageAsset,
                        tone: NestColors.cream,
                        icon: sofa.category.icon,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Entrance(
                  kind: EntranceKind.pop,
                  delay: const Duration(milliseconds: 650),
                  duration: const Duration(milliseconds: 1000),
                  child: ClipOval(
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: NestImage(
                        asset: chair.imageAsset,
                        tone: NestColors.coral,
                        icon: chair.category.icon,
                        cacheWidth: 400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            NestButton(
              label: 'Shop seating',
              onTap: onShop,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
