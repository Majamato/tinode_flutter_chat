import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/find_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/member_search_state.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/member_suggestions.dart';

part 'member_search.g.dart';

/// What the user typed in the add members field, as typed.
@riverpod
class MemberFilter extends _$MemberFilter {
  @override
  String build() => '';

  // A setter would hide that this filters the suggestions.
  // ignore: use_setters_to_change_properties
  void change(String input) => state = input;
}

/// The suggested members whose name matches [MemberFilter]; see
/// [MemberSuggestions].
@riverpod
MemberSuggestions memberSuggestions(Ref ref) {
  final all = ref.watch(
    chatListControllerProvider.select(MemberSuggestions.fromChatList),
  );
  return all.matching(ref.watch(memberFilterProvider));
}

/// The server's search for members, without the people
/// [memberSuggestionsProvider] shows.
@riverpod
MemberSearchState memberSearch(Ref ref) => MemberSearchState.of(
  ref.watch(findControllerProvider(FindScope.groupMembers)),
  ref.watch(memberSuggestionsProvider),
);
