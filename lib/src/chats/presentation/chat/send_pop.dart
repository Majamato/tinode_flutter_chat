import 'dart:async';

import 'package:flutter/material.dart';

/// Pops a message the user just sent out of its tail corner: it grows from
/// a third of its size, overshoots a little and settles, rising as it
/// does. A plain fade with the OS's Reduce motion; nothing at all when not
/// [animate], e.g. for messages already waiting when the chat opened.
class SendPop extends StatefulWidget {
  const SendPop({required this.animate, required this.child, super.key});

  /// Read once, when the bubble first shows.
  final bool animate;
  final Widget child;

  @override
  State<SendPop> createState() => _SendPopState();
}

class _SendPopState extends State<SendPop> with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 420);

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.35,
        end: 1.05,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 60,
    ),
    TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.98), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 0.98, end: 1), weight: 20),
  ]);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: _controller, child: widget.child);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Opacity(
          opacity: (t * 3).clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - Curves.easeOut.transform(t))),
            child: Transform.scale(
              scale: _scale.transform(t),
              alignment: AlignmentDirectional.bottomEnd.resolve(
                Directionality.of(context),
              ),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
