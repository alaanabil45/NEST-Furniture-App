import 'dart:async';

import 'package:flutter/material.dart';

enum EntranceKind {
  /// Slides up from behind an invisible mask (great for text lines, images).
  rise,

  /// Springs in from nothing with a little bounce (great for buttons, dots).
  pop,
}

class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.kind = EntranceKind.rise,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 800),
  });

  final Widget child;
  final EntranceKind kind;
  final Duration delay;
  final Duration duration;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _slide = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutQuart,
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, 1.1),
    end: Offset.zero,
  ).animate(_slide);
  late final Animation<double> _pop = CurvedAnimation(
    parent: _c,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.35, curve: Curves.easeOut),
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
      _c.duration = const Duration(milliseconds: 350);
      _c.forward();
      return;
    }
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_reduced) return FadeTransition(opacity: _c, child: widget.child);
    return switch (widget.kind) {
      EntranceKind.rise => ClipRect(
        child: SlideTransition(position: _offset, child: widget.child),
      ),
      EntranceKind.pop => FadeTransition(
        opacity: _fade,
        child: ScaleTransition(scale: _pop, child: widget.child),
      ),
    };
  }
}
