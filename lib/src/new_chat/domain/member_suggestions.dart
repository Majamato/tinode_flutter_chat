import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_list_state.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/name_match.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// The people suggested as members of a new group: the other users of the
/// user's direct chats, most recent chat first.
///
/// Compares by value, so a chat list change that touches no direct chat's
/// name or photo (a message, a read marker, presence) changes nothing.
final class MemberSuggestions with ValueObject {
  const MemberSuggestions([this.people = const []]);

  factory MemberSuggestions.fromChatList(ChatListState list) =>
      MemberSuggestions(
        List.unmodifiable([
          for (final topic in list.order)
            if (list.byTopic[topic] case final chat?
                when chat.kind == TopicKind.direct)
              SearchResult.fromChat(chat),
        ]),
      );

  final List<SearchResult> people;

  bool get isEmpty => people.isEmpty;

  /// Whether the person named [topic] is suggested.
  bool has(String topic) => people.any((p) => p.topic == topic);

  /// Those whose name matches [input]; see [nameMatches].
  MemberSuggestions matching(String input) {
    final matched = [
      for (final person in people)
        if (nameMatches(person.title, input)) person,
    ];
    return matched.length == people.length
        ? this
        : MemberSuggestions(List.unmodifiable(matched));
  }

  @override
  List<Object?> get props => [people];
}
