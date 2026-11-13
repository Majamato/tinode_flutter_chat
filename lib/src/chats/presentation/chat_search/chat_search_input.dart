import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_search.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The text field of the chat search; each change filters the chats.
/// Watches nothing.
class ChatSearchInput extends ConsumerStatefulWidget {
  const ChatSearchInput({super.key});

  @override
  ConsumerState<ChatSearchInput> createState() => _ChatSearchInputState();
}

class _ChatSearchInputState extends ConsumerState<ChatSearchInput> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _changed(String text) =>
      ref.read(chatSearchFilterProvider.notifier).change(text);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _text,
      autofocus: true,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: TinodeChatStrings.of(context).chatSearchHint,
        prefixIcon: Icon(TinodeChatIcons.of(context).search),
        border: InputBorder.none,
      ),
      onChanged: _changed,
    );
  }
}
