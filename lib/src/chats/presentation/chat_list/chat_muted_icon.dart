import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// A muted speaker after a muted chat's name, so muting doesn't show by
/// the badge's colour alone. Nothing otherwise.
class ChatMutedIcon extends ConsumerWidget {
  const ChatMutedIcon({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = ref.watch(
      chatSummaryProvider(topic).select((chat) => chat?.muted ?? false),
    );
    if (!muted) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: Icon(
        TinodeChatIcons.of(context).muted,
        size: 15,
        color: Theme.of(context).colorScheme.outline,
        semanticLabel: TinodeChatStrings.of(context).chatMuted,
      ),
    );
  }
}
