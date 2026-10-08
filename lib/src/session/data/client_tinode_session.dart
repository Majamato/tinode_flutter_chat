import 'dart:async';
import 'dart:developer';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

/// A [TinodeSession] over a real `TinodeClient`.
final class ClientTinodeSession implements TinodeSession {
  ClientTinodeSession(this._client) {
    _events = _client.events.listen(_route, onError: _onError, onDone: _onDone);
    _statuses = _client.statusChanges.listen(_forgetLost);
  }

  /// Connects and performs the `hi` handshake. An unreachable server
  /// throws [ServerUnreachableException].
  static Future<TinodeSession> connect(TinodeConfig config) async =>
      ClientTinodeSession(await TinodeClient.connect(config));

  /// Connects and logs in with [token] in the background.
  static Future<TinodeSession> restore(
    TinodeConfig config,
    String token,
  ) async => ClientTinodeSession(TinodeClient.restore(config, token: token));

  final TinodeClient _client;
  late final StreamSubscription<ServerMessage> _events;
  late final StreamSubscription<ConnectionStatus> _statuses;

  /// How many attaches hold each topic.
  final _holds = <String, int>{};

  /// Attaches waiting for the server, shared by callers that overlap.
  final _attaching = <String, Future<String>>{};
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
  Future<String> attach(String topic) async {
    if (_holds[topic] case final holds? when holds > 0) {
      _holds[topic] = holds + 1;
      return topic;
    }
    final name = await (_attaching[topic] ??= _subscribe(topic));
    _holds.update(topic, (holds) => holds + 1, ifAbsent: () => 1);
    return name;
  }

  @override
  Future<void> detach(String topic) async {
    final holds = _holds.remove(topic) ?? 0;
    if (holds > 1) {
      _holds[topic] = holds - 1;
      return;
    }
    await _client.leave(topic);
  }

  @override
  Future<List<Subscription>> chatList({DateTime? ifModifiedSince}) async => [
    for (final s in await _client.getSubscriptions(
      'me',
      ifModifiedSince: ifModifiedSince,
    ))
      if (s.topic != null) s,
  ];

  @override
  Future<List<FoundTopic>> find(String query) => _client.find(query);

  @override
  Future<String> createGroup({required Profile public}) async {
    final name = await _client.createGroup(public: public);
    _holds.update(name, (holds) => holds + 1, ifAbsent: () => 1);
    return name;
  }

  @override
  Future<void> addMember(String topic, String userId) =>
      _client.setSubscription(topic, userId: userId);

  @override
  Future<List<DataMessage>> history(
    String topic, {
    required int limit,
    int? since,
    int? before,
  }) => _client.getMessages(topic, since: since, before: before, limit: limit);

  @override
  Future<PublishResult> publish(
    String topic,
    MessageContent content, {
    Json? head,
  }) => _client.publish(topic, content, head: head);

  @override
  Future<int> deleteMessages(
    String topic,
    List<SeqRange> ranges, {
    required bool hard,
  }) => _client.deleteMessages(topic, ranges, hard: hard);

  @override
  Future<DeleteLog> deleteLog(String topic, {int? since, int? limit}) =>
      _client.getDeleteLog(topic, since: since, limit: limit);

  @override
  void sendTyping(String topic) => _client.sendTyping(topic);

  @override
  void markRead(String topic, int seq) => _client.markRead(topic, seq);

  @override
  ServerInfo get serverInfo => _client.serverInfo;

  @override
  Future<PublishResult> startCall(String topic, {required bool audioOnly}) =>
      _client.startCall(topic, audioOnly: audioOnly);

  @override
  void sendCallEvent(String topic, int seq, CallEvent event, {Json? payload}) =>
      _client.sendCallEvent(topic, seq, event, payload: payload);

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

  Future<String> _subscribe(String topic) async {
    try {
      return await _client.subscribe(topic);
    } finally {
      // The callers await this future already; the map's copy is spare.
      _attaching.remove(topic)?.ignore();
    }
  }

  /// A topic the server refused after a reconnect is no longer attached,
  /// so the next attach must go to the server again.
  void _forgetLost(ConnectionStatus status) {
    if (status case Connected(:final lostTopics)) {
      lostTopics.keys.forEach(_holds.remove);
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
    unawaited(_statuses.cancel());
    unawaited(_messages.close());
    unawaited(_presence.close());
    unawaited(_info.close());
  }
}
