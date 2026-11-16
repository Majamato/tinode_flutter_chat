import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/push/domain/tinode_push_names.dart';

/// The names [store] holds for a notification of [push]: its chat's, and
/// in a group its sender's.
Future<TinodePushNames> storedPushNames(
  ChatStore store,
  TinodePush push,
) async {
  final topic = push.topic;
  final chat = (await store.chat(topic))?.public?.name;
  final sender = switch (push.from) {
    final from? when TopicKind.of(topic) == TopicKind.group =>
      (await store.member(topic, from))?.public?.name,
    _ => null,
  };
  return TinodePushNames(chat: _shown(chat), sender: _shown(sender));
}

String? _shown(String? name) => switch (name?.trim()) {
  final shown? when shown.isNotEmpty => shown,
  _ => null,
};
