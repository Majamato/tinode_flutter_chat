import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_avatar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The peer of a call, big: [topic]'s avatar in a translucent ring. It
/// pops in once; while [rings] is set, three rings pulse out of it, every
/// 2.2 s, staggered .75 s. With Reduce motion it only fades in, without
/// rings. The rings are hidden from screen readers.
class CallAvatar extends StatefulWidget {
  const CallAvatar({
    required this.topic,
    this.size = 148,
    this.rings = false,
    super.key,
  });

  static const _pulse = Duration(milliseconds: 2200);
  static const _stagger = Duration(milliseconds: 750);
  static const _pop = Duration(milliseconds: 600);

  final String topic;
  final double size;
  final bool rings;

  @override
  State<CallAvatar> createState() => _CallAvatarState();
}

class _CallAvatarState extends State<CallAvatar> with TickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: CallAvatar._pulse,
  );
  late final _pop = AnimationController(vsync: this, duration: CallAvatar._pop);
  late final _fade = CurvedAnimation(
    parent: _pop,
    curve: const Interval(0, 0.7),
  );
  CurvedAnimation? _grow;
  var _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    _grow?.dispose();
    _grow = CurvedAnimation(
      parent: _pop,
      curve: TinodeChatTheme.of(context).springCurve,
    );
    if (_pop.isDismissed) {
      unawaited(_pop.forward());
    }
    _pulseWhile(on: widget.rings);
  }

  @override
  void didUpdateWidget(CallAvatar old) {
    super.didUpdateWidget(old);
    _pulseWhile(on: widget.rings);
  }

  void _pulseWhile({required bool on}) {
    if (on && !_still) {
      if (!_pulse.isAnimating) {
        unawaited(_pulse.repeat());
      }
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _grow?.dispose();
    _fade.dispose();
    _pop.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    final grow = _grow!;
    final avatar = Container(
      width: widget.size,
      height: widget.size,
      padding: EdgeInsets.all(widget.size >= 96 ? 4 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.callOutlineColor,
      ),
      child: _PeerAvatar(topic: widget.topic),
    );
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: grow,
        builder: (context, child) => Transform.scale(
          scale: _still ? 1 : 0.7 + 0.3 * grow.value,
          child: child,
        ),
        child: CustomPaint(
          // Still rings would read as halos: none with Reduce motion.
          painter: widget.rings && !_still
              ? _RingsPainter(animation: _pulse, color: theme.onCallColor)
              : null,
          child: avatar,
        ),
      ),
    );
  }
}

/// [topic]'s avatar filling its space, its initials big and white on the
/// palette's primary.
class _PeerAvatar extends StatelessWidget {
  const _PeerAvatar({required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat = TinodeChatTheme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primaryContainer: chat.callBlobColors.first.withValues(alpha: 1),
          onPrimaryContainer: chat.onCallColor,
        ),
      ),
      // The avatar's initials grow with it.
      child: FittedBox(child: ChatAvatar(topic: topic)),
    );
  }
}

/// Discs swelling out of the avatar and fading, one every .75 s.
class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.animation, required this.color})
    : super(repaint: animation);

  static const _count = 3;

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stagger =
        CallAvatar._stagger.inMicroseconds / CallAvatar._pulse.inMicroseconds;
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    for (var i = 0; i < _count; i++) {
      final t = Curves.easeOut.transform((animation.value + i * stagger) % 1);
      canvas.drawCircle(
        centre,
        radius * (1 + 0.9 * t),
        Paint()..color = color.withValues(alpha: 0.35 * (1 - t)),
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.color != color;
}
