import 'package:flutter/material.dart';

import '../core/nest_theme.dart';
import 'pressable.dart';

class NestButton extends StatelessWidget {
  const NestButton({
    super.key,
    required this.label,
    required this.onTap,
    this.background = NestColors.charcoal,
    this.foreground = NestColors.cream,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NestText.button.copyWith(color: foreground),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: foreground),
            ],
          ],
        ),
      ),
    );
  }
}
