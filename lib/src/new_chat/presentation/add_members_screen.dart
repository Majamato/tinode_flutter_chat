import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/add_members_list.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/add_members_title.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/member_find_bar.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/next_button.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

/// The first step of a new group: picking its members among the user's
/// direct chats, or anyone the search finds, on cards under a glass bar
/// with the search field. Next goes on to naming the group. Watches
/// nothing.
class AddMembersScreen extends StatelessWidget {
  const AddMembersScreen({super.key});

  /// Pushes the screen onto the chat's navigator.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const AddMembersScreen()));

  @override
  Widget build(BuildContext context) {
    final page = TinodeChatTheme.of(context).pageColor;
    return GlassScaffold(
      screen: const TinodeAddMembersScreen(),
      backgroundColor: page,
      appBar: TinodeAppBar(
        leading: const TinodeBackButton(),
        title: const AddMembersTitle(),
        actions: const [NextButton()],
        bottom: const MemberFindBar(),
        fadeColor: page,
      ),
      body: const AddMembersList(),
    );
  }
}
