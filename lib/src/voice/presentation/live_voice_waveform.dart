import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_waveform.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/voice_waveform.dart';

/// The waveform of a voice message as it records: one bar per level, the
/// newest on the right, older ones drifting left until they slide out of
/// the left edge. Bars are the bubble's ([VoiceWaveform.barWidth] wide,
/// [VoiceWaveform.barGap] apart, [VoiceWaveform.minBarHeight] to
/// [VoiceWaveform.maxBarHeight] tall) on a fixed scale ([liveBarOf]), so a
/// loud sample doesn't resize the others and silence shows as dots.
///
/// It starts from the [initial] levels (dBFS) and adds each one [levels]
/// brings. While [running], a ticker glides the bars between levels, one
/// bar's pitch per `voiceSampleInterval`; stopped, or with Reduce motion,
/// they step instead. Only the painter repaints. Hidden from screen
/// readers.
class LiveVoiceWaveform extends StatefulWidget {
  const LiveVoiceWaveform({
    required this.initial,
    required this.levels,
    required this.running,
    required this.color,
    super.key,
  });

  /// The most bars kept: more than any screen fits.
  static const capacity = 512;

  static const double height = VoiceWaveform.height;

  /// From one bar's left edge to the next.
  static const double pitch = VoiceWaveform.barWidth + VoiceWaveform.barGap;

  final List<double> initial;
  final Stream<double> levels;
  final bool running;
  final Color color;

  @override
  State<LiveVoiceWaveform> createState() => LiveVoiceWaveformState();
}

class LiveVoiceWaveformState extends State<LiveVoiceWaveform>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _bars = _Bars();

  /// How far the newest bar has slid in, 0..1.
  final _slide = ValueNotifier<double>(1);

  StreamSubscription<double>? _subscription;
  var _still = false;

  /// The ticker's time now, and when the newest level came.
  Duration _now = Duration.zero;
  Duration _lastAt = Duration.zero;

  /// The bars kept, 0..1 each, oldest first.
  @visibleForTesting
  List<double> get bars => List.unmodifiable(_bars.values);

  /// How far the newest bar has slid in, 0..1.
  @visibleForTesting
  double get slide => _slide.value;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final from = initial.length > LiveVoiceWaveform.capacity
        ? initial.length - LiveVoiceWaveform.capacity
        : 0;
    _bars.addAll(initial.skip(from).map(liveBarOf));
    _listen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    _run();
  }

  @override
  void didUpdateWidget(LiveVoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.levels != oldWidget.levels) {
      unawaited(_subscription?.cancel());
      _listen();
    }
    _run();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _ticker.dispose();
    _bars.dispose();
    _slide.dispose();
    super.dispose();
  }

  void _listen() {
    _subscription = widget.levels.listen(_add);
  }

  void _add(double dbfs) {
    _bars.add(liveBarOf(dbfs));
    _lastAt = _now;
    _slide.value = _ticker.isActive ? 0 : 1;
  }

  /// Glides while running and motion is allowed; steps otherwise.
  void _run() {
    final run = widget.running && !_still;
    if (run && !_ticker.isActive) {
      _now = Duration.zero;
      _lastAt = Duration.zero;
      unawaited(_ticker.start());
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
      _slide.value = 1;
    }
  }

  void _tick(Duration elapsed) {
    _now = elapsed;
    final since = (elapsed - _lastAt).inMicroseconds;
    _slide.value = (since / voiceSampleInterval.inMicroseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: double.infinity,
      height: LiveVoiceWaveform.height,
      child: CustomPaint(
        painter: _LivePainter(bars: _bars, slide: _slide, color: widget.color),
      ),
    ),
  );
}

/// The bars kept, capped at [LiveVoiceWaveform.capacity].
class _Bars extends ChangeNotifier {
  final values = <double>[];

  void add(double bar) {
    values.add(bar);
    _trim();
    notifyListeners();
  }

  void addAll(Iterable<double> bars) {
    values.addAll(bars);
    _trim();
    notifyListeners();
  }

  void _trim() {
    final over = values.length - LiveVoiceWaveform.capacity;
    if (over > 0) {
      values.removeRange(0, over);
    }
  }
}

/// The bars from the right edge leftwards, the newest [slide] of the way
/// in, clipped at the edges.
class _LivePainter extends CustomPainter {
  _LivePainter({required this.bars, required this.slide, required this.color})
    : super(repaint: Listenable.merge([bars, slide]));

  final _Bars bars;
  final ValueListenable<double> slide;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()..color = color;
    final values = bars.values;
    // The newest bar rests against the right edge once it has slid in.
    final rest = size.width - VoiceWaveform.barWidth;
    final shift = (1 - slide.value) * LiveVoiceWaveform.pitch;
    for (var k = 0; k < values.length; k++) {
      final left = rest - k * LiveVoiceWaveform.pitch + shift;
      if (left + VoiceWaveform.barWidth < 0) {
        break;
      }
      final height =
          VoiceWaveform.minBarHeight +
          (VoiceWaveform.maxBarHeight - VoiceWaveform.minBarHeight) *
              values[values.length - 1 - k];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            (size.height - height) / 2,
            VoiceWaveform.barWidth,
            height,
          ),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LivePainter old) =>
      old.bars != bars || old.slide != slide || old.color != color;
}
