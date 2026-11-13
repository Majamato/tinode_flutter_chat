import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/new_group_members_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The add members screen's title, over how many people are picked once
/// someone is. Watches the count.
class AddMembersTitle extends ConsumerWidget {
  const AddMembersTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      newGroupMembersControllerProvider.select((m) => m.count),
    );
    final strings = TinodeChatStrings.of(context);
    final theme = Theme.of(context);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(strings.addMembersHint),
          if (count > 0)
            Text(
              strings.selectedCount(count),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }
}
