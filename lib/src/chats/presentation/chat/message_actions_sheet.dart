import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// What the user can do with message [seq]: delete it for themselves, or
/// for everyone where they may.
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
    final strings = TinodeChatStrings.of(context);
    final forEveryone = ref.watch(
      chatSummaryProvider(topic).select((c) => c?.canDeleteForEveryone),
    );

    void delete({required bool forEveryone}) {
      Navigator.of(context).pop();
      unawaited(
        ref.read(chatControllerProvider(topic).notifier).delete({
          seq,
        }, forEveryone: forEveryone),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(strings.deleteForMe),
            onTap: () => delete(forEveryone: false),
          ),
          if (forEveryone ?? false)
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined),
              title: Text(strings.deleteForEveryone),
              onTap: () => delete(forEveryone: true),
            ),
        ],
      ),
    );
  }
}
