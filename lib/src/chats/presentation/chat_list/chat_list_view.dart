import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_tile.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/row_entrance.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The list of chat tiles, scrolling under the frosted header: [topInset]
/// is its height. Rebuilds only when the order of chats changes; each tile
/// watches its own chat.
///
/// The first rows to show fade up one after the other, once per screen.
class ChatListView extends ConsumerStatefulWidget {
  const ChatListView({required this.topInset, super.key});

  /// The rows that stagger in; the rest are below the fold.
  static const staggeredRows = 12;

  /// Room under the last row for the floating button.
  static const _bottomRoom = 96.0;

  final ValueListenable<double> topInset;

  @override
  ConsumerState<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends ConsumerState<ChatListView> {
  /// Until the first rows were built: rows built later, scrolled to or
  /// new, are simply there.
  var _entering = true;

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(chatListControllerProvider.select((s) => s.order));
    if (order.isEmpty) {
      return Center(child: Text(TinodeChatStrings.of(context).noChats));
    }
    if (_entering) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _entering = false);
    }
    final entering = _entering;
    final bottom =
        MediaQuery.paddingOf(context).bottom + ChatListView._bottomRoom;
    return ValueListenableBuilder(
      valueListenable: widget.topInset,
      builder: (context, top, _) => MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: ListView.builder(
          padding: EdgeInsets.only(top: top, bottom: bottom),
          itemExtent: ChatListTile.height,
          itemCount: order.length,
          itemBuilder: (context, index) => RowEntrance(
            key: ValueKey(order[index]),
            animate: entering && index < ChatListView.staggeredRows,
            delay: RowEntrance.stagger * index,
            child: ChatListTile(topic: order[index]),
          ),
        ),
      ),
    );
  }
}
