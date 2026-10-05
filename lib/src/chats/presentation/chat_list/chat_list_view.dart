import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The list of chat tiles. Rebuilds only when the order of chats changes;
/// each tile watches its own chat.
class ChatListView extends ConsumerWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(chatListControllerProvider.select((s) => s.order));
    if (order.isEmpty) {
      return Center(child: Text(TinodeChatStrings.of(context).noChats));
    }
    return ListView.builder(
      itemCount: order.length,
      itemBuilder: (context, index) =>
          ChatListTile(key: ValueKey(order[index]), topic: order[index]),
    );
  }
}
