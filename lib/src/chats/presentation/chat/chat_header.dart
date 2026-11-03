import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_back_button.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_header_actions.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_status.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_info/chat_info_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_avatar.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_surface.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';

/// The glass app bar over a chat: back (with the other chats' unread
/// count), a pill with the chat's photo, name and status (typing, online)
/// that opens the chat's info, then message search and the call buttons on
/// one island, over a fade of the wallpaper. Watches nothing itself.
class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  const ChatHeader({required this.topic, super.key});

  final String topic;

  @override
  Size get preferredSize => const TinodeAppBar().preferredSize;

  @override
  Widget build(BuildContext context) {
    return TinodeAppBar(
      fadeColor: TinodeChatTheme.of(context).wallpaperColor,
      centerTitle: false,
      titleOnGlass: true,
      leading: ChatBackButton(topic: topic),
      title: _TitlePill(topic: topic),
      actions: [ChatHeaderActions(topic: topic)],
    );
  }
}

/// The chat's photo, then its name over its status, on glass, as wide as
/// they need.
class _TitlePill extends StatelessWidget {
  const _TitlePill({required this.topic});

  /// 34 px across, 5 px inside the 44 px pill.
  static const _avatarRadius = 17.0;

  final String topic;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: GlassSurface(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => ChatInfoScreen.open(context, topic),
            child: Padding(
              // The photo sits concentric in the pill's round end.
              padding: const EdgeInsetsDirectional.only(start: 5, end: 14),
              child: SizedBox(
                height: TinodeAppBar.rowHeight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    ExcludeSemantics(
                      child: ChatAvatar(topic: topic, radius: _avatarRadius),
                    ),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultTextStyle.merge(
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 15,
                              height: 1.2,
                            ),
                            child: ChatTitle(topic: topic),
                          ),
                          ChatStatus(topic: topic),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
