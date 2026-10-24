import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/typing_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/typing_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Who is typing, under the chat's title in the link colour; nothing
/// while nobody is.
class TypingIndicator extends ConsumerWidget {
  const TypingIndicator({required this.topic, this.style, super.key});

  final String topic;

  /// The text style, in the link colour; the theme's `bodySmall` when null.
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typing = ref.watch(typingMembersProvider(topic));
    if (typing.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      typingMessage(TinodeChatStrings.of(context), typing),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (style ?? Theme.of(context).textTheme.bodySmall)?.copyWith(
        color: TinodeChatTheme.of(context).linkColor,
      ),
    );
  }
}
