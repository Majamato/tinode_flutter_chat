import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/new_group_members_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/profile_avatar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The people picked for the new group, on a card: each a photo with a
/// small x and the name under it; a tap unpicks them. In one row that
/// scrolls sideways, or, when [wrap], in as many rows as they take. Grows
/// and shrinks on the spring, and takes no room while nobody is picked.
/// Watches the picked members.
class PickedMembersCard extends ConsumerWidget {
  const PickedMembersCard({this.wrap = false, super.key});

  final bool wrap;

  void _remove(WidgetRef ref, SearchResult member) =>
      ref.read(newGroupMembersControllerProvider.notifier).toggle(member);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(
      newGroupMembersControllerProvider.select((m) => m.members),
    );
    final chat = TinodeChatTheme.of(context);
    final avatars = [
      for (final member in members)
        _PickedAvatar(
          key: ValueKey(member.topic),
          member: member,
          onRemove: () => _remove(ref, member),
        ),
    ];
    final card = members.isEmpty
        ? const SizedBox(width: double.infinity)
        : DecoratedBox(
            decoration: BoxDecoration(
              color: chat.cardColor,
              borderRadius: BorderRadius.circular(chat.cardRadius),
            ),
            child: wrap
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: avatars,
                      ),
                    ),
                  )
                : SizedBox(
                    height: _PickedAvatar.height + 28,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(14),
                      children: avatars,
                    ),
                  ),
          );
    if (MediaQuery.disableAnimationsOf(context)) {
      return card;
    }
    return AnimatedSize(
      duration: chat.springDuration,
      curve: chat.springCurve,
      alignment: Alignment.topCenter,
      child: card,
    );
  }
}

class _PickedAvatar extends StatelessWidget {
  const _PickedAvatar({
    required this.member,
    required this.onRemove,
    super.key,
  });

  static const width = 68.0;
  static const height = 84.0;

  final SearchResult member;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = TinodeChatStrings.of(context).removePicked(member.title);
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: width,
            height: height,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ProfileAvatar(
                      initials: member.initials,
                      photo: member.photo,
                      radius: 28,
                    ),
                    PositionedDirectional(
                      top: -2,
                      end: -4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.onSurfaceVariant,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: TinodeChatTheme.of(context).cardColor,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            TinodeChatIcons.of(context).close,
                            size: ChatIconSize.tiny,
                            color: colors.surface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  member.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
