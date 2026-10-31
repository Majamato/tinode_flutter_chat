import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The solid bar behind a screen's header: the glass color laid over the
/// surface (as the glass looked over an empty page), with a hairline
/// towards the content below it. Watches nothing.
class HeaderBar extends StatelessWidget {
  const HeaderBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final chat = TinodeChatTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          chat.glassColor,
          Theme.of(context).colorScheme.surface,
        ),
        border: Border(
          bottom: BorderSide(color: chat.glassEdgeColor, width: 0.5),
        ),
      ),
      child: child,
    );
  }
}
