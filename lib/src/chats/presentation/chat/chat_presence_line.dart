import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/sliding_text.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// "online" in the link colour for a direct chat whose peer is, else when
/// the peer was last seen in `outline`, sliding when it doesn't fit, else
/// nothing. Presence is never there while it is off. Watches the chat's
/// online and last seen.
class ChatPresenceLine extends ConsumerWidget {
  const ChatPresenceLine({required this.topic, this.style, super.key});

  final String topic;

  /// The text style, in the colours above; the theme's `bodySmall` when
  /// null.
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (online, lastSeen) = ref.watch(
      chatSummaryProvider(topic).select(
        (chat) => chat == null || chat.kind != TopicKind.direct
            ? (false, null)
            : (chat.online, chat.lastSeen),
      ),
    );
    final theme = Theme.of(context);
    final textStyle = style ?? theme.textTheme.bodySmall;
    if (online) {
      return Text(
        TinodeChatStrings.of(context).online,
        maxLines: 1,
        style: textStyle?.copyWith(
          color: TinodeChatTheme.of(context).linkColor,
        ),
      );
    }
    if (lastSeen == null) {
      return const SizedBox.shrink();
    }
    return SlidingText(
      lastSeenText(
        TinodeChatStrings.of(context),
        MaterialLocalizations.of(context),
        lastSeen,
      ),
      style: textStyle?.copyWith(color: theme.colorScheme.outline),
    );
  }

  /// "last seen today at 14:05", "… yesterday at 14:05", or "… Mar 3".
  @visibleForTesting
  static String lastSeenText(
    TinodeChatStrings strings,
    MaterialLocalizations localizations,
    DateTime lastSeen, {
    DateTime? now,
  }) {
    final local = lastSeen.toLocal();
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    return switch (calendarDaysBetween(local, today)) {
      <= 0 => strings.lastSeenToday(localizations.messageTime(local)),
      1 => strings.lastSeenYesterday(localizations.messageTime(local)),
      _ => strings.lastSeenOn(localizations.formatShortMonthDay(local)),
    };
  }
}
