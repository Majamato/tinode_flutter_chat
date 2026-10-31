import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_scope.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_screen.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/profile_screen.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The chat list's menu without the tab bar: the user's profile, the
/// appearance when the host offers one, and logging out, which also
/// deletes the chats kept on the device.
class AccountMenuButton extends ConsumerWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = TinodeChatStrings.of(context);
    return PopupMenuButton<void>(
      tooltip: strings.accountMenu,
      icon: Icon(
        Icons.account_circle_outlined,
        color: TinodeChatTheme.of(context).linkColor,
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          onTap: () => unawaited(ProfileScreen.open(context)),
          child: Text(strings.profile),
        ),
        if (AppearanceScope.peek(context) != null)
          PopupMenuItem(
            onTap: () => unawaited(
              AppearanceScreen.open(context, backLabel: strings.chatListTitle),
            ),
            child: Text(strings.appearance),
          ),
        PopupMenuItem(
          onTap: () =>
              unawaited(ref.read(sessionControllerProvider.notifier).logout()),
          child: Text(strings.logOut),
        ),
      ],
    );
  }
}
