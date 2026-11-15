import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_search.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_search/call_search_row.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_skeleton.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/load_more_row.dart';

/// The calls the call search found, exact matches first and newest first
/// among them, or that it found none; blank until its first page was read.
/// While more are left, a skeleton row ends the list and reads the next
/// page once it is built: a screen before the end, or at once while
/// the calls don't fill the screen. Rebuilds only when the calls shown,
/// their order or whether more are left change; each row watches its own
/// call.
class CallSearchResults extends ConsumerWidget {
  const CallSearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (loaded, ids, hasMore) = ref.watch(
      callSearchControllerProvider.select((s) => (s.loaded, s.ids, s.hasMore)),
    );
    if (!loaded) {
      return const SizedBox.shrink();
    }
    if (ids.isEmpty && !hasMore) {
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
    return ListView.builder(
      // Rows a screen past the end are built, so the skeleton row asks
      // for the next page a screen early.
      scrollCacheExtent: const ScrollCacheExtent.viewport(1),
      itemExtent: CallHistoryTile.height,
      itemCount: ids.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) => index < ids.length
          ? CallSearchRow(key: ValueKey(ids[index]), id: ids[index])
          : LoadMoreRow(
              onShown: () => unawaited(
                ref.read(callSearchControllerProvider.notifier).loadMore(),
              ),
              child: const CallHistorySkeleton(rows: 1),
            ),
    );
  }
}
