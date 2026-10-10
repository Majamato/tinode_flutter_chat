import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/file_size_label.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/typing_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/attach_button.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/send_button.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The attach button, the message field and the send button. Typing and
/// sending never rebuild it: the button watches both on its own. Typing
/// tells the other members. A failed send, or a refused attachment, shows
/// a snack bar and keeps the text.
class Composer extends ConsumerStatefulWidget {
  const Composer({required this.topic, super.key});

  final String topic;

  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<Composer> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final sent = await ref
        .read(sendControllerProvider(widget.topic).notifier)
        .send(_text.text);
    if (sent && mounted) {
      _text.clear();
    }
  }

  void _onSendState(AsyncValue<void>? previous, AsyncValue<void> next) {
    if (next case AsyncError(:final error) when previous is! AsyncError) {
      final strings = TinodeChatStrings.of(context);
      final message = switch (error) {
        FileTooLargeException(:final limit) => strings.fileTooLargeLimit(
          fileSizeLabel(limit),
        ),
        _ => failureMessage(strings, ChatFailure.of(error)),
      };
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sendControllerProvider(widget.topic), _onSendState);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          AttachButton(topic: widget.topic),
          Expanded(
            child: TextField(
              controller: _text,
              decoration: InputDecoration(
                hintText: TinodeChatStrings.of(context).messageHint,
              ),
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onChanged: (_) => ref
                  .read(typingControllerProvider(widget.topic).notifier)
                  .typed(),
              onSubmitted: (_) => _send(),
            ),
          ),
          SendButton(topic: widget.topic, text: _text, onSend: _send),
        ],
      ),
    );
  }
}
