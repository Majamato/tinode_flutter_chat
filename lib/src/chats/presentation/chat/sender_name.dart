import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The sender's name above the first message of their run in a group, in
/// their colour.
class SenderName extends ConsumerWidget {
  const SenderName({required this.topic, required this.seq, super.key});

  final String topic;
  final int seq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sender = ref.watch(
      messageSenderProvider(
        topic,
        seq,
      ).select((s) => s == null ? null : (s.name, s.colorIndex)),
    );
    if (sender == null) {
      return const SizedBox.shrink();
    }
    final (name, colorIndex) = sender;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        name ?? TinodeChatStrings.of(context).unknownMember,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: TinodeChatTheme.of(context).senderNameColor(colorIndex),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
