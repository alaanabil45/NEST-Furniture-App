import 'package:flutter/material.dart';

import '../core/nest_theme.dart';
import 'pressable.dart';

/// Minus / quantity / plus control. At quantity 1 the minus becomes a bin.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.canIncrement = true,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool canIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: NestColors.creamDeep,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: quantity <= 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            label: quantity <= 1 ? 'Remove from cart' : 'Decrease quantity',
            onTap: onDecrement,
          ),
          SizedBox(
            width: 28,
            child: AnimatedSwitcher(
              duration: NestMotion.fast,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Text(
                '$quantity',
                key: ValueKey<int>(quantity),
                textAlign: TextAlign.center,
                style: NestText.bodyStrong.copyWith(fontSize: 16),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            label: 'Increase quantity',
            onTap: canIncrement ? onIncrement : () {},
            dimmed: !canIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dimmed = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      scale: 0.88,
      child: SizedBox(
        width: 48,
        height: 52,
        child: Icon(
          icon,
          size: 22,
          color: dimmed
              ? NestColors.charcoal.withValues(alpha: 0.3)
              : NestColors.charcoal,
        ),
      ),
    );
  }
}
