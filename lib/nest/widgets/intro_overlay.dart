import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/nest_theme.dart';
import '../data/catalog.dart';

/// Launch animation: letters rise, shapes pop, then the blue curtain lifts.
/// It advances by at most ~34ms per rendered frame, so a slow phone still
/// shows every part of it instead of jumping to the end.
/// With "Remove animations" on, a calm fade-only version plays instead.
class IntroOverlay extends StatefulWidget {
  const IntroOverlay({super.key, required this.onReveal, required this.onDone});

  /// Called when Home should start building behind the overlay.
  final VoidCallback onReveal;

  /// Called when the overlay can be removed.
  final VoidCallback onDone;

  @override
  State<IntroOverlay> createState() => _IntroOverlayState();
}

class _IntroOverlayState extends State<IntroOverlay>
    with SingleTickerProviderStateMixin {
  static const double _liftStart = 0.68;
  static const double _calmReveal = 0.45;
  static const String _word = 'nest';
  static const double _fullMs = 2300;
  static const double _calmMs = 1300;
  static const Duration _maxStep = Duration(milliseconds: 34);

  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _t = ValueNotifier<double>(0);

  Duration _last = Duration.zero;
  double _ms = 0;
  bool _revealed = false;
  bool _done = false;
  bool _started = false;
  bool _calm = false;

  void _tick(Duration elapsed) {
    final dt = elapsed - _last;
    _last = elapsed;
    final step = dt > _maxStep ? _maxStep : dt;
    _ms += step.inMicroseconds / 1000;

    final total = _calm ? _calmMs : _fullMs;
    final value = (_ms / total).clamp(0.0, 1.0).toDouble();
    _t.value = value;

    final revealAt = _calm ? _calmReveal : _liftStart;
    if (!_revealed && value >= revealAt) {
      _revealed = true;
      widget.onReveal();
    }
    if (value >= 1 && !_done) {
      _done = true;
      _ticker.stop();
      widget.onDone();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _calm = MediaQuery.disableAnimationsOf(context);
    debugPrint('NEST intro: reduced motion = $_calm');

    // Wait (briefly) for the hero photo so Home does not stutter later.
    final hero = precacheImage(
      const AssetImage(Catalog.heroImage),
      context,
      onError: (error, stack) {},
    );
    Future.any<void>([
      hero,
      Future<void>.delayed(const Duration(milliseconds: 1500)),
    ]).then((_) {
      if (mounted) _ticker.start();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  double _p(double start, double end, [Curve curve = Curves.easeOut]) {
    final v = ((_t.value - start) / (end - start)).clamp(0.0, 1.0).toDouble();
    return curve.transform(v);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final fs = (size.width * 0.28).clamp(80.0, 130.0).toDouble();

    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        if (_calm) {
          return Opacity(
            opacity: 1 - _p(0.6, 1.0),
            child: ColoredBox(
              color: NestColors.cobalt,
              child: Center(
                child: Opacity(
                  opacity: _p(0.0, 0.3),
                  child: Text.rich(
                    const TextSpan(
                      text: 'nest',
                      children: [
                        TextSpan(
                          text: '.',
                          style: TextStyle(color: NestColors.coral),
                        ),
                      ],
                    ),
                    style: NestText.display(fs)
                        .copyWith(color: NestColors.cream),
                  ),
                ),
              ),
            ),
          );
        }

        final lift = _p(_liftStart, 1.0, Curves.easeInOutCubic);
        return Transform.translate(
          offset: Offset(0, -lift * size.height),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(56),
            ),
            child: ColoredBox(
              color: NestColors.cobalt,
              child: Stack(
                children: [
                  Positioned(
                    left: -size.width * 0.25,
                    bottom: -size.width * 0.25,
                    width: size.width * 0.9,
                    height: size.width * 0.9,
                    child: Transform.scale(
                      scale: _p(0, 0.55, Curves.easeOutCubic),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: NestColors.butter,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -30,
                    top: size.height * 0.12,
                    width: 150,
                    height: 150,
                    child: Transform.scale(
                      scale: _p(0.1, 0.6, Curves.elasticOut),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: NestColors.coral,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < _word.length; i++)
                              SizedBox(
                                height: fs * 1.15,
                                child: ClipRect(
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      (1 -
                                              _p(
                                                0.04 * i + 0.05,
                                                0.04 * i + 0.35,
                                                Curves.easeOutQuart,
                                              )) *
                                          fs *
                                          1.2,
                                    ),
                                    child: Text(
                                      _word[i],
                                      style: NestText.display(fs)
                                          .copyWith(color: NestColors.cream),
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: EdgeInsets.only(
                                left: 4,
                                bottom: fs * 0.14,
                              ),
                              child: Transform.scale(
                                scale: _p(0.3, 0.62, Curves.elasticOut),
                                child: Container(
                                  width: fs * 0.16,
                                  height: fs * 0.16,
                                  decoration: const BoxDecoration(
                                    color: NestColors.coral,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Opacity(
                          opacity: _p(0.45, 0.6),
                          child: Text(
                            'FURNITURE & HOME',
                            style: NestText.label.copyWith(
                              color: NestColors.butter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
