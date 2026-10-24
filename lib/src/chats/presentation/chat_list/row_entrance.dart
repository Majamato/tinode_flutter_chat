import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// A list row that fades up 14 px into place after [delay], once. With
/// [animate] false, or Reduce motion, it is simply there.
class RowEntrance extends StatefulWidget {
  const RowEntrance({
    required this.child,
    this.animate = true,
    this.delay = Duration.zero,
    super.key,
  });

  /// How long a row takes to rise.
  static const duration = Duration(milliseconds: 420);

  /// The time between two rows starting.
  static const stagger = Duration(milliseconds: 40);

  final bool animate;
  final Duration delay;
  final Widget child;

  @override
  State<RowEntrance> createState() => _RowEntranceState();
}

class _RowEntranceState extends State<RowEntrance>
    with SingleTickerProviderStateMixin {
  // The delay is the start of the animation, so no timer outlives the row.
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.delay + RowEntrance.duration,
    value: widget.animate ? 0 : 1,
  );
  late final double _start =
      widget.delay.inMicroseconds / _controller.duration!.inMicroseconds;
  late final _fade = CurvedAnimation(
    parent: _controller,
    curve: Interval(_start, 1),
  );
  CurvedAnimation? _rise;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rise?.dispose();
    _rise = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        _start,
        1,
        curve: TinodeChatTheme.of(context).springCurve,
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _rise?.dispose();
    _fade.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rise = _rise!;
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: rise,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 14 * (1 - rise.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
