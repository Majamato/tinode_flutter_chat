import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_search.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The text field of the call search; each change filters the calls.
/// Watches nothing.
class CallSearchInput extends ConsumerStatefulWidget {
  const CallSearchInput({super.key});

  @override
  ConsumerState<CallSearchInput> createState() => _CallSearchInputState();
}

class _CallSearchInputState extends ConsumerState<CallSearchInput> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _changed(String text) =>
      ref.read(callSearchControllerProvider.notifier).search(text);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _text,
      autofocus: true,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: TinodeChatStrings.of(context).callSearchHint,
        prefixIcon: Icon(TinodeChatIcons.of(context).search),
        border: InputBorder.none,
      ),
      onChanged: _changed,
    );
  }
}
