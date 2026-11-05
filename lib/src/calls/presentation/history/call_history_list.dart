import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The calls, newest first, scrolling under the app bar and over the tab
/// bar (the top and bottom padding of [MediaQuery]). Rebuilds only when
/// the calls shown or their order change; each row watches its own call.
class CallHistoryList extends ConsumerWidget {
  const CallHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(callHistoryControllerProvider.select((h) => h.ids));
    final padding = MediaQuery.paddingOf(context);
    final bottom = padding.bottom + 16;
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: ids.isEmpty
          ? ListView(
              padding: EdgeInsets.only(top: padding.top + 48, bottom: bottom),
              children: [
                Center(child: Text(TinodeChatStrings.of(context).noCalls)),
              ],
            )
          : ListView.builder(
              padding: EdgeInsets.only(top: padding.top, bottom: bottom),
              itemExtent: CallHistoryTile.height,
              itemCount: ids.length,
              itemBuilder: (context, index) =>
                  CallHistoryTile(key: ValueKey(ids[index]), id: ids[index]),
            ),
    );
  }
}
