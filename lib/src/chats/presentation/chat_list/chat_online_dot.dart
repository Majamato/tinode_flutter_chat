import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The dot on a direct chat's avatar while the peer is online: the online
/// colour with a ring in the list's background. Nothing otherwise.
class ChatOnlineDot extends ConsumerWidget {
  const ChatOnlineDot({required this.topic, super.key});

  static const _size = 14.0;
  static const _ring = 3.0;

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(
      chatSummaryProvider(topic).select(
        (chat) => chat != null && chat.kind == TopicKind.direct && chat.online,
      ),
    );
    if (!online) {
      return const SizedBox.shrink();
    }
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: TinodeChatTheme.of(context).onlineColor,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: _ring,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
    );
  }
}
