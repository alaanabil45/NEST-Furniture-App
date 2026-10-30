import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nest_theme.dart';
import '../data/product.dart';
import '../widgets/intro_overlay.dart';
import '../widgets/nest_nav_bar.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'shop_screen.dart';

class NestShell extends StatefulWidget {
  const NestShell({super.key});

  @override
  State<NestShell> createState() => _NestShellState();
}

class _NestShellState extends State<NestShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  int _direction = 1;
  bool _homeReady = false;
  bool _introDone = false;

  // Tabs are built the first time they are opened, so their entrance
  // animations are actually seen, then kept alive by the IndexedStack.
  final List<bool> _visited = [true, false, false, false];
  final GlobalKey<ShopScreenState> _shopKey = GlobalKey<ShopScreenState>();

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _fadeController,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _direction = i > _index ? 1 : -1;
      _index = i;
      _visited[i] = true;
    });
    _fadeController.forward(from: 0);
  }

  void _goShop({
    ProductCategory? category,
    bool setCategory = false,
    bool focus = false,
  }) {
    _select(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shop = _shopKey.currentState;
      if (shop == null) return;
      if (setCategory) shop.showCategory(category);
      if (focus) shop.focusSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    debugPrint('NEST DEBUG: NestShell build; introDone=$_introDone');

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _select(0);
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Scaffold(
              backgroundColor: NestColors.cream,
              body: FadeTransition(
                opacity: _fade,
                child: AnimatedBuilder(
                  animation: _fade,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      reduced ? 0 : (1 - _fade.value) * 36 * _direction,
                      0,
                    ),
                    child: child,
                  ),
                  child: IndexedStack(
                    index: _index,
                    children: [
                      _homeReady
                          ? HomeScreen(
                              onSearch: () => _goShop(focus: true),
                              onCategory: (c) =>
                                  _goShop(category: c, setCategory: true),
                              onSeeAll: () => _goShop(setCategory: true),
                              onFavorites: () => _select(2),
                              onCart: () => _select(3),
                            )
                          : const SizedBox.shrink(),
                      _visited[1]
                          ? ShopScreen(key: _shopKey)
                          : const SizedBox.shrink(),
                      _visited[2]
                          ? FavoritesScreen(onBrowse: () => _goShop())
                          : const SizedBox.shrink(),
                      _visited[3]
                          ? CartScreen(onBrowse: () => _goShop())
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: AnimatedSlide(
                offset: _homeReady ? Offset.zero : const Offset(0, 2),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                child: NestNavBar(index: _index, onSelected: _select),
              ),
            ),
          ),
          if (!_introDone)
            Positioned.fill(
              child: IntroOverlay(
                onReveal: () {
                  if (mounted) setState(() => _homeReady = true);
                },
                onDone: () {
                  if (mounted) setState(() => _introDone = true);
                },
              ),
            ),
        ],
      ),
    );
  }
}
