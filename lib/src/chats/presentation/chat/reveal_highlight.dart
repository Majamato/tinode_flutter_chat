import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// A band behind the message the user asked to see, e.g. from message
/// search, that fades in and out. Rebuilds only when that message changes.
class RevealHighlight extends ConsumerWidget {
  const RevealHighlight({
    required this.topic,
    required this.seq,
    required this.child,
    super.key,
  });

  static const _fade = Duration(milliseconds: 300);

  final String topic;
  final int seq;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revealed = ref.watch(messageRevealedProvider(topic, seq));
    return AnimatedContainer(
      duration: _fade,
      color: revealed
          ? TinodeChatTheme.of(context).revealedMessageColor
          : Colors.transparent,
      child: child,
    );
  }
}
