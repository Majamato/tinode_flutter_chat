import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The calls, newest first, scrolling under the frosted header ([topInset]
/// is its height) and over the tab bar. Pulling it down fetches the chats
/// the cache is behind on. Rebuilds only when the calls shown or their
/// order change; each row watches its own call.
class CallHistoryList extends ConsumerWidget {
  const CallHistoryList({required this.topInset, super.key});

  final ValueListenable<double> topInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(callHistoryControllerProvider.select((h) => h.ids));
    final bottom = MediaQuery.paddingOf(context).bottom + 16;
    return ValueListenableBuilder(
      valueListenable: topInset,
      builder: (context, top, _) => MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: RefreshIndicator(
          edgeOffset: top,
          onRefresh: () => ref
              .read(callHistoryControllerProvider.notifier)
              .refresh(force: true),
          child: ids.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(top: top + 48, bottom: bottom),
                  children: [
                    Center(child: Text(TinodeChatStrings.of(context).noCalls)),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(top: top, bottom: bottom),
                  itemExtent: CallHistoryTile.height,
                  itemCount: ids.length,
                  itemBuilder: (context, index) => CallHistoryTile(
                    key: ValueKey(ids[index]),
                    id: ids[index],
                  ),
                ),
        ),
      ),
    );
  }
}
