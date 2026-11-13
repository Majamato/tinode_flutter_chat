import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_matches.dart';

part 'chat_search.g.dart';

/// What the user typed in the chat search field, as typed.
@riverpod
class ChatSearchFilter extends _$ChatSearchFilter {
  @override
  String build() => '';

  // A setter would hide that this filters the chats.
  // ignore: use_setters_to_change_properties
  void change(String input) => state = input;
}

/// The user's chats whose name matches [ChatSearchFilter]; see
/// [ChatMatches].
@riverpod
ChatMatches chatSearchResults(Ref ref) {
  final all = ref.watch(
    chatListControllerProvider.select(ChatMatches.fromChatList),
  );
  return all.matching(ref.watch(chatSearchFilterProvider));
}
