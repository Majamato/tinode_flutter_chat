import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_failure_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Where the call stands, or how long it has lasted once connected, in
/// tabular figures. While the call waits, the dots of "Ringing…" pulse;
/// with Reduce motion they hold still. Watches the stage, the connect
/// time, the failure and whether the link is reconnecting; ticks every
/// second while connected.
class CallStatusText extends ConsumerStatefulWidget {
  const CallStatusText({
    this.style,
    this.showReconnecting = true,
    this.textAlign = TextAlign.center,
    super.key,
  });

  final TextStyle? style;

  /// Whether a reconnecting link replaces the timer; off where something
  /// else shows it.
  final bool showReconnecting;
  final TextAlign textAlign;

  @override
  ConsumerState<CallStatusText> createState() => _CallStatusTextState();
}

class _CallStatusTextState extends ConsumerState<CallStatusText> {
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (:stage, :connectedAt, :failure, :reconnecting) = ref.watch(
      callControllerProvider.select(
        (c) => (
          stage: c?.stage,
          connectedAt: c?.connectedAt,
          failure: c?.failure,
          reconnecting: c?.reconnecting ?? false,
        ),
      ),
    );
    _tickWhile(running: connectedAt != null && stage == CallStage.connected);
    final strings = TinodeChatStrings.of(context);
    final text = switch (stage) {
      null => '',
      CallStage.connected when reconnecting && widget.showReconnecting =>
        strings.callReconnecting,
      CallStage.preparing || CallStage.calling => strings.calling,
      CallStage.ringing => strings.ringing,
      CallStage.incoming => '',
      CallStage.connecting => strings.callConnecting,
      CallStage.connected => formatCallDuration(
        clock.now().difference(connectedAt ?? clock.now()),
      ),
      CallStage.ended =>
        failure == null
            ? strings.callEnded
            : callFailureMessage(strings, failure),
    };
    final style = (widget.style ?? const TextStyle()).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final waiting = switch (stage) {
      CallStage.preparing ||
      CallStage.calling ||
      CallStage.ringing ||
      CallStage.connecting => true,
      _ => false,
    };
    if (waiting && !MediaQuery.disableAnimationsOf(context)) {
      if (_withoutEllipsis(text) case final words?) {
        return _PulsingDots(text: words, style: style);
      }
    }
    return Text(text, style: style, textAlign: widget.textAlign);
  }

  /// [text] without its trailing ellipsis; null when it has none.
  static String? _withoutEllipsis(String text) {
    for (final ellipsis in const ['…', '...']) {
      if (text.endsWith(ellipsis)) {
        return text.substring(0, text.length - ellipsis.length);
      }
    }
    return null;
  }

  void _tickWhile({required bool running}) {
    if (running && _ticker == null) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    } else if (!running) {
      _ticker?.cancel();
      _ticker = null;
    }
  }
}

/// [text] followed by three dots that brighten in turn, every 1.2 s.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots({required this.text, required this.style});

  static const _period = Duration(milliseconds: 1200);

  /// How far behind the one before each dot pulses, in parts of a period.
  static const double _stagger = 1 / 6;

  final String text;
  final TextStyle style;

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: _PulsingDots._period,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.text}…',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.text, style: widget.style),
          for (var i = 0; i < 3; i++)
            FadeTransition(
              opacity: _controller.drive(_DotPulse(i * _PulsingDots._stagger)),
              child: Text('.', style: widget.style),
            ),
        ],
      ),
    );
  }
}

/// A dot's opacity over the period: .3, up to 1 halfway, and back.
class _DotPulse extends Animatable<double> {
  const _DotPulse(this.delay);

  final double delay;

  @override
  double transform(double t) {
    final phase = (t - delay) % 1;
    return 0.3 + 0.7 * (1 - (2 * phase - 1).abs());
  }
}
