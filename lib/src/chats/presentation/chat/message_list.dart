import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_bubble.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/older_messages_indicator.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/outgoing_bubble.dart';

/// The messages, newest at the bottom, below them those still in the
/// outbox. Rebuilds only when a message is added or leaves the outbox;
/// each bubble watches its own message. Scrolling near the top loads older
/// messages.
class MessageList extends ConsumerStatefulWidget {
  const MessageList({required this.topic, super.key});

  final String topic;

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  /// How close to the oldest loaded message a scroll starts the next page.
  static const _loadOlderExtent = 400.0;

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < _loadOlderExtent) {
      unawaited(
        ref.read(chatControllerProvider(widget.topic).notifier).loadOlder(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final seqs = ref.watch(
      chatControllerProvider(widget.topic).select((s) => s.seqs),
    );
    final outgoing = ref.watch(
      chatControllerProvider(widget.topic).select((s) => s.outgoingIds),
    );
    // Reversed, so index 0 is the newest message and the list starts at
    // the bottom: first the outbox, then the numbered messages, and last
    // the indicator for older messages.
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: outgoing.length + seqs.length + 1,
      itemBuilder: (context, index) {
        if (index < outgoing.length) {
          final id = outgoing[outgoing.length - 1 - index];
          return OutgoingBubble(
            key: ValueKey(id),
            topic: widget.topic,
            clientId: id,
          );
        }
        final numbered = index - outgoing.length;
        if (numbered == seqs.length) {
          return OlderMessagesIndicator(topic: widget.topic);
        }
        final seq = seqs[seqs.length - 1 - numbered];
        return MessageBubble(key: ValueKey(seq), topic: widget.topic, seq: seq);
      },
    );
  }
}
