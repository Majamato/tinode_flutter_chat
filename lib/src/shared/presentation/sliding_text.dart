import 'dart:async';

import 'package:flutter/material.dart';

/// One line of [text], as wide as it needs. When that is wider than the
/// room it has, it slides to its end and back, resting at each, so all of
/// it gets seen; with Reduce motion it stands still, cut by an ellipsis.
/// Tapping goes through to whatever is under it. Watches nothing.
class SlidingText extends StatefulWidget {
  const SlidingText(this.text, {this.style, super.key});

  final String text;

  final TextStyle? style;

  @override
  State<SlidingText> createState() => _SlidingTextState();
}

class _SlidingTextState extends State<SlidingText>
    with SingleTickerProviderStateMixin {
  /// How long the text rests at each end.
  static const _rest = Duration(seconds: 2);

  /// Slow enough to read while it moves.
  static const _pixelsPerSecond = 30.0;

  final _scroll = ScrollController();
  late final AnimationController _loop;

  /// How far the text sticks out, as last laid out.
  double _overflow = 0;

  /// Where the text is along [_loop].
  Animation<double> _offset = kAlwaysDismissedAnimation;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(vsync: this)..addListener(_slide);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _overflow = 0;
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _slide() {
    if (_scroll.hasClients) {
      _scroll.jumpTo(_offset.value);
    }
  }

  /// Fits the loop to how far the text sticks out, whenever that changes.
  /// The metrics change on every slide too, with the same overflow.
  bool _onMetrics(ScrollMetricsNotification notification) {
    final overflow = notification.metrics.maxScrollExtent;
    if (overflow == _overflow) {
      return false;
    }
    _overflow = overflow;
    _loop.value = 0;
    if (overflow <= 0) {
      return false;
    }
    final rest = _rest.inMilliseconds.toDouble();
    final slide = overflow / _pixelsPerSecond * 1000;
    _offset = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0), weight: rest),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: overflow,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: slide,
      ),
      TweenSequenceItem(tween: ConstantTween(overflow), weight: rest),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: overflow,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: slide,
      ),
    ]).animate(_loop);
    _loop.duration = Duration(milliseconds: (rest + slide).round() * 2);
    unawaited(_loop.repeat());
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(
        widget.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      );
    }
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetrics,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scroll,
        physics: const NeverScrollableScrollPhysics(),
        child: Text(widget.text, maxLines: 1, style: widget.style),
      ),
    );
  }
}
