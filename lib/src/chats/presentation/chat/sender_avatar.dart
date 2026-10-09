import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/profile_avatar.dart';

/// The sender's avatar beside the last message of their run in a group;
/// an empty space of the same width beside the others, so a run lines up.
class SenderAvatar extends ConsumerWidget {
  const SenderAvatar({required this.topic, required this.seq, super.key});

  static const _radius = 16.0;

  /// The space the avatar takes, gap included.
  static const double width = _radius * 2 + 8;

  final String topic;
  final int seq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(
      messageSenderProvider(topic, seq).select(
        (s) => s == null || !s.showAvatar ? null : (s.initials, s.photo),
      ),
    );
    return SizedBox(
      width: width,
      child: avatar == null
          ? null
          : Align(
              alignment: AlignmentDirectional.bottomStart,
              child: ProfileAvatar(
                initials: avatar.$1,
                photo: avatar.$2,
                radius: _radius,
              ),
            ),
    );
  }
}
