import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/account/presentation/change_password_tile.dart';
import 'package:tinode_flutter_chat/src/account/presentation/delete_account_tile.dart';
import 'package:tinode_flutter_chat/src/account/presentation/log_out_tile.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_section.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

/// The user's account: changing the password, logging out and deleting
/// the account, in cards scrolling under the glass app bar, whose back
/// button names [backLabel]. Watches nothing itself.
class AccountScreen extends StatelessWidget {
  const AccountScreen({required this.backLabel, super.key});

  /// Pushes the screen onto the chat's navigator.
  static Future<void> open(BuildContext context, {required String backLabel}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AccountScreen(backLabel: backLabel),
        ),
      );

  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final page = TinodeChatTheme.of(context).pageColor;
    return GlassScaffold(
      screen: const TinodeAccountScreen(),
      backgroundColor: page,
      appBar: TinodeAppBar(
        title: Text(TinodeChatStrings.of(context).account),
        leading: TinodeBackButton(label: Text(backLabel)),
        fadeColor: page,
      ),
      // No padding of its own: the list pads itself by the bars'.
      body: ListView(
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 22,
              children: [
                SettingsSection(children: [ChangePasswordTile()]),
                SettingsSection(children: [LogOutTile()]),
                SettingsSection(children: [DeleteAccountTile()]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
