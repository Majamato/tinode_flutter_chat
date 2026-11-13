import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/new_group_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/new_group_members_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/new_group_photo_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/create_group_button.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/group_photo_button.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/picked_members_card.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_label.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

/// The second step of a new group: its photo and name on a card, and the
/// members picked on the add members screen, still removable. Once
/// created, the group's chat opens over the chat list. Shows a snack bar
/// when the photo could not be picked, the group could not be created, or
/// some members not added.
class NewGroupScreen extends ConsumerStatefulWidget {
  const NewGroupScreen({super.key});

  /// Pushes the screen onto the chat's navigator, over the add members
  /// screen, whose picks it shows.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const NewGroupScreen()));

  @override
  ConsumerState<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends ConsumerState<NewGroupScreen> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = TinodeChatStrings.of(context);
    final group = await ref
        .read(newGroupControllerProvider.notifier)
        .create(
          _name.text,
          ref.read(newGroupMembersControllerProvider).members,
          photo: ref.read(newGroupPhotoControllerProvider).value?.file,
        );
    if (group == null || !mounted) {
      return;
    }
    if (group.notAdded.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(strings.membersNotAdded)));
    }
    unawaited(ChatScreen.openOverList(context, group.topic));
  }

  void _showFailure(Object error) {
    final strings = TinodeChatStrings.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failureMessage(strings, ChatFailure.of(error)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(newGroupControllerProvider, (_, next) {
        if (next case AsyncError(:final error) when !next.isLoading) {
          _showFailure(error);
        }
      })
      ..listen(newGroupPhotoControllerProvider, (_, next) {
        if (next case AsyncError(:final error) when !next.isLoading) {
          _showFailure(error);
        }
      });
    final strings = TinodeChatStrings.of(context);
    final chat = TinodeChatTheme.of(context);

    return GlassScaffold(
      screen: const TinodeNewGroupScreen(),
      backgroundColor: chat.pageColor,
      appBar: TinodeAppBar(
        title: Text(strings.newGroup),
        leading: const TinodeBackButton(),
        actions: [CreateGroupButton(name: _name, onCreate: _create)],
        fadeColor: chat.pageColor,
      ),
      body: _GroupForm(name: _name),
    );
  }
}

/// The group's photo and name on a card, then its members. Inside the
/// scaffold's body, where `MediaQuery` holds the bars' heights, so the
/// list pads itself by them. Watches nothing.
class _GroupForm extends StatelessWidget {
  const _GroupForm({required this.name});

  final TextEditingController name;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final chat = TinodeChatTheme.of(context);
    final padding = MediaQuery.paddingOf(context);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        padding.left + 16,
        padding.top + 16,
        padding.right + 16,
        padding.bottom + 24,
      ),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: chat.cardColor,
            borderRadius: BorderRadius.circular(chat.cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const GroupPhotoButton(),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: strings.groupNameField,
                      prefixIcon: Icon(
                        TinodeChatIcons.of(context).editName,
                        size: ChatIconSize.label,
                        color: chat.iconPassiveColor,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const _MembersLabel(),
        const PickedMembersCard(wrap: true),
      ],
    );
  }
}

/// "MEMBERS: n". Watches the count.
class _MembersLabel extends ConsumerWidget {
  const _MembersLabel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      newGroupMembersControllerProvider.select((m) => m.count),
    );
    return SettingsLabel(TinodeChatStrings.of(context).membersCount(count));
  }
}
