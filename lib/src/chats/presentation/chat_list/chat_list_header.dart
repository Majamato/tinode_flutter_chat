import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/account_menu_button.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_search_field.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_people_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_icon_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';

/// The glass app bar over the chat list: the account menu (with
/// [accountMenu]), "Chats" and the compose button, then the search field.
/// Watches nothing.
class ChatListHeader extends StatelessWidget implements PreferredSizeWidget {
  const ChatListHeader({this.accountMenu = true, super.key});

  final bool accountMenu;

  @override
  Size get preferredSize =>
      const TinodeAppBar(bottom: ChatSearchField()).preferredSize;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    return TinodeAppBar(
      leading: accountMenu ? const AccountMenuButton() : null,
      title: Text(strings.chatListTitle),
      actions: [
        GlassIconButton(
          tooltip: strings.newChat,
          color: TinodeChatTheme.of(context).linkColor,
          onPressed: () => FindPeopleScreen.open(context),
          icon: TinodeChatIcons.of(context).newChat,
        ),
      ],
      bottom: const ChatSearchField(),
    );
  }
}
