import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_actions_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_exit.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/confirm_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Deletes the chat, deletes the group, or leaves it, after asking; then
/// goes back to the chat list. Watches how the user can get rid of the
/// chat, and whether an action runs.
class ChatExitTile extends ConsumerWidget {
  const ChatExitTile({required this.topic, super.key});

  final String topic;

  Future<void> _exit(BuildContext context, WidgetRef ref, ChatExit exit) async {
    final strings = TinodeChatStrings.of(context);
    final navigator = Navigator.of(context);
    final controller = ref.read(chatActionsControllerProvider(topic).notifier);
    final (:title, :message, :action) = _texts(strings, exit);
    final confirmed = await ConfirmSheet.ask(
      context,
      icon: _icon(TinodeChatIcons.of(context), exit),
      title: title,
      message: message,
      action: action,
    );
    if (!confirmed) {
      return;
    }
    if (await controller.exit(exit)) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  static ({String title, String message, String action}) _texts(
    TinodeChatStrings strings,
    ChatExit exit,
  ) => switch (exit) {
    ChatExit.deleteChat => (
      title: strings.deleteChatConfirmTitle,
      message: strings.deleteChatConfirm,
      action: strings.deleteChat,
    ),
    ChatExit.deleteGroup => (
      title: strings.deleteGroupConfirmTitle,
      message: strings.deleteGroupConfirm,
      action: strings.deleteGroup,
    ),
    ChatExit.leaveGroup => (
      title: strings.leaveGroupConfirmTitle,
      message: strings.leaveGroupConfirm,
      action: strings.leaveGroup,
    ),
  };

  static IconData _icon(TinodeChatIcons icons, ChatExit exit) =>
      exit == ChatExit.leaveGroup ? icons.leaveChat : icons.delete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icons = TinodeChatIcons.of(context);
    final exit = ref.watch(chatExitProvider(topic));
    if (exit == null) {
      return const SizedBox.shrink();
    }
    final busy = ref.watch(
      chatActionsControllerProvider(topic).select((s) => s.isLoading),
    );
    final color = Theme.of(context).colorScheme.error;
    final label = _texts(TinodeChatStrings.of(context), exit).action;
    return ListTile(
      leading: Icon(_icon(icons, exit), color: color),
      title: Text(label, style: TextStyle(color: color)),
      enabled: !busy,
      onTap: () => unawaited(_exit(context, ref, exit)),
    );
  }
}
