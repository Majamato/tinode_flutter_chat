import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// What the user can do with a message not sent yet: retry it once it
/// failed, or discard it unless it is on its way; for an attachment
/// waiting to upload, discarding cancels the upload.
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
    final strings = TinodeChatStrings.of(context);
    final (status, hasAttachment) = ref.watch(
      outgoingMessageProvider(
        topic,
        clientId,
      ).select((m) => (m?.status, m?.attachment != null)),
    );
    final chat = ref.read(chatControllerProvider(topic).notifier);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == OutgoingStatus.failed)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(strings.retry),
              onTap: () => _act(context, chat.retry),
            ),
          if (status != OutgoingStatus.sending)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              // Discarding a waiting attachment stops its upload.
              title: Text(
                hasAttachment && status == OutgoingStatus.queued
                    ? strings.cancelUpload
                    : strings.discardMessage,
              ),
              onTap: () => _act(context, chat.discard),
            ),
        ],
      ),
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
