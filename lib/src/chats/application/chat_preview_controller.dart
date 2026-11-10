import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_members.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_preview.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_session.dart';
import 'package:tinode_flutter_chat/src/offline/domain/latest_message.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';

part 'chat_preview_controller.g.dart';

/// The preview of each chat's newest message, by topic, read from the
/// cache: all of them first, then each chat again when its cached messages
/// or members change (`ChatSession.storedChanges`), changes in one turn
/// read once.
///
/// It never asks the server itself: a chat this device isn't attached to
/// gets no message content, only `pres msg`, and the session's latest
/// catch-up fetches the newest messages (and the members a preview needs)
/// into the cache. Until then, or while offline, a chat keeps the preview
/// of its newest cached message.
@Riverpod(keepAlive: true)
class ChatPreviewController extends _$ChatPreviewController {
  final _changed = <String>{};

  @override
  Map<String, ChatPreview> build() {
    final lifetime = BuildLifetime(ref);
    final session = ref.watch(activeSessionProvider);
    final me = ref.watch(currentUserIdProvider);
    _changed.clear();
    if (session == null || me == null) {
      return const {};
    }

    final subscription = session.storedChanges.listen((topic) {
      if (_changed.isEmpty) {
        scheduleMicrotask(() => unawaited(_reload(session, me, lifetime)));
      }
      _changed.add(topic);
    });
    ref.onDispose(() => unawaited(subscription.cancel()));
    unawaited(_load(session, me, lifetime));
    return const {};
  }

  Future<void> _load(
    ChatSession session,
    String me,
    BuildLifetime lifetime,
  ) async {
    final previews = await _previews(
      session,
      me,
      await session.storedLatestMessages(),
    );
    if (lifetime.isActive) {
      // A chat read again meanwhile is newer than this first read.
      state = {...previews, ...state};
    }
  }

  Future<void> _reload(
    ChatSession session,
    String me,
    BuildLifetime lifetime,
  ) async {
    final topics = Set.of(_changed);
    _changed.clear();
    final latest = <String, LatestMessage>{
      for (final topic in topics)
        ...await session.storedLatestMessages(topic: topic),
    };
    final previews = await _previews(session, me, latest);
    if (lifetime.isActive) {
      state = {
        for (final MapEntry(:key, :value) in state.entries)
          if (!topics.contains(key)) key: value,
        ...previews,
      };
    }
  }

  /// The previews of [latest]. A group's members name its senders; the
  /// others need none.
  static Future<Map<String, ChatPreview>> _previews(
    ChatSession session,
    String me,
    Map<String, LatestMessage> latest,
  ) async {
    final previews = <String, ChatPreview>{};
    for (final MapEntry(key: topic, value: end) in latest.entries) {
      final kind = TopicKind.of(topic);
      final members = kind == TopicKind.group
          ? const ChatMembers().withMembers(await session.storedMembers(topic))
          : const ChatMembers();
      if (ChatPreview.of(end, me: me, kind: kind, members: members)
          case final preview?) {
        previews[topic] = preview;
      }
    }
    return previews;
  }
}

/// The preview of [topic]'s newest cached message, if there is one.
@riverpod
ChatPreview? chatPreview(Ref ref, String topic) => ref.watch(
  chatPreviewControllerProvider.select((previews) => previews[topic]),
);
