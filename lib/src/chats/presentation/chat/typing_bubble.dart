import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_frame.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_text_layout.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/typing_slot.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Someone else's bubble with three bouncing dots, in the [TypingSlot] at
/// the bottom of the chat while someone types. As tall as a one-line text
/// message, so nothing jumps when the message replaces it. The dots stand
/// still with the OS's Reduce motion. Decoration: the header says who types.
class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  static const _period = Duration(milliseconds: 1200);

  /// The delay between dots, as a share of [_period].
  static const double _stagger = 150 / 1200;
  static const _dot = 8.0;
  static const _lift = 4.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
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

  /// How high dot [index] is at [t]: one hop in the first half of its
  /// cycle, then rest.
  static double _height(double t, int index) {
    final phase = (t - index * _stagger) % 1;
    return phase < 0.5
        ? Curves.easeInOut.transform(1 - (phase * 4 - 1).abs())
        : 0;
  }

  @override
  Widget build(BuildContext context) {
    final color = TinodeChatTheme.of(context).peerMetaColor;
    return Padding(
      padding: EdgeInsets.only(top: TinodeChatTheme.of(context).newRunGap),
      child: ExcludeSemantics(
        child: BubbleFrame(
          own: false,
          tail: true,
          body: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  bottom: RenderBubbleTextLayout.drop,
                ),
                child: Text('', style: Theme.of(context).textTheme.bodyLarge),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            -_lift * _height(_controller.value, i),
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox.square(dimension: _dot),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
