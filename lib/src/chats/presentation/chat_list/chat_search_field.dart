import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_search/chat_search_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/search_pill.dart';

/// The search pill under the chat list's app bar, which opens the chat
/// search. Watches nothing.
class ChatSearchField extends StatelessWidget implements PreferredSizeWidget {
  const ChatSearchField({super.key});

  /// Its height.
  static const double height = SearchPill.height;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  void _open(BuildContext context) => ChatSearchScreen.open(context);

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    return SearchPill(
      label: strings.searchChats,
      semanticsLabel: strings.chatSearchHint,
      onTap: () => _open(context),
    );
  }
}
