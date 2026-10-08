import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/new_group_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The search's entry that opens the new group screen. Watches nothing.
class NewGroupTile extends StatelessWidget {
  const NewGroupTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.group_add_outlined)),
      title: Text(TinodeChatStrings.of(context).newGroup),
      onTap: () => NewGroupScreen.open(context),
    );
  }
}
