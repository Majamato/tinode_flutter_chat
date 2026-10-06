import 'dart:async';
import 'dart:developer';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

/// A [TinodeSession] over a real `TinodeClient`.
final class ClientTinodeSession implements TinodeSession {
  ClientTinodeSession(this._client) {
    _events = _client.events.listen(_route, onError: _onError, onDone: _onDone);
  }

  /// Connects and performs the `hi` handshake. An unreachable server
  /// throws [ServerUnreachableException].
  static Future<TinodeSession> connect(TinodeConfig config) async =>
      ClientTinodeSession(await TinodeClient.connect(config));

  final TinodeClient _client;
  late final StreamSubscription<ServerMessage> _events;
  final _messages = StreamController<DataMessage>.broadcast();
  final _presence = StreamController<PresMessage>.broadcast();
  final _info = StreamController<InfoMessage>.broadcast();

  @override
  Stream<DataMessage> get messages => _messages.stream;

  @override
  Stream<PresMessage> get presence => _presence.stream;

  @override
  Stream<InfoMessage> get info => _info.stream;

  @override
  ConnectionStatus get status => _client.status;

  @override
  Stream<ConnectionStatus> get statusChanges => _client.statusChanges;

  @override
  Future<LoginResult> loginBasic(String login, String password) =>
      _client.loginBasic(login, password);

  @override
  Future<LoginResult> loginToken(String token) => _client.loginToken(token);

  @override
  Future<String> attach(String topic) => _client.subscribe(topic);

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
    int? since,
    int? before,
  }) => _client.getMessages(topic, since: since, before: before, limit: limit);

  @override
  Future<PublishResult> publish(String topic, MessageContent content) =>
      _client.publish(topic, content);

  @override
  void sendTyping(String topic) => _client.sendTyping(topic);

  @override
  void markRead(String topic, int seq) => _client.markRead(topic, seq);

  @override
  void suspend() => _client.suspend();

  @override
  void resume({Duration? probeTimeout}) =>
      _client.resume(probeTimeout: probeTimeout);

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

  /// The client's events end only when it is closed for good.
  void _onDone() {
    unawaited(_events.cancel());
    unawaited(_messages.close());
    unawaited(_presence.close());
    unawaited(_info.close());
  }
}
