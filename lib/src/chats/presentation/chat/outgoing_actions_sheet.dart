import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// What the user can do with a message not sent yet: retry it once it
/// failed, or discard it unless it is on its way.
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
    final status = ref.watch(
      outgoingMessageProvider(topic, clientId).select((m) => m?.status),
    );
    final chat = ref.read(chatControllerProvider(topic).notifier);

    void act(Future<void> Function(String clientId) action) {
      Navigator.of(context).pop();
      unawaited(action(clientId).then((_) {}, onError: (_) {}));
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == OutgoingStatus.failed)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(strings.retry),
              onTap: () => act(chat.retry),
            ),
          if (status != OutgoingStatus.sending)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(strings.discardMessage),
              onTap: () => act(chat.discard),
            ),
        ],
      ),
    );
  }
}
