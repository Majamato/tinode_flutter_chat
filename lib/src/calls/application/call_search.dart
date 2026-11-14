import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_matches.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_matches.dart';

part 'call_search.g.dart';

/// What the user typed in the call search field, as typed.
@riverpod
class CallSearchFilter extends _$CallSearchFilter {
  @override
  String build() => '';

  // A setter would hide that this filters the calls.
  // ignore: use_setters_to_change_properties
  void change(String input) => state = input;
}

/// The calls of the history whose chat's name matches [CallSearchFilter];
/// see [CallMatches].
@riverpod
CallMatches callSearchResults(Ref ref) {
  final ids = ref.watch(callHistoryControllerProvider.select((h) => h.ids));
  final chats = ref.watch(
    chatListControllerProvider.select(ChatMatches.fromChatList),
  );
  return CallMatches.matching(ids, {
    for (final chat in chats.chats) chat.topic: chat.title,
  }, ref.watch(callSearchFilterProvider));
}
