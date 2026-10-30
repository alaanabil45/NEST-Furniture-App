import 'package:flutter/material.dart';

import '../core/nest_theme.dart';
import 'pressable.dart';

class NestChip extends StatelessWidget {
  const NestChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: selected ? '$label, selected' : label,
      child: AnimatedContainer(
        duration: NestMotion.base,
        curve: NestMotion.enter,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? NestColors.charcoal : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? NestColors.charcoal : NestColors.line,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: NestMotion.base,
              style: NestText.button.copyWith(
                color: selected ? NestColors.cream : NestColors.charcoal,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
