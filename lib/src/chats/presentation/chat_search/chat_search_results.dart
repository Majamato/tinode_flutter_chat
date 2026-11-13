import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_search.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/search_result_list.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The chats the chat search matches, most recent first, or that none
/// does. Tapping one opens it. Watches the matches.
class ChatSearchResults extends ConsumerWidget {
  const ChatSearchResults({super.key});

  void _open(BuildContext context, SearchResult chat) =>
      ChatScreen.openOverList(context, chat.topic);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(chatSearchResultsProvider);
    if (matches.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            TinodeChatStrings.of(context).noChatsFound,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }
    return SearchResultList(
      results: matches.chats,
      searching: false,
      onSelected: (chat) => _open(context, chat),
    );
  }
}
