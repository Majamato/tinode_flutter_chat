import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/new_group_members_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/pick_mark.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/profile_avatar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// A person who can be picked for the new group, as one row of a card:
/// avatar, name and [PickMark]. A tap picks or unpicks them. The [first]
/// and [last] rows round the card's corners; a divider runs under the
/// text of every other row. Watches nothing; the mark watches the pick.
class PickableMemberTile extends ConsumerWidget {
  const PickableMemberTile({
    required this.result,
    this.first = false,
    this.last = false,
    super.key,
  });

  /// Every row's height.
  static const height = 64.0;

  final SearchResult result;
  final bool first;
  final bool last;

  void _toggle(WidgetRef ref) =>
      ref.read(newGroupMembersControllerProvider.notifier).toggle(result);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final chat = TinodeChatTheme.of(context);
    final corner = Radius.circular(chat.cardRadius);
    return Material(
      color: chat.cardColor,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.vertical(
        top: first ? corner : Radius.zero,
        bottom: last ? corner : Radius.zero,
      ),
      child: InkWell(
        onTap: () => _toggle(ref),
        child: MergeSemantics(
          child: SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(width: 16),
                Center(
                  child: ProfileAvatar(
                    initials: result.initials,
                    photo: result.photo,
                    radius: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: last
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            result.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        PickMark(topic: result.topic),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
