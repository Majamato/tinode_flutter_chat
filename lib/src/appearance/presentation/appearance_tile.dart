import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_scope.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_tile.dart';

/// The settings' way to the appearance screen, naming the palette in use.
/// Watches the appearance.
class AppearanceTile extends StatelessWidget {
  const AppearanceTile({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final appearance = AppearanceScope.maybeOf(context);
    return SettingsTile(
      icon: TinodeChatIcons.of(context).appearance,
      title: strings.appearance,
      subtitle: (appearance?.palettes.length ?? 0) > 1
          ? appearance?.palette.label
          : null,
      onTap: () => unawaited(
        AppearanceScreen.open(context, backLabel: strings.settingsTitle),
      ),
    );
  }
}
