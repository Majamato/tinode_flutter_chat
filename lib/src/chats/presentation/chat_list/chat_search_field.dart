import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_people_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// What looks like a search field in the chat list's header: a 38 px pill
/// that opens the search for people and groups. Watches nothing.
class ChatSearchField extends StatelessWidget {
  const ChatSearchField({super.key});

  static const _height = 38.0;
  static const _radius = BorderRadius.all(Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.outline;
    return Tooltip(
      message: strings.findPeople,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: strings.findPeople,
        excludeSemantics: true,
        child: Material(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: _radius,
          child: InkWell(
            borderRadius: _radius,
            onTap: () => FindPeopleScreen.open(context),
            child: SizedBox(
              height: _height,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, size: 18, color: muted),
                  const SizedBox(width: 8),
                  Text(
                    strings.searchChats,
                    style: theme.textTheme.bodyLarge?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
