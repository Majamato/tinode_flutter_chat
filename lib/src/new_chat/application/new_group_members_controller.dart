import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/picked_members.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';

part 'new_group_members_controller.g.dart';

/// The people picked for a new group, shared by its two screens: picked on
/// the add members screen, and removable on both. Lives while the add
/// members screen does.
@riverpod
class NewGroupMembersController extends _$NewGroupMembersController {
  @override
  PickedMembers build() => const PickedMembers();

  /// Picks [member], or unpicks them when picked.
  void toggle(SearchResult member) => state = state.toggled(member);
}
