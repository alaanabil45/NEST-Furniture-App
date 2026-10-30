import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nest_theme.dart';
import '../state/favorites_controller.dart';
import 'pressable.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.productId,
    required this.name,
  });

  final String productId;
  final String name;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.0,
        end: 1.35,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.35,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 60,
    ),
  ]).animate(_pop);

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _toggle() {
    favoritesController.toggle(widget.productId);
    HapticFeedback.lightImpact();
    if (favoritesController.isFavorite(widget.productId)) {
      _pop.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: favoritesController,
      builder: (context, _) {
        final fav = favoritesController.isFavorite(widget.productId);
        return Pressable(
          onTap: _toggle,
          semanticLabel: fav
              ? 'Remove ${widget.name} from favorites'
              : 'Add ${widget.name} to favorites',
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: ScaleTransition(
                scale: _scale,
                child: AnimatedContainer(
                  duration: NestMotion.base,
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fav ? NestColors.coral : NestColors.cream,
                  ),
                  child: Icon(
                    fav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: NestColors.charcoal,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
