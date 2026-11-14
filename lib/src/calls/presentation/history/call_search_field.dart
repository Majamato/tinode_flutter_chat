import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_search/call_search_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/search_pill.dart';

/// The search pill under the calls history's app bar, which opens the
/// call search. Watches nothing.
class CallSearchField extends StatelessWidget implements PreferredSizeWidget {
  const CallSearchField({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(SearchPill.height);

  void _open(BuildContext context) => CallSearchScreen.open(context);

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    return SearchPill(
      label: strings.searchCalls,
      semanticsLabel: strings.callSearchHint,
      onTap: () => _open(context),
    );
  }
}
