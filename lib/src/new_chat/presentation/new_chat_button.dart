import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_people_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The chat list's button that opens the search for people to chat with.
/// Watches nothing.
class NewChatButton extends StatelessWidget {
  const NewChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: TinodeChatStrings.of(context).newChat,
      onPressed: () => FindPeopleScreen.open(context),
      child: const Icon(Icons.edit_outlined),
    );
  }
}
