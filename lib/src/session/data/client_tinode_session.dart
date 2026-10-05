import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:web_socket/web_socket.dart';

/// A [TinodeSession] over a real `TinodeClient`.
final class ClientTinodeSession implements TinodeSession {
  ClientTinodeSession(this._client) {
    _events = _client.events.listen(_route, onError: _onError, onDone: _onDone);
  }

  /// Connects and performs the `hi` handshake. An unreachable server
  /// throws [ServerUnreachableException]: a refused or failed connection
  /// surfaces as a raw [SocketException], which `web_socket` doesn't wrap.
  static Future<TinodeSession> connect(TinodeConfig config) async {
    try {
      return ClientTinodeSession(await TinodeClient.connect(config));
    } on WebSocketException catch (e) {
      throw ServerUnreachableException(e.message);
    } on SocketException catch (e) {
      throw ServerUnreachableException(e.message);
    }
  }

  /// How often [attach] tries before giving up on a locked topic.
  static const attachAttempts = 4;

  /// The wait before the second attach; later waits grow linearly.
  static const attachRetryDelay = Duration(milliseconds: 200);

  final TinodeClient _client;
  late final StreamSubscription<ServerMessage> _events;
  final _messages = StreamController<DataMessage>.broadcast();
  final _presence = StreamController<PresMessage>.broadcast();
  final _info = StreamController<InfoMessage>.broadcast();
  final _closed = Completer<void>();

  @override
  Stream<DataMessage> get messages => _messages.stream;

  @override
  Stream<PresMessage> get presence => _presence.stream;

  @override
  Stream<InfoMessage> get info => _info.stream;

  @override
  Future<void> get closed => _closed.future;

  @override
  Future<LoginResult> loginBasic(String login, String password) =>
      _client.loginBasic(login, password);

  @override
  Future<LoginResult> loginToken(String token) => _client.loginToken(token);

  /// Attaching retries a `503 locked` reply: the server sends it while it
  /// is still loading the topic, e.g. when both sides of a P2P chat attach
  /// at the same moment.
  @override
  Future<String> attach(String topic) async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await _client.subscribe(topic);
      } on ServerException catch (e) {
        if (e.code != 503 || attempt >= attachAttempts) rethrow;
        await Future<void>.delayed(attachRetryDelay * attempt);
      }
    }
  }

  @override
  Future<void> detach(String topic) => _client.leave(topic);

  @override
  Future<List<Subscription>> chatList() async => [
    for (final s in await _client.getSubscriptions('me'))
      if (s.topic != null) s,
  ];

  @override
  Future<List<DataMessage>> history(
    String topic, {
    required int limit,
    int? before,
  }) => _client.getMessages(topic, before: before, limit: limit);

  @override
  Future<PublishResult> publish(String topic, MessageContent content) =>
      _client.publish(topic, content);

  @override
  void sendTyping(String topic) => _client.sendTyping(topic);

  @override
  void markRead(String topic, int seq) => _client.markRead(topic, seq);

  @override
  Future<void> close() async {
    await _client.close();
    _onDone();
  }

  void _route(ServerMessage message) {
    switch (message) {
      case final DataMessage m:
        _messages.add(m);
      case final PresMessage m:
        _presence.add(m);
      case final InfoMessage m:
        _info.add(m);
      case CtrlMessage() || MetaMessage():
        break;
    }
  }

  /// Malformed packets are dropped: one bad packet must not end the chat.
  void _onError(Object error, StackTrace stackTrace) => log(
    'Dropped a server packet',
    name: 'tinode_flutter_chat',
    error: error,
    stackTrace: stackTrace,
  );

  void _onDone() {
    if (_closed.isCompleted) return;
    _closed.complete();
    unawaited(_events.cancel());
    unawaited(_messages.close());
    unawaited(_presence.close());
    unawaited(_info.close());
  }
}
