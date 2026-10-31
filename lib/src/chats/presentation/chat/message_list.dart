import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/message_runs.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_reveal.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_bubble.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/older_messages_indicator.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/outgoing_bubble.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/reveal_highlight.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/typing_bubble.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The messages, newest at the bottom, below them those still in the
/// outbox, and the typing bubble while someone types. Rebuilds only when a
/// message is added or leaves the outbox, or typing starts or stops; each
/// bubble watches its own message. It scrolls under the composer:
/// [bottomInset] is the composer's height. Scrolling near the
/// top loads older messages. A message the user asked to see is scrolled
/// to, or a snack bar says it can't be shown.
class MessageList extends ConsumerStatefulWidget {
  const MessageList({
    required this.topic,
    required this.bottomInset,
    super.key,
  });

  final String topic;
  final ValueListenable<double> bottomInset;

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  /// How close to the oldest loaded message a scroll starts the next page.
  static const _loadOlderExtent = 400.0;

  final _scroll = ScrollController();
  final _list = ListController();

  /// Each message's widget, by seq or client ID. The same instance comes
  /// back while the list rebuilds, e.g. as typing starts, so no bubble
  /// rebuilds with it.
  final _items = <Object, Widget>{};

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
    final typing = ref.read(anyoneTypingProvider(widget.topic)) ? 1 : 0;
    _list.jumpToItem(
      index: typing + chat.outgoingIds.length + chat.seqs.length - 1 - position,
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
    final typing = ref.watch(anyoneTypingProvider(widget.topic)) ? 1 : 0;
    // Reversed, so index 0 is the newest message and the list starts at
    // the bottom: the typing bubble, the outbox, then the numbered
    // messages, and last the indicator for older messages.
    return ValueListenableBuilder(
      valueListenable: widget.bottomInset,
      builder: (context, bottom, _) => MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: SuperListView.builder(
          controller: _scroll,
          listController: _list,
          reverse: true,
          padding: EdgeInsets.fromLTRB(10, 4, 10, bottom + 12),
          itemCount: typing + outgoing.length + seqs.length + 1,
          // By key, so a bubble keeps its element as the typing bubble or a
          // new message shifts the others.
          findChildIndexCallback: (key) =>
              _indexOf(key, typing, outgoing, seqs),
          itemBuilder: (context, position) {
            if (position < typing) {
              return const TypingBubble(key: ValueKey(TypingBubble.listKey));
            }
            return _item(position - typing, outgoing, seqs);
          },
        ),
      ),
    );
  }

  /// Where the item with [key] is now, or null when it's gone.
  int? _indexOf(Key key, int typing, List<String> outgoing, List<int> seqs) {
    switch (key) {
      case ValueKey<String>(:final value) when value == TypingBubble.listKey:
        return typing > 0 ? 0 : null;
      case ValueKey<String>(:final value):
        final index = outgoing.indexOf(value);
        return index < 0 ? null : typing + outgoing.length - 1 - index;
      case ValueKey<int>(:final value):
        final index = binarySearch(seqs, value);
        return index < 0
            ? null
            : typing + outgoing.length + seqs.length - 1 - index;
    }
    return null;
  }

  /// The message at [index] counted from the newest: the outbox first,
  /// then the numbered messages, last the indicator for older ones.
  Widget _item(int index, List<String> outgoing, List<int> seqs) {
    if (index < outgoing.length) {
      final id = outgoing[outgoing.length - 1 - index];
      return _items.putIfAbsent(
        id,
        () => OutgoingBubble(
          key: ValueKey(id),
          topic: widget.topic,
          clientId: id,
        ),
      );
    }
    final numbered = index - outgoing.length;
    if (numbered == seqs.length) {
      return OlderMessagesIndicator(topic: widget.topic);
    }
    final seq = seqs[seqs.length - 1 - numbered];
    return _items.putIfAbsent(
      seq,
      () => RevealHighlight(
        key: ValueKey(seq),
        topic: widget.topic,
        seq: seq,
        child: MessageBubble(topic: widget.topic, seq: seq),
      ),
    );
  }
}
