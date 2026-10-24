import 'dart:async';

import 'package:flutter/material.dart';

/// [child] fading in as it rises [distance] px into place, once, after
/// [delay]. With Reduce motion it only fades.
class CallEntrance extends StatefulWidget {
  const CallEntrance({
    required this.child,
    this.distance = 20,
    this.delay = Duration.zero,
    super.key,
  });

  static const _duration = Duration(milliseconds: 500);

  /// The design's entry curve, a touch of overshoot.
  static const _curve = Cubic(0.2, 0.9, 0.3, 1.1);

  final double distance;
  final Duration delay;
  final Widget child;

  @override
  State<CallEntrance> createState() => _CallEntranceState();
}

class _CallEntranceState extends State<CallEntrance>
    with SingleTickerProviderStateMixin {
  // The delay is the start of the animation, so no timer outlives it.
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.delay + CallEntrance._duration,
  );
  late final _interval = Interval(
    widget.delay.inMicroseconds / _controller.duration!.inMicroseconds,
    1,
  );
  late final _fade = CurvedAnimation(parent: _controller, curve: _interval);
  late final _rise = CurvedAnimation(
    parent: _controller,
    curve: Interval(_interval.begin, 1, curve: CallEntrance._curve),
  );
  var _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    if (_controller.isDismissed) {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _rise.dispose();
    _fade.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final distance = _still ? 0.0 : widget.distance;
    return AnimatedBuilder(
      animation: _rise,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, distance * (1 - _rise.value)),
        child: child,
      ),
      child: FadeTransition(opacity: _fade, child: widget.child),
    );
  }
}
