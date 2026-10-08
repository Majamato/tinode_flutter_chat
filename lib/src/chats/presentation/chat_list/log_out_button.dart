import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The chat list's menu: logging out, which also deletes the chats kept
/// on the device.
class LogOutButton extends ConsumerWidget {
  const LogOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = TinodeChatStrings.of(context);
    return PopupMenuButton<void>(
      itemBuilder: (_) => [
        PopupMenuItem(
          onTap: () =>
              unawaited(ref.read(sessionControllerProvider.notifier).logout()),
          child: Text(strings.logOut),
        ),
      ],
    );
  }
}
