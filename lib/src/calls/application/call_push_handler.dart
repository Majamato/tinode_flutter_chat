import 'dart:async';

import 'package:clock/clock.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';
import 'package:tinode_flutter_chat/src/calls/domain/system_calls.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_chat_features.dart';

/// How long after it was sent a call push may still ring: Tinode's default
/// call timeout. The server sends call pushes to be delivered at once or
/// dropped, so a later one is rare.
const callPushLifetime = Duration(seconds: 30);

/// How long looking up the caller's name in the cache may take before the
/// call rings without it.
const callerNameTimeout = Duration(seconds: 2);

/// Acts on a [push] that arrived while the app is in the background or
/// closed: a new call rings on the system's call screen, and a call's later
/// state stops the ringing (another device took it, or it is over).
///
/// The caller's name comes from the cache of the user who last logged in to
/// [config]'s server. With [token], declining on the system's screen
/// reaches the caller even while the app is closed: [registerHangUp] sets
/// that up. A new call of a kind [features] turns off doesn't ring.
///
/// Returns whether [push] was about a call. Call pushes are `silent`, so
/// none of them is a notification to show.
Future<bool> handleCallPush(
  TinodePush push, {
  required TinodeConfig config,
  required SystemCalls systemCalls,
  required ChatStoreOpener storeOpener,
  String? token,
  Future<void> Function()? registerHangUp,
  TinodeChatFeatures features = const TinodeChatFeatures(),
}) async {
  if (push is! MessagePush) {
    return false;
  }
  final state = push.callState;
  if (state == null) {
    return false;
  }
  final topic = push.topic;
  if (TopicKind.of(topic) != TopicKind.direct) {
    return true;
  }

  if (push.replacesSeq case final seq?) {
    if (state == CallState.accepted || state.isOver) {
      await systemCalls.stopRinging(
        topic,
        seq,
        missed: state == CallState.missed,
      );
    }
    return true;
  }

  final seq = push.seq;
  final age = switch (push.sentAt) {
    final sentAt? => clock.now().difference(sentAt),
    null => Duration.zero,
  };
  if (state != CallState.started ||
      seq == null ||
      age >= callPushLifetime ||
      !features.allowsCall(audioOnly: push.audioOnly)) {
    return true;
  }
  final callerName = await cachedCallerName(storeOpener, config.server, topic);
  if (token != null) {
    await registerHangUp?.call();
  }
  await systemCalls.ring(
    SystemCall(
      topic: topic,
      seq: seq,
      direction: CallDirection.incoming,
      audioOnly: push.audioOnly,
      callerName: callerName,
      hangUpWith: token == null
          ? null
          : HangUpCredentials(
              server: config.server,
              apiKey: config.apiKey,
              userAgent: config.userAgent,
              token: token,
            ),
    ),
    ringFor: callPushLifetime - (age.isNegative ? Duration.zero : age),
  );
  return true;
}

/// The name of the 1:1 chat [topic] in the cache of the user who last
/// logged in to [server]; null when there is none, or it takes too long.
Future<String?> cachedCallerName(
  ChatStoreOpener opener,
  Uri server,
  String topic,
) async {
  try {
    return await () async {
      final user = await opener.lastUser(server);
      if (user == null) {
        return null;
      }
      final store = await opener.open(server, user);
      try {
        return switch ((await store.chat(topic))?.public?.name?.trim()) {
          final name? when name.isNotEmpty => name,
          _ => null,
        };
      } finally {
        await store.close();
      }
    }().timeout(callerNameTimeout);
  } on Object {
    return null;
  }
}
