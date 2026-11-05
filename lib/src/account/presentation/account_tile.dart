import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/account/presentation/account_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_tile.dart';

/// The settings' way to the account screen: the password, logging out and
/// deleting the account. Watches nothing.
class AccountTile extends StatelessWidget {
  const AccountTile({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    return SettingsTile(
      icon: TinodeChatIcons.of(context).account,
      title: strings.account,
      subtitle: strings.accountSubtitle,
      onTap: () => unawaited(
        AccountScreen.open(context, backLabel: strings.settingsTitle),
      ),
    );
  }
}
