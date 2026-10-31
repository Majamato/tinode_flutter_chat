import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_scope.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_tile.dart';
import 'package:tinode_flutter_chat/src/settings/presentation/log_out_tile.dart';
import 'package:tinode_flutter_chat/src/settings/presentation/settings_profile_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/screen_header.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_section.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The settings tab: the user's profile, the appearance when the host
/// offers one, and logging out, in cards under a header. Watches
/// nothing.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinodeChatTheme.of(context).pageColor,
      appBar: ScreenHeader(title: TinodeChatStrings.of(context).settingsTitle),
      body: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            Column(
              spacing: 22,
              children: [
                const SettingsSection(children: [SettingsProfileTile()]),
                if (AppearanceScope.peek(context) != null)
                  const SettingsSection(children: [AppearanceTile()]),
                const SettingsSection(children: [LogOutTile()]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
