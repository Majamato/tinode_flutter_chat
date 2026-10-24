import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The background of the call screens: large blurred shapes over a dark
/// base. Behind a voice call or the ringing screen they drift and swell in
/// 9 to 14 s loops under a scrim; behind a [video] call that has no
/// picture yet they hold still. Decoration only: hidden from screen
/// readers, and still with Reduce motion.
class CallBackdrop extends StatefulWidget {
  const CallBackdrop({this.video = false, super.key});

  /// One loop of the controller: every blob's period divides it.
  static const _loop = Duration(seconds: 9 * 11 * 14);

  final bool video;

  @override
  State<CallBackdrop> createState() => _CallBackdropState();
}

class _CallBackdropState extends State<CallBackdrop>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: CallBackdrop._loop,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.video || MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: widget.video
              ? _BlobPainter(
                  animation: _controller,
                  base: theme.videoPlaceholderColor,
                  colors: theme.videoBlobColors,
                  blobs: _videoBlobs,
                  opacity: 1,
                )
              : _BlobPainter(
                  animation: _controller,
                  base: theme.callBackgroundColor,
                  colors: theme.callBlobColors,
                  blobs: _voiceBlobs,
                  opacity: 0.85,
                  scrim: theme.callScrimColor,
                ),
        ),
      ),
    );
  }
}

/// A keyframe of a blob's drift: where it is moved to, in design pixels,
/// and how much it is scaled, at `at` of its period.
typedef _Key = ({double at, Offset shift, double scale});

/// A blob of the design's 390 × 844 frame: its centre and diameter there,
/// its blur, and how it drifts over `period` seconds.
typedef _Blob = ({
  Offset centre,
  double diameter,
  double blur,
  int period,
  List<_Key> keys,
});

const _still = <_Key>[(at: 0, shift: Offset.zero, scale: 1)];

const _voiceBlobs = <_Blob>[
  (
    centre: Offset(80, 200),
    diameter: 320,
    blur: 70,
    period: 14,
    keys: [
      (at: 0, shift: Offset.zero, scale: 1),
      (at: 0.33, shift: Offset(60, 40), scale: 1.15),
      (at: 0.66, shift: Offset(-30, 80), scale: 0.9),
      (at: 1, shift: Offset.zero, scale: 1),
    ],
  ),
  (
    centre: Offset(340, 450),
    diameter: 300,
    blur: 70,
    period: 11,
    keys: [
      (at: 0, shift: Offset.zero, scale: 1),
      (at: 0.5, shift: Offset(-70, -50), scale: 1.2),
      (at: 1, shift: Offset.zero, scale: 1),
    ],
  ),
  (
    centre: Offset(170, 774),
    diameter: 260,
    blur: 70,
    period: 9,
    keys: [
      (at: 0, shift: Offset.zero, scale: 1),
      (at: 0.5, shift: Offset(40, -70), scale: 1),
      (at: 1, shift: Offset.zero, scale: 1),
    ],
  ),
];

const _videoBlobs = <_Blob>[
  (centre: Offset(320, 210), diameter: 260, blur: 40, period: 1, keys: _still),
  (centre: Offset(60, 520), diameter: 280, blur: 50, period: 1, keys: _still),
];

/// Paints [blobs] in [colors] over [base], then [scrim]. Repaints from
/// [animation] alone, so nothing rebuilds while the blobs drift.
class _BlobPainter extends CustomPainter {
  _BlobPainter({
    required this.animation,
    required this.base,
    required this.colors,
    required this.blobs,
    required this.opacity,
    this.scrim,
  }) : super(repaint: animation);

  static const _frame = Size(390, 844);

  final Animation<double> animation;
  final Color base;
  final List<Color> colors;
  final List<_Blob> blobs;
  final double opacity;
  final Color? scrim;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final scale = size.width / _frame.width;
    final seconds = animation.value * CallBackdrop._loop.inSeconds;
    for (final (i, blob) in blobs.indexed) {
      if (i >= colors.length) {
        break;
      }
      final (:shift, scale: grow) = _pose(blob, seconds);
      final color = colors[i];
      final centre = Offset(
        (blob.centre.dx + shift.dx) * scale,
        (blob.centre.dy + shift.dy) * size.height / _frame.height,
      );
      canvas.drawCircle(
        centre,
        blob.diameter / 2 * grow * scale,
        Paint()
          ..color = color.withValues(alpha: color.a * opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blob.blur * scale),
      );
    }
    if (scrim case final scrim?) {
      canvas.drawRect(Offset.zero & size, Paint()..color = scrim);
    }
  }

  /// Where [blob] is after [seconds], easing in and out between its keys.
  static ({Offset shift, double scale}) _pose(_Blob blob, double seconds) {
    final keys = blob.keys;
    if (keys.length == 1) {
      return (shift: keys.first.shift, scale: keys.first.scale);
    }
    final t = (seconds % blob.period) / blob.period;
    var next = 1;
    while (next < keys.length - 1 && keys[next].at < t) {
      next++;
    }
    final from = keys[next - 1];
    final to = keys[next];
    final local = Curves.easeInOut.transform(
      ((t - from.at) / (to.at - from.at)).clamp(0, 1),
    );
    return (
      shift: Offset.lerp(from.shift, to.shift, local)!,
      scale: from.scale + (to.scale - from.scale) * local,
    );
  }

  @override
  bool shouldRepaint(_BlobPainter old) =>
      old.base != base ||
      old.colors != colors ||
      old.blobs != blobs ||
      old.opacity != opacity ||
      old.scrim != scrim;
}
