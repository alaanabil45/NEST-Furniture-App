import 'package:flutter/material.dart';

import '../core/nest_theme.dart';
import 'nest_button.dart';
import 'staggered_in.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.lead,
    required this.emphasis,
    required this.message,
    this.accent = NestColors.softGreen,
    this.accent2 = NestColors.butter,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String lead;
  final String emphasis;
  final String message;
  final Color accent;
  final Color accent2;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: NestMotion.slow,
              curve: Curves.easeOutBack,
              builder: (context, t, child) => Transform.scale(
                scale: 0.85 + 0.15 * t,
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0).toDouble(),
                  child: child,
                ),
              ),
              child: _Art(icon: icon, accent: accent, accent2: accent2),
            ),
            const SizedBox(height: 28),
            StaggeredIn(
              index: 1,
              offset: 14,
              child: Column(
                children: [
                  Text.rich(
                    TextSpan(
                      text: '$lead ',
                      children: [
                        TextSpan(
                          text: emphasis,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: NestColors.cobalt,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: NestText.display(36),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: NestText.body,
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 24),
                    NestButton(
                      label: actionLabel!,
                      onTap: onAction!,
                      icon: Icons.arrow_forward_rounded,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Art extends StatelessWidget {
  const _Art({required this.icon, required this.accent, required this.accent2});

  final IconData icon;
  final Color accent;
  final Color accent2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 180,
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 0,
            child: Container(
              width: 130,
              height: 170,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(65),
                  bottom: Radius.circular(16),
                ),
              ),
              child: Icon(icon, size: 44, color: NestColors.charcoal),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 6,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: accent2, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: 8,
            top: 16,
            child: Transform.rotate(
              angle: 0.45,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: NestColors.cobalt,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
