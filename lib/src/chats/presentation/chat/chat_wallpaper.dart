import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Behind a chat's messages: the flat wallpaper color.
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: TinodeChatTheme.of(context).wallpaperColor,
      child: const SizedBox.expand(),
    );
  }
}
