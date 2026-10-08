import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The shape every message shares: own messages on the right, others on
/// the left, the [body] above a [footer] with the time and status.
class BubbleFrame extends StatelessWidget {
  const BubbleFrame({
    required this.own,
    required this.body,
    required this.footer,
    this.onLongPress,
    super.key,
  });

  /// Bubbles take at most this share of the list's width.
  static const _maxWidthFactor = 0.78;

  final bool own;
  final Widget body;
  final Widget footer;

  /// Opens the message's actions.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * _maxWidthFactor,
        ),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            decoration: BoxDecoration(
              color: own ? theme.ownBubbleColor : theme.peerBubbleColor,
              borderRadius: BorderRadius.circular(theme.bubbleRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [body, const SizedBox(height: 2), footer],
            ),
          ),
        ),
      ),
    );
  }
}
