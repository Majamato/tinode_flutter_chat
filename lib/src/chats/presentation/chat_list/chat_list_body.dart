import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_view.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/error_retry_view.dart';

/// Progress, error or the list, below the header: [topInset] is its
/// height. Rebuilds only when the load status does.
class ChatListBody extends ConsumerWidget {
  const ChatListBody({required this.topInset, super.key});

  final ValueListenable<double> topInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (status, failure) = ref.watch(
      chatListControllerProvider.select((s) => (s.status, s.failure)),
    );
    if (status == LoadStatus.ready) {
      return ChatListView(topInset: topInset);
    }
    return ValueListenableBuilder(
      valueListenable: topInset,
      builder: (context, top, child) => Padding(
        padding: EdgeInsets.only(top: top),
        child: child,
      ),
      child: switch (status) {
        LoadStatus.failed => ErrorRetryView(
          failure: failure ?? ChatFailure.unexpected,
          onRetry: ref.read(chatListControllerProvider.notifier).reload,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
