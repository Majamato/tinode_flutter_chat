import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/composer.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/read_only_notice.dart';

/// The composer, or a notice where the user cannot post (channel
/// followers). Rebuilds only if that permission changes.
class ComposerArea extends ConsumerWidget {
  const ComposerArea({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = ref.watch(
      chatSummaryProvider(topic).select((chat) => chat?.canWrite ?? true),
    );
    return canWrite ? Composer(topic: topic) : const ReadOnlyNotice();
  }
}
