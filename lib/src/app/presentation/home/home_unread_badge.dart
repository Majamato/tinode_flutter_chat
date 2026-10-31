import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/message_runs.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The chats tab's count of unread messages in chats that aren't muted,
/// on an 18 px pill; nothing when none. Watches only that count.
class HomeUnreadBadge extends ConsumerWidget {
  const HomeUnreadBadge({super.key});

  static const _height = 18.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(totalUnreadProvider);
    if (unread == 0) {
      return const SizedBox.shrink();
    }
    final theme = TinodeChatTheme.of(context);
    return Semantics(
      label: TinodeChatStrings.of(context).unreadCount(unread),
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minWidth: _height),
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: theme.unreadBadgeColor,
          ),
          child: Text(
            unread > 99 ? '99+' : '$unread',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: theme.onUnreadBadgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
