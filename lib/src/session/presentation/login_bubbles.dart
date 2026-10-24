import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_tail.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The bubbles floating over the login screen's top: an incoming hello,
/// an outgoing reply, a tiny voice note and an accent dot, each drifting
/// 12 px up and down over 5 to 7 s. Decoration only: hidden from screen
/// readers, and still with Reduce motion.
class LoginBubbles extends StatefulWidget {
  const LoginBubbles({super.key});

  /// One loop of the controller: every bubble's period divides it.
  static const _loop = Duration(seconds: 210);

  @override
  State<LoginBubbles> createState() => _LoginBubblesState();
}

class _LoginBubblesState extends State<LoginBubbles>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: LoginBubbles._loop,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
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
    final strings = TinodeChatStrings.of(context);
    final chat = TinodeChatTheme.of(context);
    final colors = Theme.of(context).colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    return ExcludeSemantics(
      child: Stack(
        children: [
          _Drift(
            animation: _controller,
            period: 5,
            phase: 0,
            start: 26,
            top: top + 38,
            child: _Bubble(
              color: chat.peerBubbleColor,
              own: false,
              child: Text(
                strings.loginBubbleHello,
                style: TextStyle(color: chat.onPeerBubbleColor, fontSize: 14),
              ),
            ),
          ),
          _Drift(
            animation: _controller,
            period: 6,
            phase: 2,
            end: 24,
            top: top + 16,
            child: _Bubble(
              color: chat.ownBubbleColor,
              own: true,
              child: Text(
                strings.loginBubbleLater,
                style: TextStyle(color: chat.onOwnBubbleColor, fontSize: 14),
              ),
            ),
          ),
          _Drift(
            animation: _controller,
            period: 7,
            phase: 4,
            start: 48,
            top: top + 208,
            child: _Bubble(
              color: chat.peerBubbleColor,
              own: false,
              child: _VoiceNote(
                played: colors.primary,
                unplayed: chat.waveOffColor,
                meta: chat.peerMetaColor,
              ),
            ),
          ),
          _Drift(
            animation: _controller,
            period: 5,
            phase: 0,
            end: 40,
            top: top + 184,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.tertiary.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [child] at its place, moving 12 px up and back once per [period]
/// seconds, [phase] seconds ahead.
class _Drift extends StatelessWidget {
  const _Drift({
    required this.animation,
    required this.period,
    required this.phase,
    required this.top,
    required this.child,
    this.start,
    this.end,
  });

  final Animation<double> animation;
  final int period;
  final int phase;
  final double top;
  final double? start;
  final double? end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loop = LoginBubbles._loop.inSeconds;
    return PositionedDirectional(
      start: start,
      end: end,
      top: top,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = animation.value * loop + phase;
          final rise = (1 - math.cos(2 * math.pi * t / period)) / 2;
          return Transform.translate(
            offset: Offset(0, -12 * rise),
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}

/// A small bubble with its tail and a soft shadow.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.color, required this.own, required this.child});

  final Color color;
  final bool own;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: -12,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
        PositionedDirectional(
          start: own ? null : 0,
          end: own ? 0 : null,
          bottom: -BubbleTail.overhang,
          child: BubbleTail(color: color, own: own),
        ),
      ],
    );
  }
}

/// A play button, six waveform bars and a duration.
class _VoiceNote extends StatelessWidget {
  const _VoiceNote({
    required this.played,
    required this.unplayed,
    required this.meta,
  });

  static const _bars = [8.0, 14.0, 10.0, 16.0, 9.0, 12.0];

  final Color played;
  final Color unplayed;
  final Color meta;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(shape: BoxShape.circle, color: played),
          child: Icon(
            Icons.play_arrow_rounded,
            size: 14,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(width: 8),
        for (final (i, height) in _bars.indexed) ...[
          if (i > 0) const SizedBox(width: 2),
          Container(
            width: 3,
            height: height,
            decoration: BoxDecoration(
              color: i < 3 ? played : unplayed,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
        const SizedBox(width: 8),
        Text('0:08', style: TextStyle(color: meta, fontSize: 12)),
      ],
    );
  }
}
