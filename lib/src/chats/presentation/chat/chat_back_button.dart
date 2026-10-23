import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/message_runs.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Back to the chat list, with how many messages wait unread in the other
/// chats. Watches only that count.
class ChatBackButton extends ConsumerWidget {
  const ChatBackButton({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(otherUnreadProvider(topic));
    final theme = TinodeChatTheme.of(context);
    final label = TinodeChatStrings.of(context).backToChats;

    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: () => Navigator.of(context).maybePop(),
          radius: 24,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios_new_rounded, color: theme.linkColor),
                if (unread > 0)
                  DecoratedBox(
                    decoration: ShapeDecoration(
                      color: theme.unreadBadgeColor,
                      shape: const StadiumBorder(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1,
                      ),
                      child: Text(
                        '$unread',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: theme.onUnreadBadgeColor,
                              letterSpacing: 0,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
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
