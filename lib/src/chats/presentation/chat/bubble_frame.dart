import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_tail.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The shape every message shares: own messages on the right, others on
/// the left, the [body] above an optional [footer] with the time and
/// status, and optionally a [header] above both, e.g. the sender's name.
/// The last bubble of a run has a [tail].
class BubbleFrame extends StatelessWidget {
  const BubbleFrame({
    required this.own,
    required this.body,
    this.footer,
    this.header,
    this.tail = false,
    this.padding = textPadding,
    this.onLongPress,
    super.key,
  });

  /// Around text.
  static const textPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 7);

  /// Around a file or a call.
  static const tilePadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

  /// Around a photo. The bubble's corners then follow the photo's, this
  /// much further out.
  static const photoPadding = EdgeInsets.all(4);

  /// Bubbles take at most this share of the list's width.
  static const _maxWidthFactor = 0.78;

  final bool own;
  final Widget body;

  /// The time and status below [body]; null when [body] carries them.
  final Widget? footer;
  final Widget? header;

  /// Whether the bubble has its tail: it ends a run and the theme has
  /// tails.
  final bool tail;
  final EdgeInsets padding;

  /// Opens the message's actions.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    final color = own ? theme.ownBubbleColor : theme.peerBubbleColor;
    // Around a photo, an even rim: the photo's radius plus the padding.
    final radius = padding == photoPadding
        ? theme.photoRadius + photoPadding.top
        : theme.bubbleRadius;
    final footer = this.footer;
    Widget bubble = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: switch (header) {
        null when footer == null => body,
        null => Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [body, const SizedBox(height: 2), footer!],
        ),
        // As wide as the widest part, the header at the start and
        // the footer at the end.
        final header => IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              body,
              if (footer != null) ...[
                const SizedBox(height: 2),
                Align(alignment: AlignmentDirectional.centerEnd, child: footer),
              ],
            ],
          ),
        ),
      },
    );
    if (tail && theme.bubbleTail) {
      bubble = Stack(
        clipBehavior: Clip.none,
        children: [
          bubble,
          PositionedDirectional(
            start: own ? null : 0,
            end: own ? 0 : null,
            bottom: -BubbleTail.overhang,
            child: BubbleTail(color: color, own: own),
          ),
        ],
      );
    }
    return Align(
      alignment: own
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * _maxWidthFactor,
        ),
        child: GestureDetector(onLongPress: onLongPress, child: bubble),
      ),
    );
  }
}
