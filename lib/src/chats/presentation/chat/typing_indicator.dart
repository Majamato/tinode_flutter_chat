import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/typing_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/typing_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Who is typing, under the chat's title; nothing while nobody is.
class TypingIndicator extends ConsumerWidget {
  const TypingIndicator({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typing = ref.watch(typingMembersProvider(topic));
    if (typing.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      typingMessage(TinodeChatStrings.of(context), typing),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
    );
  }
}
