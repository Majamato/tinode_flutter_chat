import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/call_record_texts.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_avatar.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// One call of the history, 72 px tall: the chat's avatar and name (in
/// the missed-call colour when the user missed it), the direction, kind
/// and how it went, the time, and a button to the chat. A tap calls back,
/// by the same kind when the host offers it, while the chat can be called
/// and no other call runs. Watches the call, the host's call kinds,
/// whether the chat can be called and whether a call runs.
class CallHistoryTile extends ConsumerWidget {
  const CallHistoryTile({required this.id, super.key});

  static const height = 72.0;
  static const _avatarRadius = 24.0;

  final CallId id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(callHistoryEntryProvider(id.topic, id.seq));
    if (entry == null) {
      return const SizedBox(height: height);
    }
    final audioOnly = ref.watch(
      tinodeChatFeaturesProvider.select(entry.callBackAudioOnly),
    );
    final callable = ref.watch(callsAvailableProvider(id.topic));
    final busy = ref.watch(
      callControllerProvider.select((c) => c != null && !c.isOver),
    );
    final strings = TinodeChatStrings.of(context);
    final theme = Theme.of(context);
    final chat = TinodeChatTheme.of(context);
    final muted = theme.colorScheme.outline;
    final accent = entry.missed ? chat.missedCallColor : chat.iconPassiveColor;
    final call = entry.call;
    final kind = call.audioOnly ? strings.voiceCall : strings.videoCall;
    final how = '$kind · ${call.status(strings, outgoing: entry.outgoing)}';
    return Semantics(
      onTapHint: strings.callBack,
      child: InkWell(
        onTap: audioOnly == null || !callable || busy
            ? null
            : () => unawaited(
                ref
                    .read(callControllerProvider.notifier)
                    .start(id.topic, audioOnly: audioOnly),
              ),
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: Row(
              children: [
                ChatAvatar(topic: id.topic, radius: _avatarRadius),
                const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 3,
                              children: [
                                DefaultTextStyle.merge(
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 16,
                                    color: entry.missed
                                        ? chat.missedCallColor
                                        : null,
                                  ),
                                  child: ChatTitle(topic: id.topic),
                                ),
                                Row(
                                  spacing: 4,
                                  children: [
                                    Icon(
                                      call.icon(
                                        TinodeChatIcons.of(context),
                                        outgoing: entry.outgoing,
                                      ),
                                      size: ChatIconSize.small,
                                      color: accent,
                                    ),
                                    Flexible(
                                      child: Text(
                                        how,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: muted),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            MaterialLocalizations.of(context).chatListTime(
                              entry.time,
                              yesterday: strings.yesterday,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                          IconButton(
                            tooltip: strings.openChat,
                            color: chat.iconColor,
                            onPressed: () => ChatScreen.open(context, id.topic),
                            icon: Icon(TinodeChatIcons.of(context).openChat),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
