import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/search/presentation/message_search_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_icon_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The chat's button that opens message search within it, on the glass
/// island of `ChatHeaderActions`. Watches nothing.
class MessageSearchButton extends StatelessWidget {
  const MessageSearchButton({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      tooltip: TinodeChatStrings.of(context).searchInChat,
      icon: TinodeChatIcons.of(context).search,
      onPressed: () => MessageSearchScreen.open(context, topic),
      onGlass: true,
    );
  }
}
