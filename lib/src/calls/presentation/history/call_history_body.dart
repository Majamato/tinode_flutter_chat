import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_list.dart';

/// A spinner until the cache was read, then the calls. Watches only
/// whether the cache was read.
class CallHistoryBody extends ConsumerWidget {
  const CallHistoryBody({required this.topInset, super.key});

  final ValueListenable<double> topInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = ref.watch(
      callHistoryControllerProvider.select((h) => h.loaded),
    );
    return loaded
        ? CallHistoryList(topInset: topInset)
        : const Center(child: CircularProgressIndicator());
  }
}
