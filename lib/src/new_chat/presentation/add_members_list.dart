import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/member_search_section.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/picked_members_card.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/suggested_members_section.dart';

/// The add members screen's content, scrolling under its bars: the picked
/// members, the suggested ones, then those the server found. Watches
/// nothing.
class AddMembersList extends StatelessWidget {
  const AddMembersList({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              padding.left + 16,
              padding.top + 16,
              padding.right + 16,
              padding.bottom + 24,
            ),
            sliver: const SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(child: PickedMembersCard()),
                SuggestedMembersSection(),
                MemberSearchSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
