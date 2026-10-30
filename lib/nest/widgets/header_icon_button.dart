import 'package:flutter/material.dart';

import '../core/nest_theme.dart';
import 'pressable.dart';

class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    this.color = NestColors.creamDeep,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: count > 0 ? '$label, $count' : label,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Icon(icon, size: 22, color: NestColors.charcoal),
              ),
            ),
            Positioned(
              right: -4,
              top: -4,
              child: AnimatedScale(
                scale: count > 0 ? 1 : 0,
                duration: NestMotion.base,
                curve: Curves.easeOutBack,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: NestColors.coral,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NestColors.cream, width: 2),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: NestText.label.copyWith(
                      fontSize: 10,
                      letterSpacing: 0,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
