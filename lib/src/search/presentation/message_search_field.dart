import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/search/application/message_search_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The text field of a message search; each change goes to the search of
/// the chat named [topic]. Watches nothing.
class MessageSearchField extends ConsumerStatefulWidget {
  const MessageSearchField({required this.topic, super.key});

  final String topic;

  @override
  ConsumerState<MessageSearchField> createState() => _MessageSearchFieldState();
}

class _MessageSearchFieldState extends ConsumerState<MessageSearchField> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _text,
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: TinodeChatStrings.of(context).messageSearchHint,
        prefixIcon: const Icon(Icons.search),
        border: InputBorder.none,
      ),
      onChanged: (text) => ref
          .read(messageSearchControllerProvider(widget.topic).notifier)
          .search(text),
    );
  }
}
