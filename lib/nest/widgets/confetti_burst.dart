import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/nest_theme.dart';

enum _Shape { rect, strip, dot }

class _Particle {
  const _Particle({
    required this.x0,
    required this.y0,
    required this.vx,
    required this.vy,
    required this.delay,
    required this.size,
    required this.color,
    required this.shape,
    required this.spin,
    required this.rot0,
    required this.flutter,
  });

  /// Start position as a fraction of the canvas.
  final double x0;
  final double y0;

  /// Start velocity in pixels per second (for an 800px-tall canvas).
  final double vx;
  final double vy;

  /// Seconds before this piece appears.
  final double delay;
  final double size;
  final Color color;
  final _Shape shape;
  final double spin;
  final double rot0;
  final double flutter;
}

/// Plays one confetti show: two cannons from the bottom corners plus a
/// shower from the top. Place it on top of a screen; it ignores touches.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const double _seconds = 3.4;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );
  late final List<_Particle> _particles = _make();
  bool _started = false;

  static List<_Particle> _make() {
    final r = math.Random(7);
    const colors = [
      NestColors.cobalt,
      NestColors.butter,
      NestColors.coral,
      NestColors.softGreen,
      NestColors.charcoal,
    ];
    final list = <_Particle>[];

    _Particle build({
      required double x0,
      required double y0,
      required double vx,
      required double vy,
      required double delay,
    }) {
      return _Particle(
        x0: x0,
        y0: y0,
        vx: vx,
        vy: vy,
        delay: delay,
        size: 6 + r.nextDouble() * 7,
        color: colors[r.nextInt(colors.length)],
        shape: _Shape.values[r.nextInt(_Shape.values.length)],
        spin: (r.nextDouble() - 0.5) * 14,
        rot0: r.nextDouble() * math.pi * 2,
        flutter: 4 + r.nextDouble() * 6,
      );
    }

    // Cannons
    for (var i = 0; i < 70; i++) {
      final left = i.isEven;
      final spread = r.nextDouble() * 0.9;
      final angle = left ? -math.pi / 2 + spread : -math.pi / 2 - spread;
      final speed = 650 + r.nextDouble() * 750;
      list.add(
        build(
          x0: left ? 0.08 : 0.92,
          y0: 0.72,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          delay: r.nextDouble() * 0.15,
        ),
      );
    }

    // Shower
    for (var i = 0; i < 55; i++) {
      list.add(
        build(
          x0: r.nextDouble(),
          y0: -0.05,
          vx: (r.nextDouble() - 0.5) * 120,
          vy: 80 + r.nextDouble() * 160,
          delay: 0.4 + r.nextDouble() * 1.2,
        ),
      );
    }
    return list;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(_particles, _controller, _seconds),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.animation, this.total)
    : super(repaint: animation);

  final List<_Particle> particles;
  final Animation<double> animation;
  final double total;

  static const double _drag = 1.7;
  static const double _gravity = 900;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * total;
    final k = size.height / 800;
    final fade = ((total - t) / 0.8).clamp(0.0, 1.0).toDouble();
    if (fade <= 0) return;
    final paint = Paint();

    for (final p in particles) {
      final tt = t - p.delay;
      if (tt <= 0) continue;

      final e = 1 - math.exp(-_drag * tt);
      final x = p.x0 * size.width + p.vx * k * e / _drag;
      final y =
          p.y0 * size.height +
          p.vy * k * e / _drag +
          (_gravity * k / _drag) * (tt - e / _drag);
      if (y > size.height + 40) continue;

      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot0 + p.spin * tt);
      canvas.scale(
        1.0,
        math.cos(p.flutter * tt).abs().clamp(0.15, 1.0).toDouble(),
      );
      switch (p.shape) {
        case _Shape.rect:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.6,
            ),
            paint,
          );
        case _Shape.strip:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 1.8,
              height: p.size * 0.35,
            ),
            paint,
          );
        case _Shape.dot:
          canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => false;
}
