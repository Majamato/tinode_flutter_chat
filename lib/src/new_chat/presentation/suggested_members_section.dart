import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/member_search.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/member_list_message.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/pickable_member_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_label.dart';

/// The people suggested as members (the user's direct chats) whose name
/// matches the filter, as a card under its heading. A sliver. With no
/// direct chats at all, a line saying how to find people. Watches the
/// suggestions.
class SuggestedMembersSection extends ConsumerWidget {
  const SuggestedMembersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(memberSuggestionsProvider).people;
    final strings = TinodeChatStrings.of(context);
    if (people.isEmpty) {
      final filtering = ref.watch(
        memberFilterProvider.select((input) => input.trim().isNotEmpty),
      );
      return SliverToBoxAdapter(
        child: filtering ? null : MemberListMessage(strings.findHint),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.only(top: 22),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(child: SettingsLabel(strings.suggestedMembers)),
          SliverList.builder(
            itemCount: people.length,
            itemBuilder: (context, index) => PickableMemberTile(
              key: ValueKey(people[index].topic),
              result: people[index],
              first: index == 0,
              last: index == people.length - 1,
            ),
          ),
        ],
      ),
    );
  }
}
