import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_row.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_skeleton.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/load_more_row.dart';

/// The calls, newest first, scrolling under the app bar and over the tab
/// bar (the top and bottom padding of [MediaQuery]). While older calls are
/// left, a skeleton row ends the list and reads the next page once it is
/// built: a screen before the end, or at once while the calls don't
/// fill the screen. Rebuilds only when the calls shown, their order or
/// whether more are left change; each row watches its own call.
class CallHistoryList extends ConsumerWidget {
  const CallHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (ids, hasMore) = ref.watch(
      callHistoryControllerProvider.select((h) => (h.ids, h.hasMore)),
    );
    final padding = MediaQuery.paddingOf(context);
    final bottom = padding.bottom + 16;
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: ids.isEmpty && !hasMore
          ? ListView(
              padding: EdgeInsets.only(top: padding.top + 48, bottom: bottom),
              children: [
                Center(child: Text(TinodeChatStrings.of(context).noCalls)),
              ],
            )
          : ListView.builder(
              padding: EdgeInsets.only(top: padding.top, bottom: bottom),
              // Rows a screen past the end are built, so the skeleton row asks
              // for the next page a screen early.
              scrollCacheExtent: const ScrollCacheExtent.viewport(1),
              itemExtent: CallHistoryTile.height,
              itemCount: ids.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) => index < ids.length
                  ? CallHistoryRow(key: ValueKey(ids[index]), id: ids[index])
                  : LoadMoreRow(
                      onShown: () => unawaited(
                        ref
                            .read(callHistoryControllerProvider.notifier)
                            .loadMore(),
                      ),
                      child: const CallHistorySkeleton(rows: 1),
                    ),
            ),
    );
  }
}
