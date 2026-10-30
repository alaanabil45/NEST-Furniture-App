import 'package:flutter/material.dart';

import '../core/nest_theme.dart';
import '../data/catalog.dart';
import '../state/favorites_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_sliver_grid.dart';
import '../widgets/screen_title.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: favoritesController,
        builder: (context, _) {
          final items = Catalog.all
              .where((p) => favoritesController.isFavorite(p.id))
              .toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: ScreenTitle(
                    lead: 'Your',
                    emphasis: 'favorites',
                    subtitle:
                        '${items.length} ${items.length == 1 ? 'piece' : 'pieces'} saved',
                  ),
                ),
              ),
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.favorite_border_rounded,
                    accent: NestColors.coral,
                    accent2: NestColors.butter,
                    lead: 'Nothing saved',
                    emphasis: 'yet.',
                    message: 'Tap the heart on anything you love and it will wait for you here.',
                    actionLabel: 'Find something to love',
                    onAction: onBrowse,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  sliver: ProductSliverGrid(products: items, heroScope: 'fav'),
                ),
            ],
          );
        },
      ),
    );
  }
}
