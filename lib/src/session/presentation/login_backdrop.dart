import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_bubbles.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Behind the login sheet: the wallpaper colour and the floating bubbles.
/// Watches nothing.
class LoginBackdrop extends StatelessWidget {
  const LoginBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: theme.wallpaperColor),
        const LoginBubbles(),
      ],
    );
  }
}
