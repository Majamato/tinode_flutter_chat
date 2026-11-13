import 'package:tinode_flutter_chat/src/chats/domain/chat_list_state.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/name_match.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// What the chat search shows: the user's chats, direct and groups, most
/// recent first.
///
/// Compares by value, so a chat list change that touches no chat's place,
/// name or photo (a read marker, presence) changes nothing.
final class ChatMatches with ValueObject {
  const ChatMatches([this.chats = const []]);

  factory ChatMatches.fromChatList(ChatListState list) => ChatMatches(
    List.unmodifiable([
      for (final topic in list.order)
        if (list.byTopic[topic] case final chat?) SearchResult.fromChat(chat),
    ]),
  );

  final List<SearchResult> chats;

  bool get isEmpty => chats.isEmpty;

  /// Those whose name matches [input]; see [nameMatches].
  ChatMatches matching(String input) {
    final matched = [
      for (final chat in chats)
        if (nameMatches(chat.title, input)) chat,
    ];
    return matched.length == chats.length
        ? this
        : ChatMatches(List.unmodifiable(matched));
  }

  @override
  List<Object?> get props => [chats];
}
