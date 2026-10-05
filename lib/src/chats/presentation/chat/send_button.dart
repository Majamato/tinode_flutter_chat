import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Sends the composer's [text]. Disabled while it is blank or a message
/// is on its way; the only part of the composer that rebuilds for either.
class SendButton extends ConsumerWidget {
  const SendButton({
    required this.topic,
    required this.text,
    required this.onSend,
    super.key,
  });

  final String topic;
  final TextEditingController text;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sending = ref.watch(
      sendControllerProvider(topic).select((s) => s.isLoading),
    );
    final tooltip = TinodeChatStrings.of(context).send;
    if (sending) {
      return IconButton(
        onPressed: null,
        tooltip: tooltip,
        icon: const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return ValueListenableBuilder(
      valueListenable: text,
      builder: (context, value, icon) => IconButton(
        onPressed: value.text.trim().isEmpty ? null : onSend,
        tooltip: tooltip,
        icon: icon!,
      ),
      child: const Icon(Icons.send),
    );
  }
}
