import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_list.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/error_retry_view.dart';

/// Progress, error or the messages. Rebuilds only when the load status
/// does. While it is shown the chat stays attached.
class ChatBody extends ConsumerWidget {
  const ChatBody({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (status, failure) = ref.watch(
      chatControllerProvider(topic).select((s) => (s.status, s.failure)),
    );
    return switch (status) {
      LoadStatus.loading => const Center(child: CircularProgressIndicator()),
      LoadStatus.failed => ErrorRetryView(
        failure: failure ?? ChatFailure.unexpected,
        onRetry: ref.read(chatControllerProvider(topic).notifier).reload,
      ),
      LoadStatus.ready => MessageList(topic: topic),
    };
  }
}
