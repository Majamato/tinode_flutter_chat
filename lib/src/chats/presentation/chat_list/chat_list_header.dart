import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/account_menu_button.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_search_field.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_people_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/frosted_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The frosted bar over the chat list: the account menu (with
/// [accountMenu]), "Chats" and the compose button, then the search field.
/// Watches nothing.
class ChatListHeader extends StatelessWidget {
  const ChatListHeader({this.accountMenu = true, super.key});

  /// Room the menu's button takes, kept without it so the title stays
  /// centred.
  static const _sideButton = 48.0;

  final bool accountMenu;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    return FrostedBar(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    if (accountMenu)
                      const AccountMenuButton()
                    else
                      const SizedBox(width: _sideButton),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          strings.chatListTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: strings.newChat,
                      color: TinodeChatTheme.of(context).linkColor,
                      onPressed: () => FindPeopleScreen.open(context),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: ChatSearchField(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
