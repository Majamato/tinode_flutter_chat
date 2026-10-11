import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_people_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The chat list's search button: finds people and groups to chat with.
/// Watches nothing.
class FindPeopleButton extends StatelessWidget {
  const FindPeopleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: TinodeChatStrings.of(context).findPeople,
      icon: const Icon(Icons.search),
      onPressed: () => FindPeopleScreen.open(context),
    );
  }
}
