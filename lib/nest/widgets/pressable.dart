import 'package:flutter/material.dart';

import '../core/nest_theme.dart';

/// Tap target with a small, tactile scale-down press effect.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.95,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (mounted && _down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => Future<void>.delayed(
          const Duration(milliseconds: 70),
          () => _set(false),
        ),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1.0,
          duration: NestMotion.fast,
          curve: NestMotion.press,
          child: widget.child,
        ),
      ),
    );
  }
}
