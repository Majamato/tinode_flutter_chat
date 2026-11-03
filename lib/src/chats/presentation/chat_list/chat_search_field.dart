import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_people_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_surface.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// What looks like a search field under the chat list's app bar: a glass
/// pill that opens the search for people and groups. Watches nothing.
class ChatSearchField extends StatelessWidget implements PreferredSizeWidget {
  const ChatSearchField({super.key});

  /// Its height.
  static const height = 40.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

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
        child: GlassSurface(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => FindPeopleScreen.open(context),
              child: SizedBox(
                height: height,
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      TinodeChatIcons.of(context).search,
                      size: 18,
                      color: muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.searchChats,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
