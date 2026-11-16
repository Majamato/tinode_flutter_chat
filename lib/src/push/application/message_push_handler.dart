import 'dart:async';
import 'dart:developer';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/cached_tinode_session.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/push/data/port_names.dart';
import 'package:tinode_flutter_chat/src/push/data/push_relay_port.dart';
import 'package:tinode_flutter_chat/src/push/data/stored_push_names.dart';
import 'package:tinode_flutter_chat/src/push/domain/tinode_push_names.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

/// How long handling a push in the background may take before it gives up:
/// the app catches up when it opens anyway.
const backgroundPushTimeout = Duration(seconds: 15);

/// How long reading the names for the notification may take.
const pushNamesTimeout = Duration(seconds: 2);

/// Acts on a [push] that arrived while the app is in the background or
/// closed: a new message is fetched into the
/// cache and marked received while its chat is attached, so its sender
/// sees it delivered and the chat shows it offline; a read marker is kept;
/// a chat the cache lacks is fetched. Then it returns the names the
/// notification can show.
///
/// It works for the user who last logged in to [config]'s server, with
/// their [token]. While the app lives in this process its own session does
/// the work (`PushRelay`), found among [portNames]; otherwise this
/// connects, logs in with [token]
/// and fetches through a passive cached session, which never sends the
/// outbox. A new message the cache marked received already needs no
/// connection. Best effort, within [timeout]: failures are logged.
///
/// Returns null for a push it doesn't handle (a call, which `TinodeCalls`
/// handles), with no [token], or with no user on the device.
Future<TinodePushNames?> handleMessagePush(
  TinodePush push, {
  required TinodeConfig config,
  required String? token,
  required ChatStoreOpener storeOpener,
  required SessionConnector connect,
  required PortNames portNames,
  Duration timeout = backgroundPushTimeout,
}) async {
  if (!_handles(push) || token == null) {
    return null;
  }
  final server = config.server;
  final String? user;
  try {
    user = await storeOpener.lastUser(server);
  } on Object catch (e, stackTrace) {
    _log('Could not find the user for a push', e, stackTrace);
    return null;
  }
  if (user == null) {
    return null;
  }
  if (await relayToApp(portNames, server, push, timeout: timeout)
      case final names?) {
    return names;
  }

  ChatStore? store;
  TinodeSession? remote;
  CallLog? calls;
  CachedTinodeSession? session;
  try {
    await () async {
      final opened = store = await storeOpener.open(server, user!);
      if (!await _needsLink(opened, push)) {
        if (push case ReadPush(:final topic, seq: final seq?)) {
          await opened.advanceChat(topic, read: seq);
        }
        return;
      }
      final connected = remote = await connect(
        config.copyWith(background: true),
      );
      await connected.loginToken(token);
      calls = await storeOpener.openCallLog(server, user);
      session = CachedTinodeSession(
        connected,
        opened,
        userId: user,
        calls: calls,
        passive: true,
      );
      await session!.applyPush(push);
    }().timeout(timeout);
  } on Object catch (e, stackTrace) {
    _log('Could not fetch what a push announced', e, stackTrace);
  }
  try {
    return switch (store) {
      final store? => await storedPushNames(
        store,
        push,
      ).timeout(pushNamesTimeout),
      null => const TinodePushNames(),
    };
  } on Object {
    return const TinodePushNames();
  } finally {
    await _closeQuietly(session, remote, store, calls);
  }
}

/// The names the cache of the user who last logged in to [server] gives a
/// notification of [push], read at once and without the server; null with
/// no such user, or a cache that can't be read in time.
Future<TinodePushNames?> cachedPushNames(
  TinodePush push, {
  required Uri server,
  required ChatStoreOpener storeOpener,
}) async {
  try {
    return await () async {
      final user = await storeOpener.lastUser(server);
      if (user == null) {
        return null;
      }
      final store = await storeOpener.open(server, user);
      try {
        return await storedPushNames(store, push);
      } finally {
        await store.close();
      }
    }().timeout(pushNamesTimeout);
  } on Object {
    return null;
  }
}

bool _handles(TinodePush push) => switch (push) {
  MessagePush(seq: _?, callState: null) => true,
  ReadPush(seq: _?) || SubscriptionPush() => true,
  _ => false,
};

/// Whether [push] needs the server: a message the cache hasn't marked
/// received, or a chat it lacks.
Future<bool> _needsLink(ChatStore store, TinodePush push) async =>
    switch (push) {
      MessagePush(:final topic, seq: final seq?) =>
        ((await store.chat(topic))?.received ?? 0) < seq,
      SubscriptionPush(:final topic) => await store.chat(topic) == null,
      _ => false,
    };

Future<void> _closeQuietly(
  CachedTinodeSession? session,
  TinodeSession? remote,
  ChatStore? store,
  CallLog? calls,
) async {
  try {
    if (session != null) {
      // It closes the others.
      await session.close();
      return;
    }
    await remote?.close();
    await calls?.close();
    await store?.close();
  } on Object catch (e, stackTrace) {
    _log('Could not close after a push', e, stackTrace);
  }
}

void _log(String message, Object error, StackTrace stackTrace) => log(
  message,
  name: 'tinode_flutter_chat',
  error: error,
  stackTrace: stackTrace,
);
