import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_skeleton.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_view.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/error_retry_view.dart';

/// A skeleton of the list or the list itself, scrolling under the bars, or
/// an error between them. Rebuilds only when the load status does.
class ChatListBody extends ConsumerWidget {
  const ChatListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (status, failure) = ref.watch(
      chatListControllerProvider.select((s) => (s.status, s.failure)),
    );
    return switch (status) {
      LoadStatus.ready => const ChatListView(),
      LoadStatus.failed => SafeArea(
        child: ErrorRetryView(
          failure: failure ?? ChatFailure.unexpected,
          onRetry: ref.read(chatListControllerProvider.notifier).reload,
        ),
      ),
      LoadStatus.loading => const ChatListSkeleton(),
    };
  }
}
