import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_waveform.dart';

/// A voice message's waveform: bars from [waveform] (0..100 each), 2 px
/// wide, 2 px apart and 2 to 22 px tall, so silence shows as dots, as many
/// as fit the width less [inset] at each end, and a dot centred on the
/// playhead. Those before the dot take [playedColor]. The dot is 8 px at
/// rest and grows to 12 px while playing or dragging.
///
/// While [playing], the dot moves on its own every frame, from the last
/// [progress] over [duration], so it glides between the player's reports.
/// It never steps back while playing: it starts gliding once a report shows
/// the audio really moves (as play starts, or after a seek), and when a
/// report is behind it, it slows down until the audio catches up, stopping
/// only when [catchUp] or more ahead. Paused or stopped, it
/// stands at [progress]. A tap, or a drag once the finger lifts, calls
/// [onSeek] with the fraction there, and moves the dot straight there;
/// while dragging, the dot follows the finger. Hidden from screen readers:
/// the play button speaks for the message.
class VoiceWaveform extends StatefulWidget {
  const VoiceWaveform({
    required this.waveform,
    required this.progress,
    required this.duration,
    required this.playing,
    required this.playedColor,
    required this.unplayedColor,
    this.onSeek,
    super.key,
  });

  static const barWidth = 2.0;
  static const barGap = 2.0;
  static const minBarHeight = 2.0;
  static const maxBarHeight = 22.0;

  /// Bar heights follow the loudness to this power, so quieter stretches
  /// still rise and speech reads as ups and downs.
  static const loudnessCurve = 0.7;

  /// The dot while playing or dragging, and at rest.
  static const dotSize = 12.0;
  static const restingDotSize = 8.0;

  /// How far ahead of the audio the dot may run before it stops for it;
  /// nearer, it slows down instead.
  static const catchUp = Duration(milliseconds: 400);
  static const height = 24.0;

  /// The room before the first bar and after the last, so the dot's
  /// centre reaches both ends of the bars.
  static const double inset = dotSize / 2;

  /// The width of [count] bars.
  static double widthOf(int count) =>
      count <= 0 ? 0 : count * barWidth + (count - 1) * barGap;

  /// How many bars fit in [width].
  static int barCountFor(double width) =>
      ((width + barGap) / (barWidth + barGap)).floor().clamp(0, 1 << 10);

  final List<int> waveform;
  final double progress;
  final Duration duration;
  final bool playing;
  final Color playedColor;
  final Color unplayedColor;
  final ValueChanged<double>? onSeek;

  @override
  State<VoiceWaveform> createState() => VoiceWaveformState();
}

class VoiceWaveformState extends State<VoiceWaveform>
    with TickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late final _head = ValueNotifier<double>(widget.progress);

  /// How grown the dot is: 0 at rest, 1 while playing or dragging.
  late final _grown = AnimationController(
    vsync: this,
    value: widget.playing ? 1 : 0,
  );

  /// Where the audio was last known to be, and the ticker's time then.
  late double _anchor = widget.progress;
  Duration _anchorAt = Duration.zero;
  Duration _elapsed = Duration.zero;
  var _dragging = false;

  /// Whether a report has shown the audio moving since play started or the
  /// last seek: the dot glides only then.
  var _moving = false;

  /// The width the bars take, for seeking.
  var _span = 0.0;

  List<int>? _barsOf;
  var _barsCount = -1;
  var _bars = const <double>[];

  /// Where the dot stands, 0..1.
  @visibleForTesting
  ValueListenable<double> get head => _head;

  /// The dot's size now.
  @visibleForTesting
  double get dotSize => _dotSizeAt(_grown.value);

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void didUpdateWidget(VoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _anchorTo(_head.value);
    }
    if (widget.progress != oldWidget.progress && !_dragging) {
      if (widget.playing) {
        _report(widget.progress);
      } else {
        _anchorTo(widget.progress);
      }
    }
    _run();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _grown.dispose();
    _head.dispose();
    super.dispose();
  }

  /// Grows the dot while playing or dragging, shrinks it otherwise.
  void _resize() {
    final target = widget.playing || _dragging ? 1.0 : 0.0;
    if (_grown.value == target && !_grown.isAnimating) {
      return;
    }
    final theme = TinodeChatTheme.of(context);
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _grown.value = target;
      return;
    }
    unawaited(
      _grown.animateTo(
        target,
        duration: theme.springDuration,
        curve: theme.springCurve,
      ),
    );
  }

  /// Runs the ticker while playing and not dragging, and sizes the dot.
  void _run() {
    _resize();
    final run = widget.playing && !_dragging && widget.duration > Duration.zero;
    if (run && !_ticker.isActive) {
      _elapsed = Duration.zero;
      _anchorTo(_head.value);
      _moving = false;
      unawaited(_ticker.start());
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final frame = elapsed - _elapsed;
    _elapsed = elapsed;
    final length = widget.duration.inMicroseconds;
    if (!_moving || length <= 0) {
      return;
    }
    final moved = (elapsed - _anchorAt).inMicroseconds / length;
    final at = (_anchor + moved).clamp(0.0, 1.0);
    if (at >= _head.value) {
      _head.value = at;
      return;
    }
    // Ahead of the audio, as when a report lags it: the further ahead, the
    // slower it goes, stopping at [VoiceWaveform.catchUp], so the audio
    // catches up without the dot stalling or stepping back. The lead is as
    // the frame began, as the dot's step covers the whole frame.
    final lead = (_head.value - at) * length + frame.inMicroseconds;
    final pace = (1 - lead / VoiceWaveform.catchUp.inMicroseconds).clamp(
      0.0,
      1.0,
    );
    _head.value = min(1, _head.value + pace * frame.inMicroseconds / length);
  }

  /// Moves the dot straight to [fraction], back too.
  void _anchorTo(double fraction) {
    _head.value = fraction;
    _anchor = fraction;
    _anchorAt = _elapsed;
  }

  /// The player reported [fraction] while playing: the glide goes on from
  /// there, but the dot only moves forward.
  void _report(double fraction) {
    final length = widget.duration.inMicroseconds;
    // Ahead of the last known place by more than a rounding error.
    if ((fraction - _anchor) * length > 1000) {
      _moving = true;
    }
    _anchor = fraction;
    _anchorAt = _elapsed;
    if (fraction > _head.value) {
      _head.value = fraction;
    }
  }

  double _fractionAt(double dx) => _span > 0
      ? ((dx - VoiceWaveform.inset) / _span).clamp(0, 1).toDouble()
      : 0;

  void _drag(double dx) {
    _dragging = true;
    _run();
    _head.value = _fractionAt(dx);
  }

  void _seek(double fraction) {
    _dragging = false;
    _anchorTo(fraction);
    _moving = false;
    widget.onSeek?.call(fraction);
    _run();
  }

  void _cancelDrag() {
    _dragging = false;
    _anchorTo(widget.progress);
    _moving = false;
    _run();
  }

  List<double> _barsFor(int count) {
    if (count != _barsCount || !listEquals(widget.waveform, _barsOf)) {
      _barsOf = widget.waveform;
      _barsCount = count;
      _bars = voiceBars(widget.waveform, count: count);
    }
    return _bars;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : VoiceWaveform.widthOf(26) + 2 * VoiceWaveform.inset;
      final bars = _barsFor(
        VoiceWaveform.barCountFor(width - 2 * VoiceWaveform.inset),
      );
      _span = VoiceWaveform.widthOf(bars.length);
      final paint = ExcludeSemantics(
        child: CustomPaint(
          size: Size(width, VoiceWaveform.height),
          painter: _WaveformPainter(
            bars: bars,
            head: _head,
            grown: _grown,
            playedColor: widget.playedColor,
            unplayedColor: widget.unplayedColor,
          ),
        ),
      );
      if (widget.onSeek == null) {
        return paint;
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _seek(_fractionAt(details.localPosition.dx)),
        onHorizontalDragStart: (details) => _drag(details.localPosition.dx),
        onHorizontalDragUpdate: (details) => _drag(details.localPosition.dx),
        onHorizontalDragEnd: (_) => _seek(_head.value),
        onHorizontalDragCancel: _cancelDrag,
        child: paint,
      );
    },
  );
}

/// A dot's size when it is [grown] (0..1) of the way from rest to full.
/// The spring may overshoot a little past full.
double _dotSizeAt(double grown) =>
    VoiceWaveform.restingDotSize +
    (VoiceWaveform.dotSize - VoiceWaveform.restingDotSize) * grown;

/// The bars, those before the [head] played, and the dot on top.
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.bars,
    required this.head,
    required this.grown,
    required this.playedColor,
    required this.unplayedColor,
  }) : super(repaint: Listenable.merge([head, grown]));

  final List<double> bars;
  final ValueListenable<double> head;
  final Animation<double> grown;
  final Color playedColor;
  final Color unplayedColor;

  @override
  void paint(Canvas canvas, Size size) {
    final played = Paint()..color = playedColor;
    final unplayed = Paint()..color = unplayedColor;
    final span = VoiceWaveform.widthOf(bars.length);
    if (span <= 0) {
      return;
    }
    final at = VoiceWaveform.inset + head.value * span;
    for (var i = 0; i < bars.length; i++) {
      final height =
          VoiceWaveform.minBarHeight +
          (VoiceWaveform.maxBarHeight - VoiceWaveform.minBarHeight) *
              pow(bars[i].clamp(0, 1), VoiceWaveform.loudnessCurve).toDouble();
      final left =
          VoiceWaveform.inset +
          i * (VoiceWaveform.barWidth + VoiceWaveform.barGap);
      final top = (size.height - height) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, VoiceWaveform.barWidth, height),
          const Radius.circular(1),
        ),
        left + VoiceWaveform.barWidth / 2 < at ? played : unplayed,
      );
    }
    canvas.drawCircle(
      Offset(at, size.height / 2),
      _dotSizeAt(grown.value) / 2,
      played,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.head != head ||
      old.grown != grown ||
      old.playedColor != playedColor ||
      old.unplayedColor != unplayedColor ||
      !identical(old.bars, bars);
}
