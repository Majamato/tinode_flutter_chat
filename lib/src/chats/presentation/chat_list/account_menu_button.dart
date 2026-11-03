import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_scope.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_screen.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/profile_screen.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_icon_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_surface.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The chat list's menu without the tab bar, a round glass button: the
/// user's profile, the appearance when the host offers one, and logging
/// out, which also deletes the chats kept on the device.
class AccountMenuButton extends ConsumerWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = TinodeChatStrings.of(context);
    return GlassSurface(
      child: SizedBox.square(
        dimension: GlassIconButton.size,
        child: PopupMenuButton<void>(
          tooltip: strings.accountMenu,
          padding: EdgeInsets.zero,
          icon: Icon(
            TinodeChatIcons.of(context).account,
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
                  AppearanceScreen.open(
                    context,
                    backLabel: strings.chatListTitle,
                  ),
                ),
                child: Text(strings.appearance),
              ),
            PopupMenuItem(
              onTap: () => unawaited(
                ref.read(sessionControllerProvider.notifier).logout(),
              ),
              child: Text(strings.logOut),
            ),
          ],
        ),
      ),
    );
  }
}
