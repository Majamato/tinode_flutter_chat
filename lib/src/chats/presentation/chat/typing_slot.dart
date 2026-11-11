import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/message_runs.dart';
import 'package:tinode_flutter_chat/src/chats/application/typing_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_tail.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/typing_bubble.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The bottom of the message list, where the [TypingBubble] grows in while
/// someone types and shrinks away when they stop, so the messages above
/// slide rather than jump. Empty while nobody types; with Reduce motion
/// the bubble comes and goes at once, and it goes at once when the typer's
/// message arrives, which takes its place. Watches only whether anyone
/// types.
class TypingSlot extends ConsumerStatefulWidget {
  const TypingSlot({required this.topic, super.key});

  /// Its key in the message list; no client ID looks like it.
  static const listKey = '_typing';

  final String topic;

  @override
  ConsumerState<TypingSlot> createState() => _TypingSlotState();
}

class _TypingSlotState extends ConsumerState<TypingSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: ref.read(anyoneTypingProvider(widget.topic)) ? 1 : 0,
  )..addStatusListener(_onStatus);

  late final _size = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.8,
    end: 1,
  ).animate(_size);

  /// Whether the bubble is built: from the moment it starts to grow until
  /// it is gone again.
  late bool _shown = !_controller.isDismissed;

  @override
  void initState() {
    super.initState();
    ref.listenManual(anyoneTypingProvider(widget.topic), _onTyping);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = TinodeChatTheme.of(context).springDuration;
  }

  @override
  void dispose() {
    _size.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTyping(bool? _, bool typing) {
    final target = typing ? 1.0 : 0.0;
    final sent =
        !typing &&
        ref.read(typingControllerProvider(widget.topic)).endedWithMessage;
    if (sent || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = target;
    } else {
      unawaited(_controller.animateTo(target));
    }
  }

  /// Builds the bubble once it starts to show, and drops it once gone.
  void _onStatus(AnimationStatus status) {
    if (status.isDismissed == _shown) {
      setState(() => _shown = !status.isDismissed);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shown) {
      return const SizedBox.shrink();
    }
    return _GrowUp(
      height: _size,
      child: FadeTransition(
        opacity: _size,
        child: ScaleTransition(
          scale: _scale,
          alignment: AlignmentDirectional.bottomStart.resolve(
            Directionality.of(context),
          ),
          child: const TypingBubble(),
        ),
      ),
    );
  }
}

/// [child] cut, from its bottom up, to the share of its height the animation
/// gives; unlike a `SizeTransition`, the tail still shows below it.
class _GrowUp extends AnimatedWidget {
  const _GrowUp({required Animation<double> height, required this.child})
    : super(listenable: height);

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    clipper: const _AllButBelow(),
    child: Align(
      alignment: AlignmentDirectional.bottomStart,
      heightFactor: (listenable as Animation<double>).value.clamp(0, 1),
      child: child,
    ),
  );
}

/// Its box and the room the bubble's tail takes below it.
class _AllButBelow extends CustomClipper<Rect> {
  const _AllButBelow();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width, size.height + BubbleTail.overhang);

  @override
  bool shouldReclip(_AllButBelow oldClipper) => false;
}
