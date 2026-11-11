import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/round_send_button.dart';

/// The composer's [RoundSendButton], for its [text]: it sends once there
/// is text, and while it is blank it records a voice message
/// ([onRecord]), where voice messages are on. (While recording, the
/// recording panel takes the composer's place, button and all.) It spins
/// while a message is on its way. The only part of the composer that
/// rebuilds for any of these.
class SendButton extends ConsumerWidget {
  const SendButton({
    required this.topic,
    required this.text,
    required this.onSend,
    required this.onRecord,
    super.key,
  });

  final String topic;
  final TextEditingController text;
  final VoidCallback onSend;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sending = ref.watch(
      sendControllerProvider(topic).select((s) => s.isLoading),
    );
    final voice = ref.watch(
      tinodeChatFeaturesProvider.select((f) => f.voiceMessages),
    );
    return ValueListenableBuilder(
      valueListenable: text,
      builder: (context, value, _) => RoundSendButton(
        onSend: value.text.trim().isNotEmpty ? onSend : null,
        onRecord: voice ? onRecord : null,
        busy: sending,
      ),
    );
  }
}
