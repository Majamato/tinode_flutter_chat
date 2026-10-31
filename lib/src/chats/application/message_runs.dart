import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/typing_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_run.dart';

part 'message_runs.g.dart';

/// Where message [seq] sits in its chat. A bubble rebuilds only when its
/// own position changes, e.g. it stops being the last of a run.
@riverpod
MessageRun messageRun(Ref ref, String topic, int seq) => ref.watch(
  chatControllerProvider(topic).select(
    (chat) => MessageRun(
      startsRun: chat.startsRun(seq),
      endsRun: chat.endsRun(seq),
      startsDay: chat.startsDay(seq),
    ),
  ),
);

/// Where the outbox message [clientId] sits in its chat.
@riverpod
MessageRun outgoingRun(Ref ref, String topic, String clientId) => ref.watch(
  chatControllerProvider(topic).select(
    (chat) => MessageRun(
      startsRun: chat.outgoingStartsRun(clientId),
      endsRun: chat.outgoingEndsRun(clientId),
      startsDay: chat.outgoingStartsDay(clientId),
    ),
  ),
);

/// The unread messages of every chat but [topic], for its back button.
@riverpod
int otherUnread(Ref ref, String topic) => ref.watch(
  chatListControllerProvider.select(
    (list) => list.byTopic.values
        .where((chat) => chat.topic != topic)
        .fold(0, (sum, chat) => sum + chat.unread),
  ),
);

/// The unread messages of every chat that isn't muted, for the tab bar.
@riverpod
int totalUnread(Ref ref) => ref.watch(
  chatListControllerProvider.select(
    (list) => list.byTopic.values
        .where((chat) => !chat.muted)
        .fold(0, (sum, chat) => sum + chat.unread),
  ),
);

/// Whether anyone in [topic] is typing, for the typing bubble.
@riverpod
bool anyoneTyping(Ref ref, String topic) =>
    ref.watch(typingMembersProvider(topic).select((t) => !t.isEmpty));
