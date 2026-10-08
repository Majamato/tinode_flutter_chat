import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/find_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/new_group_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/create_group_button.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_field.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_results.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/selected_members.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Creates a group: its name, and people found by a search as members.
/// Once created, the group's chat opens over the chat list. Shows a snack
/// bar when the group could not be created, or some members not added.
class NewGroupScreen extends ConsumerStatefulWidget {
  const NewGroupScreen({super.key});

  /// Pushes the screen onto the chat's navigator.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const NewGroupScreen()));

  @override
  ConsumerState<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends ConsumerState<NewGroupScreen> {
  final _name = TextEditingController();

  /// The picked members in the order picked, and their topics.
  var _members = const <SearchResult>[];
  var _picked = const <String>{};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toggle(SearchResult member) => setState(() {
    _members = _picked.contains(member.topic)
        ? [
            for (final m in _members)
              if (m.topic != member.topic) m,
          ]
        : [..._members, member];
    _picked = {for (final m in _members) m.topic};
  });

  Future<void> _create() async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = TinodeChatStrings.of(context);
    final group = await ref
        .read(newGroupControllerProvider.notifier)
        .create(_name.text, _members);
    if (group == null || !mounted) {
      return;
    }
    if (group.notAdded.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(strings.membersNotAdded)));
    }
    unawaited(ChatScreen.openOverList(context, group.topic));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(newGroupControllerProvider, (_, next) {
      if (next case AsyncError(:final error) when !next.isLoading) {
        final strings = TinodeChatStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failureMessage(strings, ChatFailure.of(error))),
          ),
        );
      }
    });
    final strings = TinodeChatStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.newGroup),
        actions: [CreateGroupButton(name: _name, onCreate: _create)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: strings.groupNameField),
            ),
          ),
          if (_members.isNotEmpty)
            SelectedMembers(members: _members, onRemove: _toggle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FindField(
              scope: FindScope.groupMembers,
              hint: strings.addMembersHint,
              autofocus: false,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FindResults(
              scope: FindScope.groupMembers,
              selected: _picked,
              onSelected: _toggle,
            ),
          ),
        ],
      ),
    );
  }
}
