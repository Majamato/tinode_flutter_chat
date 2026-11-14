import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_search.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The calls the call search matches, exact matches first and newest
/// first among them, or that none does. Rebuilds only when the calls shown
/// or their order change; each row watches its own call.
class CallSearchResults extends ConsumerWidget {
  const CallSearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(callSearchResultsProvider);
    if (matches.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            TinodeChatStrings.of(context).noCallsFound,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }
    final ids = matches.ids;
    return ListView.builder(
      itemExtent: CallHistoryTile.height,
      itemCount: ids.length,
      itemBuilder: (context, index) =>
          CallHistoryTile(key: ValueKey(ids[index]), id: ids[index]),
    );
  }
}
