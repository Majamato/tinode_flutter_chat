import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_file.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/image_viewer_screen.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/local_image.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_avatar.dart';
import 'package:tinode_flutter_chat/src/shared/domain/avatar_image.dart';

/// The chat's photo in a circle; a tap opens it full screen, titled with
/// the chat's name. Initials, or a photo still downloading, open nothing.
/// Watches the chat's name and photo, and the photo's file when given by
/// ref.
class ChatPhoto extends ConsumerWidget {
  const ChatPhoto({required this.topic, this.radius, super.key});

  final String topic;

  /// The circle's radius; [CircleAvatar]'s default when null.
  final double? radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (title, photo) = ref.watch(
      chatSummaryProvider(
        topic,
      ).select((chat) => (chat?.title ?? topic, chat?.photo)),
    );
    final avatar = ChatAvatar(topic: topic, radius: radius);
    final provider = _image(ref, photo);
    if (provider == null) {
      return avatar;
    }
    return Semantics(
      button: true,
      image: true,
      label: title,
      child: GestureDetector(
        onTap: () =>
            unawaited(ImageViewerScreen.open(context, provider, title)),
        child: avatar,
      ),
    );
  }

  /// What the viewer shows: the inline photo, or the downloaded one; null
  /// without a photo or until it has downloaded.
  ImageProvider<Object>? _image(WidgetRef ref, AvatarImage? photo) =>
      switch (photo) {
        AvatarImage(:final bytes?) => MemoryImage(bytes),
        AvatarImage(ref: final photoRef?) => switch (ref
            .watch(attachmentFileProvider(photoRef))
            .value) {
          final file? => localImage(file),
          null => null,
        },
        _ => null,
      };
}
