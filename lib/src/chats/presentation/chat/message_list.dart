import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_reveal.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_bubble.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/older_messages_indicator.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/outgoing_bubble.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/reveal_highlight.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The messages, newest at the bottom, below them those still in the
/// outbox. Rebuilds only when a message is added or leaves the outbox;
/// each bubble watches its own message. Scrolling near the top loads older
/// messages. A message the user asked to see is scrolled to, or a snack bar
/// says it can't be shown.
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
  final _list = ListController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // At once too: a reveal may be done before the list first shows.
    ref.listenManual(
      chatControllerProvider(widget.topic).select((s) => s.reveal),
      (_, reveal) => _onReveal(reveal),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _list.dispose();
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

  void _onReveal(MessageReveal? reveal) {
    switch (reveal) {
      case MessageReveal(status: RevealStatus.shown, :final seq):
        // After the frame that builds the messages loaded for it.
        WidgetsBinding.instance
          ..addPostFrameCallback((_) => _jumpTo(seq))
          ..ensureVisualUpdate();
      case MessageReveal(status: RevealStatus.unavailable):
        // Also when called from initState, where the scaffold can't be
        // looked up yet.
        WidgetsBinding.instance
          ..addPostFrameCallback((_) => _sayUnavailable())
          ..ensureVisualUpdate();
      case _:
        break;
    }
  }

  void _sayUnavailable() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TinodeChatStrings.of(context).messageUnavailable),
        ),
      );
    }
  }

  void _jumpTo(int seq) {
    if (!mounted || !_list.isAttached || !_scroll.hasClients) {
      return;
    }
    final chat = ref.read(chatControllerProvider(widget.topic));
    final position = binarySearch(chat.seqs, seq);
    if (position < 0) {
      return;
    }
    _list.jumpToItem(
      index: chat.outgoingIds.length + chat.seqs.length - 1 - position,
      scrollController: _scroll,
      alignment: 0.5,
    );
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
    return SuperListView.builder(
      controller: _scroll,
      listController: _list,
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
        return RevealHighlight(
          key: ValueKey(seq),
          topic: widget.topic,
          seq: seq,
          child: MessageBubble(topic: widget.topic, seq: seq),
        );
      },
    );
  }
}
