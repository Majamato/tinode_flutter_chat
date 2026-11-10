import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet_action.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// What the user can do with a message not sent yet: retry it once it
/// failed, under why it failed, or discard it unless it is on its way; for
/// an attachment waiting to upload, discarding cancels the upload.
class OutgoingActionsSheet extends ConsumerWidget {
  const OutgoingActionsSheet({
    required this.topic,
    required this.clientId,
    super.key,
  });

  final String topic;
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icons = TinodeChatIcons.of(context);
    final strings = TinodeChatStrings.of(context);
    final (status, failure, hasAttachment) = ref.watch(
      outgoingMessageProvider(
        topic,
        clientId,
      ).select((m) => (m?.status, m?.failure, m?.attachment != null)),
    );
    final chat = ref.read(chatControllerProvider(topic).notifier);

    return ChatSheet(
      // Why it failed: the bubble only shows that it did.
      title: status == OutgoingStatus.failed && failure != null
          ? failureMessage(strings, failure)
          : null,
      children: [
        if (status == OutgoingStatus.failed)
          ChatSheetAction(
            icon: icons.retry,
            label: strings.retry,
            onTap: () => _act(context, chat.retry),
          ),
        if (status != OutgoingStatus.sending)
          ChatSheetAction(
            icon: icons.delete,
            // Discarding a waiting attachment stops its upload.
            label: hasAttachment && status == OutgoingStatus.queued
                ? strings.cancelUpload
                : strings.discardMessage,
            destructive: true,
            onTap: () => _act(context, chat.discard),
          ),
      ],
    );
  }

  /// Closes the sheet and runs [action] on this message without waiting
  /// for it.
  void _act(
    BuildContext context,
    Future<void> Function(String clientId) action,
  ) {
    Navigator.of(context).pop();
    unawaited(action(clientId).then((_) {}, onError: (_) {}));
  }
}
