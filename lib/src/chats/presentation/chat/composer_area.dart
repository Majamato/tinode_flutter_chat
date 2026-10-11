import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/composer.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/read_only_notice.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

/// The composer, or a notice where the user cannot post (channel
/// followers), or nothing once the chat is gone. Rebuilds only if one of
/// those changes.
class ComposerArea extends ConsumerWidget {
  const ComposerArea({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gone = ref.watch(
      chatControllerProvider(
        topic,
      ).select((chat) => chat.failure == ChatFailure.gone),
    );
    final canWrite = ref.watch(
      chatSummaryProvider(topic).select((chat) => chat?.canWrite ?? true),
    );
    if (gone) {
      return const SizedBox.shrink();
    }
    return canWrite ? Composer(topic: topic) : const ReadOnlyNotice();
  }
}
