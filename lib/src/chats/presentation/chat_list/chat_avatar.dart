import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/profile_avatar.dart';

/// The chat's photo, or its initials, in a circle.
class ChatAvatar extends ConsumerWidget {
  const ChatAvatar({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (initials, photo) = ref.watch(
      chatSummaryProvider(
        topic,
      ).select((chat) => (chat?.initials ?? '', chat?.photo)),
    );
    return ProfileAvatar(initials: initials, photo: photo);
  }
}
