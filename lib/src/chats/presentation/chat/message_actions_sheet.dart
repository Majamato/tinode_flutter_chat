import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/read_by_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet_action.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// What the user can do with message [seq]: see who read it (their own,
/// in a group), delete it for themselves, or for everyone where they may.
class MessageActionsSheet extends ConsumerWidget {
  const MessageActionsSheet({
    required this.topic,
    required this.seq,
    super.key,
  });

  final String topic;
  final int seq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icons = TinodeChatIcons.of(context);
    final strings = TinodeChatStrings.of(context);
    final forEveryone = ref.watch(
      chatSummaryProvider(topic).select((c) => c?.canDeleteForEveryone),
    );
    final readBy = ref.watch(showsReadByProvider(topic, seq));

    return ChatSheet(
      children: [
        if (readBy)
          ChatSheetAction(
            icon: icons.readBy,
            label: strings.readBy,
            onTap: () => _showReadBy(context),
          ),
        ChatSheetAction(
          icon: icons.delete,
          label: strings.deleteForMe,
          onTap: () => _delete(context, ref, forEveryone: false),
        ),
        if (forEveryone ?? false)
          ChatSheetAction(
            icon: icons.deleteForever,
            label: strings.deleteForEveryone,
            destructive: true,
            onTap: () => _delete(context, ref, forEveryone: true),
          ),
      ],
    );
  }

  /// Swaps this sheet for the one listing who read the message.
  void _showReadBy(BuildContext context) {
    Navigator.of(context).pop();
    unawaited(
      showChatSheet<void>(
        context,
        builder: (_) => ReadBySheet(topic: topic, seq: seq),
      ),
    );
  }

  /// Closes the sheet and deletes this message without waiting for it.
  void _delete(
    BuildContext context,
    WidgetRef ref, {
    required bool forEveryone,
  }) {
    Navigator.of(context).pop();
    unawaited(
      ref.read(chatControllerProvider(topic).notifier).delete({
        seq,
      }, forEveryone: forEveryone),
    );
  }
}
