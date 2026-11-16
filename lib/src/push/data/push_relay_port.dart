import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/push/data/port_names.dart';
import 'package:tinode_flutter_chat/src/push/domain/tinode_push_names.dart';

/// How long the app's session may take to say it took a push before the
/// push service's isolate handles it alone: a port left by an app that is
/// gone never answers.
const relayAckTimeout = Duration(seconds: 1);

/// What the app's session answers first, as soon as it has a push.
const _taken = 'taken';

/// The name [AppPushPort] takes among the [PortNames] for [server].
String pushRelayName(Uri server) =>
    'tinode_flutter_chat.push.${server.host}:${server.port}';

/// Hands [push] to the app's own session for [server] when one lives in
/// this process, found among [names], e.g. the app is in the background
/// rather than closed, and returns the names it answers with; null when
/// there is no session to take it. One that took it but doesn't finish
/// within [timeout] gets no names.
Future<TinodePushNames?> relayToApp(
  PortNames names,
  Uri server,
  TinodePush push, {
  required Duration timeout,
}) async {
  final name = pushRelayName(server);
  final app = names.lookup(name);
  if (app == null) {
    return null;
  }
  final reply = ReceivePort();
  final answers = StreamIterator<Object?>(reply);
  try {
    app.send({'push': push.raw, 'reply': reply.sendPort});
    final took = await answers.moveNext().timeout(
      relayAckTimeout,
      onTimeout: () => false,
    );
    if (!took || answers.current != _taken) {
      // Left by an app that is gone.
      if (names.lookup(name) == app) {
        names.remove(name);
      }
      return null;
    }
    final done = await answers.moveNext().timeout(
      timeout,
      onTimeout: () => false,
    );
    return switch (done ? answers.current : null) {
      {'chat': final String? chat, 'sender': final String? sender} =>
        TinodePushNames(chat: chat, sender: sender),
      _ => const TinodePushNames(),
    };
  } finally {
    unawaited(answers.cancel());
    reply.close();
  }
}

/// The app's end of [relayToApp]: while open, it takes a server's pushes
/// from the push service's isolate and answers with the names its handler
/// returns.
final class AppPushPort {
  AppPushPort.open(this._names, Uri server, this._handle)
    : _name = pushRelayName(server) {
    _names.register(_port.sendPort, _name);
    _port.listen((message) => unawaited(_onMessage(message)));
  }

  final PortNames _names;
  final String _name;
  final _port = ReceivePort();
  final Future<TinodePushNames> Function(TinodePush push) _handle;

  Future<void> _onMessage(Object? message) async {
    if (message case {
      'push': final Map<Object?, Object?> raw,
      'reply': final SendPort reply,
    }) {
      reply.send(_taken);
      var names = const TinodePushNames();
      try {
        if (TinodePush.tryParse(raw.cast<String, Object?>()) case final push?) {
          names = await _handle(push);
        }
      } on Object catch (e, stackTrace) {
        log(
          'Could not handle a push in the app',
          name: 'tinode_flutter_chat',
          error: e,
          stackTrace: stackTrace,
        );
      } finally {
        reply.send({'chat': names.chat, 'sender': names.sender});
      }
    }
  }

  void close() {
    if (_names.lookup(_name) == _port.sendPort) {
      _names.remove(_name);
    }
    _port.close();
  }
}
