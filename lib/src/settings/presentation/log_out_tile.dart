import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_tile.dart';

/// Logs out, which also deletes the chats kept on the device. Watches
/// nothing.
class LogOutTile extends ConsumerWidget {
  const LogOutTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsTile(
      icon: TinodeChatIcons.of(context).logOut,
      title: TinodeChatStrings.of(context).logOut,
      destructive: true,
      onTap: () =>
          unawaited(ref.read(sessionControllerProvider.notifier).logout()),
    );
  }
}
