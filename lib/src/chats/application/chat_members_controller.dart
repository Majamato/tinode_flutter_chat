import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_member.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_members.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_receipt.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_sender.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_session.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';

part 'chat_members_controller.g.dart';

/// The members of one open chat: shown from the cache, fetched in full
/// whenever the chat attaches ([sync], called by `ChatController`), and
/// kept current from the topic's live traffic:
///
/// - other members' read and received markers (`info`) raise their
///   counters, and so does a message they send;
/// - a member who joins or leaves (`pres acs`), or a sender not known yet,
///   is fetched alone.
///
/// Channels have none: their followers stay anonymous.
@riverpod
class ChatMembersController extends _$ChatMembersController {
  late BuildLifetime _lifetime;
  ChatSession? _session;

  /// A full list arrived: from then on, someone not in it is news.
  var _synced = false;

  /// Members being fetched alone, so a burst of messages asks once.
  final _fetching = <String>{};

  @override
  ChatMembers build(String topic) {
    final lifetime = _lifetime = BuildLifetime(ref);
    final session = _session = ref.watch(activeSessionProvider);
    _synced = false;
    _fetching.clear();
    if (session == null || TopicKind.of(topic) == TopicKind.channel) {
      return const ChatMembers();
    }

    final subscriptions = [
      session.info.where((i) => i.topic == topic).listen(_onInfo),
      session.presence.where((p) => p.topic == topic).listen(_onPresence),
      session.messages.where((m) => m.topic == topic).listen(_onMessage),
    ];
    ref.onDispose(() {
      for (final subscription in subscriptions) {
        unawaited(subscription.cancel());
      }
    });
    unawaited(_load(session, lifetime));
    return const ChatMembers();
  }

  /// Fetches every member. The chat must be attached. A failure keeps the
  /// members as they are: the chat works without them.
  Future<void> sync() async {
    final session = _session;
    final lifetime = _lifetime;
    if (session == null || TopicKind.of(topic) == TopicKind.channel) {
      return;
    }
    try {
      final members = await session.members(topic);
      if (lifetime.isActive) {
        _synced = true;
        state = state.withMembers(members);
      }
    } on Object {
      // Shown as cached, or without names and receipts.
    }
  }

  Future<void> _load(ChatSession session, BuildLifetime lifetime) async {
    try {
      final stored = await session.storedMembers(topic);
      // A sync that came first knows better.
      if (lifetime.isActive && !_synced) {
        state = state.withMembers(stored);
      }
    } on Object {
      // The cache is a convenience: the next sync fills the members.
    }
  }

  void _onInfo(InfoMessage info) {
    if (info case InfoMessage(:final from?, :final seq?)) {
      state = switch (info.event) {
        InfoEvent.read => state.advanced(from, read: seq),
        InfoEvent.received => state.advanced(from, received: seq),
        _ => state,
      };
    }
  }

  void _onPresence(PresMessage presence) {
    if (presence case PresMessage(
      event: PresenceEvent.access,
      :final source?,
    ) when _synced) {
      unawaited(_fetch(source));
    }
  }

  void _onMessage(DataMessage message) {
    final from = message.from;
    if (from == null) {
      return;
    }
    if (state[from] == null) {
      if (_synced) {
        unawaited(_fetch(from));
      }
      return;
    }
    // The server moves a sender's own counters to their message.
    state = state.advanced(from, read: message.seq, received: message.seq);
  }

  /// Fetches the member [userId] alone: one who joined, or left.
  Future<void> _fetch(String userId) async {
    final session = _session;
    final lifetime = _lifetime;
    if (session == null || !_fetching.add(userId)) {
      return;
    }
    try {
      final found = await session.members(topic, userId: userId);
      if (lifetime.isActive) {
        state = found.isEmpty
            ? state.without(userId)
            : state.withMember(found.single);
      }
    } on Object {
      // The next full sync brings it.
    } finally {
      _fetching.remove(userId);
    }
  }
}

/// Who sent message [seq] of a group, as its bubble shows it; null for
/// the user's own messages and outside groups, where the chat's title says
/// who it is.
@riverpod
MessageSender? messageSender(Ref ref, String topic, int seq) {
  if (TopicKind.of(topic) != TopicKind.group) {
    return null;
  }
  final run = ref.watch(
    chatControllerProvider(topic).select((chat) {
      final message = chat.bySeq[seq];
      final from = message?.from;
      if (message == null || message.isOwn || from == null) {
        return null;
      }
      return (from, chat.startsRun(seq), chat.endsRun(seq));
    }),
  );
  if (run == null) {
    return null;
  }
  final (from, starts, ends) = run;
  final member = ref.watch(
    chatMembersControllerProvider(topic).select((members) => members[from]),
  );
  return MessageSender.of(from, member, showName: starts, showAvatar: ends);
}

/// How far the user's own message [seq] got; null for others' messages.
@riverpod
MessageReceipt? messageReceipt(Ref ref, String topic, int seq) {
  final own = ref.watch(
    chatMessageProvider(topic, seq).select((m) => m?.isOwn ?? false),
  );
  final me = ref.watch(currentUserIdProvider);
  if (!own || me == null) {
    return null;
  }
  return ref.watch(
    chatMembersControllerProvider(topic).select(
      (members) => members.receiptOf(seq, me: me, kind: TopicKind.of(topic)),
    ),
  );
}

/// The other members who read the user's message [seq], and those who only
/// received it.
@riverpod
({List<ChatMember> read, List<ChatMember> delivered}) messageReadBy(
  Ref ref,
  String topic,
  int seq,
) {
  final me = ref.watch(currentUserIdProvider);
  final members = ref.watch(chatMembersControllerProvider(topic));
  return me == null ? (read: [], delivered: []) : members.readBy(seq, me: me);
}

/// Whether message [seq] offers its read-by list: the user's own messages
/// in groups.
@riverpod
bool showsReadBy(Ref ref, String topic, int seq) =>
    TopicKind.of(topic) == TopicKind.group &&
    ref.watch(chatMessageProvider(topic, seq).select((m) => m?.isOwn ?? false));
