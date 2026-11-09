import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/chat_overlay_style.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Adds a [TinodeChatTheme] derived from the app's theme when the app did
/// not provide one, so [TinodeChatTheme.of] is a plain lookup below it.
/// Makes [TinodeChatTheme.iconColor] and [ChatIconSize.standard] the default
/// of every icon and icon button below it, whatever theme the app has.
/// Sets the status bar's icons to stay readable on the theme's screens
/// that have no app bar; app bars and the call screens set their own.
class ChatThemeScope extends StatelessWidget {
  const ChatThemeScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat =
        theme.extension<TinodeChatTheme>() ?? TinodeChatTheme.fallback(theme);
    return Theme(
      data: theme.copyWith(
        extensions: [...theme.extensions.values, chat],
        iconTheme: theme.iconTheme.copyWith(
          color: chat.iconColor,
          size: ChatIconSize.standard,
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: chat.iconColor,
            disabledForegroundColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.38,
            ),
            iconSize: ChatIconSize.standard,
          ),
        ),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: chatOverlayStyle(theme.brightness),
        child: child,
      ),
    );
  }
}
