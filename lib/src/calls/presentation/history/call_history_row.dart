import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_tile.dart';

/// The calls history's row for the call [id], drawn by [CallHistoryTile],
/// or blank while the history doesn't hold it. Watches that call only.
class CallHistoryRow extends ConsumerWidget {
  const CallHistoryRow({required this.id, super.key});

  final CallId id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(callHistoryEntryProvider(id.topic, id.seq));
    return entry == null
        ? const SizedBox(height: CallHistoryTile.height)
        : CallHistoryTile(entry: entry);
  }
}
