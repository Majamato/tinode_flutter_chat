import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/message_runs.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_surface.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Back to the chat list, on a glass pill, with how many messages wait
/// unread in the other chats. Watches only that count.
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
        child: GlassSurface(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: 8,
                    end: unread > 0 ? 8 : 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Icon(
                        TinodeChatIcons.of(context).back,
                        size: 22,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
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
          ),
        ),
      ),
    );
  }
}
