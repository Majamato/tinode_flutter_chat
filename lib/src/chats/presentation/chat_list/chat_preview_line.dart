import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_preview_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/message_runs.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_preview.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/typing_indicator.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The line under a chat's name: who is typing, in the link colour; else
/// the newest message, after "You" when the user sent it, in any chat, or
/// its sender in a group, and with an icon for what it is. When the newest
/// isn't on this device yet: "New message" if it is unread, else nothing (a
/// new device has no messages of chats long read).
///
/// Rebuilds when the cached newest message changes or falls behind, or the
/// chat turns read or unread, not with every `pres msg`.
class ChatPreviewLine extends ConsumerWidget {
  const ChatPreviewLine({required this.topic, super.key});

  static const _thumbnailSize = 18.0;

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icons = TinodeChatIcons.of(context);
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.outline,
    );
    if (ref.watch(anyoneTypingProvider(topic))) {
      return TypingIndicator(topic: topic, style: style);
    }
    final strings = TinodeChatStrings.of(context);
    if (ref.watch(chatPreviewBehindProvider(topic))) {
      final unread = ref.watch(
        chatSummaryProvider(topic).select((chat) => (chat?.unread ?? 0) > 0),
      );
      return _line(Text(unread ? strings.newMessageArrived : ''), style);
    }
    final preview = ref.watch(chatPreviewProvider(topic));
    if (preview == null) {
      return _line(const Text(''), style);
    }

    final theme = TinodeChatTheme.of(context);
    final sender = switch (preview) {
      ChatPreview(isOwn: true) => strings.youLabel,
      ChatPreview(:final senderName?) => senderName,
      _ => null,
    };
    final call = preview.call;
    final (icon, iconColor) = switch (preview.kind) {
      ChatPreviewKind.voice => (icons.microphone, theme.iconPassiveColor),
      ChatPreviewKind.video => (icons.video, theme.iconPassiveColor),
      ChatPreviewKind.file => (icons.file, theme.iconPassiveColor),
      ChatPreviewKind.call => (
        call?.audioOnly ?? true ? icons.voiceCall : icons.videoCall,
        preview.isMissedCall ? theme.missedCallColor : theme.iconPassiveColor,
      ),
      ChatPreviewKind.text || ChatPreviewKind.photo => (null, null),
    };
    final audioOnly = call?.audioOnly ?? true;
    final text = switch (preview) {
      ChatPreview(text: final text) when text.isNotEmpty => text,
      ChatPreview(kind: ChatPreviewKind.photo) => strings.photoMessage,
      ChatPreview(kind: ChatPreviewKind.video) => strings.videoMessage,
      ChatPreview(kind: ChatPreviewKind.voice) => strings.voiceMessage,
      ChatPreview(isMissedCall: true) =>
        audioOnly ? strings.missedVoiceCall : strings.missedVideoCall,
      ChatPreview(kind: ChatPreviewKind.call) =>
        audioOnly ? strings.voiceCall : strings.videoCall,
      _ => '',
    };
    return _line(
      Row(
        children: [
          if (sender != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 5),
              child: Text(
                '$sender:',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (preview.kind == ChatPreviewKind.photo)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox.square(
                  dimension: _thumbnailSize,
                  child: switch (preview.photo) {
                    final bytes? => Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                    null => Icon(
                      icons.photo,
                      size: ChatIconSize.small,
                      color: theme.iconPassiveColor,
                    ),
                  },
                ),
              ),
            ),
          if (icon != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 5),
              child: Icon(icon, size: ChatIconSize.small, color: iconColor),
            ),
          Expanded(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      style,
    );
  }

  static Widget _line(Widget child, TextStyle? style) => DefaultTextStyle.merge(
    style: style,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    child: child,
  );
}
