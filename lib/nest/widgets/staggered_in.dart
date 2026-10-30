import 'dart:async';

import 'package:flutter/material.dart';

import '../core/nest_theme.dart';

/// Fades, springs up and scales in once, after a delay of `index * 70ms`.
/// With "Remove animations" on, it only fades (no movement).
class StaggeredIn extends StatefulWidget {
  const StaggeredIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 44,
    this.scaleFrom = 0.92,
  });

  final Widget child;
  final int index;
  final double offset;
  final double scaleFrom;

  @override
  State<StaggeredIn> createState() => _StaggeredInState();
}

class _StaggeredInState extends State<StaggeredIn>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.5, curve: Curves.easeOut),
  );
  late final Animation<double> _move = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );

  Timer? _timer;
  bool _started = false;
  bool _reduced = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _controller.duration = const Duration(milliseconds: 350);
      _controller.forward();
      return;
    }
    final steps = widget.index > 8 ? 8 : widget.index;
    if (steps == 0) {
      _controller.forward();
    } else {
      _timer = Timer(NestMotion.stagger * steps, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_reduced) {
      return FadeTransition(opacity: _controller, child: widget.child);
    }
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: _move,
        child: widget.child,
        builder: (context, child) {
          final v = _move.value;
          return Transform.translate(
            offset: Offset(0, (1 - v) * widget.offset),
            child: Transform.scale(
              scale: widget.scaleFrom + (1 - widget.scaleFrom) * v,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
