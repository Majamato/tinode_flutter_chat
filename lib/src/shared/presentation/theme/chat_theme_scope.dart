import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/chat_overlay_style.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Adds a [TinodeChatTheme] derived from the app's theme when the app did
/// not provide one, so [TinodeChatTheme.of] is a plain lookup below it.
/// Sets the status bar's icons to stay readable on the theme's screens
/// that have no app bar; app bars and the call screens set their own.
class ChatThemeScope extends StatelessWidget {
  const ChatThemeScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = AnnotatedRegion<SystemUiOverlayStyle>(
      value: chatOverlayStyle(theme.brightness),
      child: child,
    );
    if (theme.extension<TinodeChatTheme>() != null) {
      return content;
    }

    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values,
          TinodeChatTheme.fallback(theme),
        ],
      ),
      child: content,
    );
  }
}
