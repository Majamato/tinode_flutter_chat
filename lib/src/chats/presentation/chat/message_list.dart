import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_list_layout.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_reveal.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_bubble.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/older_messages_indicator.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/outgoing_bubble.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/reveal_highlight.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/typing_slot.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The messages, newest at the bottom, below them those still in the
/// outbox, and the [TypingSlot]. Rebuilds only when a message is added or
/// leaves the outbox; each bubble watches its own message, the slot
/// whether anyone types, and padding changes (a bar or the keyboard)
/// rebuild only this. It scrolls under the app bar and the
/// composer, padded by their heights (the `MediaQuery` padding the
/// `Scaffold` gives it). Scrolling near the top loads older messages. A
/// message the user asked to see is scrolled to, or a snack bar says it
/// can't be shown.
class MessageList extends ConsumerStatefulWidget {
  const MessageList({required this.topic, super.key});

  final String topic;

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  /// How close to the oldest loaded message a scroll starts the next page.
  static const _loadOlderExtent = 400.0;

  /// Room between the bubbles and the sides of the screen.
  static const _sideRoom = 10.0;

  /// Room between the app bar and the top of the list.
  static const _topRoom = 4.0;

  /// Room between the newest message and the composer.
  static const _bottomRoom = 12.0;

  /// Where a revealed message lands: the middle of the list.
  static const _revealAlignment = 0.5;

  final _scroll = ScrollController();
  final _list = ListController();

  /// Each message's widget, by seq or client ID. The same instance comes
  /// back while the list rebuilds, e.g. as a message arrives, so no bubble
  /// rebuilds with it.
  final _items = <Object, Widget>{};

  late final Widget _typingSlot = TypingSlot(
    key: const ValueKey(TypingSlot.listKey),
    topic: widget.topic,
  );

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
    final index = MessageListLayout(
      outbox: chat.outgoingIds,
      seqs: chat.seqs,
    ).indexOfSeq(seq);
    if (index == null) {
      return;
    }
    _list.jumpToItem(
      index: index,
      scrollController: _scroll,
      alignment: _revealAlignment,
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
    // Reversed, so the list starts at the bottom; the layout says what
    // sits where.
    final layout = MessageListLayout(outbox: outgoing, seqs: seqs);
    final padding = MediaQuery.paddingOf(context);
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: SuperListView.builder(
        controller: _scroll,
        listController: _list,
        reverse: true,
        padding: EdgeInsets.fromLTRB(
          _sideRoom,
          padding.top + _topRoom,
          _sideRoom,
          padding.bottom + _bottomRoom,
        ),
        itemCount: layout.itemCount,
        // By key, so a bubble keeps its element as a new message shifts
        // the others.
        findChildIndexCallback: (key) => _indexOf(key, layout),
        itemBuilder: (context, index) => switch (layout.itemAt(index)) {
          TypingSlotItem() => _typingSlot,
          OutboxItem(:final clientId) => _outboxBubble(clientId),
          NumberedItem(:final seq) => _numberedBubble(seq),
          OlderMessagesItem() => OlderMessagesIndicator(topic: widget.topic),
        },
      ),
    );
  }

  /// Where the item with [key] is now, or null when it's gone.
  int? _indexOf(Key key, MessageListLayout layout) => switch (key) {
    ValueKey<String>(:final value) when value == TypingSlot.listKey =>
      MessageListLayout.typingSlot,
    ValueKey<String>(:final value) => layout.indexOfOutbox(value),
    ValueKey<int>(:final value) => layout.indexOfSeq(value),
    _ => null,
  };

  /// The bubble of the outbox message [clientId].
  Widget _outboxBubble(String clientId) => _items.putIfAbsent(
    clientId,
    () => OutgoingBubble(
      key: ValueKey(clientId),
      topic: widget.topic,
      clientId: clientId,
    ),
  );

  /// The bubble of the numbered message [seq].
  Widget _numberedBubble(int seq) => _items.putIfAbsent(
    seq,
    () => RevealHighlight(
      key: ValueKey(seq),
      topic: widget.topic,
      seq: seq,
      child: MessageBubble(topic: widget.topic, seq: seq),
    ),
  );
}
