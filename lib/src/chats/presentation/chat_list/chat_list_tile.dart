import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_avatar.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_last_message_time.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_last_sent_ticks.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_muted_icon.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_online_dot.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_preview_line.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_unread_badge.dart';

/// One chat in the list, 76 px tall: the avatar with the online dot; the
/// name, the muted icon, the ticks of the user's own last message and the
/// time; then the preview line and the unread badge. The divider runs
/// under the text only.
///
/// Watches nothing: each part watches its own field, so a new message
/// rebuilds only the time and the unread badge.
class ChatListTile extends StatelessWidget {
  const ChatListTile({required this.topic, super.key});

  static const height = 76.0;
  static const _avatarRadius = 28.0;

  final String topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => ChatScreen.open(context, topic),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 16),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ChatAvatar(topic: topic, radius: _avatarRadius),
                  PositionedDirectional(
                    end: 1,
                    bottom: 1,
                    child: ChatOnlineDot(topic: topic),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: DefaultTextStyle.merge(
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(fontSize: 16),
                                      child: ChatTitle(topic: topic),
                                    ),
                                  ),
                                  ChatMutedIcon(topic: topic),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ChatLastSentTicks(topic: topic),
                            ChatLastMessageTime(topic: topic),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(child: ChatPreviewLine(topic: topic)),
                            const SizedBox(width: 8),
                            ChatUnreadBadge(topic: topic),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
