import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/search/application/message_search_controller.dart';
import 'package:tinode_flutter_chat/src/search/domain/message_search_state.dart';
import 'package:tinode_flutter_chat/src/search/presentation/found_message_tile.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/error_retry_view.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// What a message search has: a hint, progress, an error, nothing found,
/// or the found messages, loading more near the end. Watches the search's
/// state.
class MessageSearchResults extends ConsumerWidget {
  const MessageSearchResults({required this.topic, super.key});

  /// How close to the end a scroll loads the next page.
  static const _loadMoreExtent = 400.0;

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = messageSearchControllerProvider(topic);
    final (status, failure, results, loadingMore) = ref.watch(
      provider.select((s) => (s.status, s.failure, s.results, s.loadingMore)),
    );
    final strings = TinodeChatStrings.of(context);

    return switch ((status, results.isEmpty)) {
      (MessageSearchStatus.failed, _) => ErrorRetryView(
        failure: failure ?? ChatFailure.unexpected,
        onRetry: ref.read(provider.notifier).retry,
      ),
      (MessageSearchStatus.idle, _) => _Message(strings.messageSearchIdle),
      (MessageSearchStatus.searching, true) => const Center(
        child: CircularProgressIndicator(),
      ),
      (MessageSearchStatus.done, true) => _Message(strings.noMessagesFound),
      (_, false) => NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < _loadMoreExtent) {
            unawaited(ref.read(provider.notifier).loadMore());
          }
          return false;
        },
        child: ListView.builder(
          itemCount: results.length + (loadingMore ? 1 : 0),
          itemBuilder: (context, index) => index < results.length
              ? FoundMessageTile(found: results[index])
              : const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
        ),
      ),
    };
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
