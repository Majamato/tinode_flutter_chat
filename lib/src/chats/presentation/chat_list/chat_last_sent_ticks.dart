import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_preview_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_status_icon.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The ticks of the user's own last message, before the time: read in the
/// link colour. Nothing when the last message is someone else's, or when
/// newer ones aren't on this device.
class ChatLastSentTicks extends ConsumerWidget {
  const ChatLastSentTicks({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(
      chatPreviewProvider(topic).select((preview) => preview?.receipt),
    );
    final behind = ref.watch(chatPreviewBehindProvider(topic));
    if (receipt == null || behind) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: MessageStatusIcon(
        receipt: receipt,
        color: Theme.of(context).colorScheme.outline,
        readColor: TinodeChatTheme.of(context).linkColor,
      ),
    );
  }
}
