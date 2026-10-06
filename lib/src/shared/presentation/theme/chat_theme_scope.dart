import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Adds a [TinodeChatTheme] derived from the app's theme when the app did
/// not provide one, so [TinodeChatTheme.of] is a plain lookup below it.
class ChatThemeScope extends StatelessWidget {
  const ChatThemeScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.extension<TinodeChatTheme>() != null) {
      return child;
    }

    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values,
          TinodeChatTheme.fallback(theme),
        ],
      ),
      child: child,
    );
  }
}
