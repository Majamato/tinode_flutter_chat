import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/find_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_field.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_results.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/new_group_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Finds people and groups to chat with: tapping one opens the chat,
/// creating it the first time. Also leads to creating a group. Watches
/// nothing itself.
class FindPeopleScreen extends StatelessWidget {
  const FindPeopleScreen({super.key});

  /// Pushes the search onto the chat's navigator.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const FindPeopleScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FindField(
          scope: FindScope.newChat,
          hint: TinodeChatStrings.of(context).findHint,
        ),
      ),
      body: Column(
        children: [
          const NewGroupTile(),
          const Divider(height: 1),
          Expanded(
            child: FindResults(
              scope: FindScope.newChat,
              onSelected: (result) =>
                  ChatScreen.openOverList(context, result.topic),
            ),
          ),
        ],
      ),
    );
  }
}
