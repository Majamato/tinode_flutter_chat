import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/account/presentation/account_tile.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_scope.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_tile.dart';
import 'package:tinode_flutter_chat/src/settings/presentation/presence_tile.dart';
import 'package:tinode_flutter_chat/src/settings/presentation/settings_profile_tile.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_section.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';

/// The settings tab: the user's profile, their account (password, logging
/// out, deleting it), the appearance when the host offers one, and whether
/// others see the user's online status, in cards scrolling under the glass
/// app bar. Watches nothing.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final page = TinodeChatTheme.of(context).pageColor;
    return GlassScaffold(
      screen: const TinodeSettingsScreen(),
      backgroundColor: page,
      appBar: TinodeAppBar(
        title: Text(TinodeChatStrings.of(context).settingsTitle),
        fadeColor: page,
      ),
      // No padding of its own: the list pads itself by the bars'.
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              spacing: 22,
              children: [
                const SettingsSection(children: [SettingsProfileTile()]),
                const SettingsSection(children: [AccountTile()]),
                if (AppearanceScope.peek(context) != null)
                  const SettingsSection(children: [AppearanceTile()]),
                SettingsSection(
                  footer: TinodeChatStrings.of(
                    context,
                  ).showMyOnlineStatusFooter,
                  children: const [PresenceTile()],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
