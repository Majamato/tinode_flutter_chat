import 'dart:async';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

/// A scripted [TinodeSession]: chats and histories are plain fields, and
/// tests push server traffic with [emitMessage] and [emitPresence].
final class FakeTinodeSession implements TinodeSession {
  FakeTinodeSession({
    this.userId = 'usrAlice',
    Map<String, String>? passwords,
    List<Subscription>? chats,
    Map<String, List<DataMessage>>? histories,
  }) : passwords = passwords ?? {'alice': 'alice123'},
       chats = chats ?? [],
       histories = histories ?? {};

  final String userId;
  final Map<String, String> passwords;
  final List<Subscription> chats;
  final Map<String, List<DataMessage>> histories;

  /// Every call, e.g. `attach usrBob` or `markRead usrBob 3`.
  final calls = <String>[];

  /// When set, `history` waits for it before answering.
  Completer<void>? holdHistory;

  /// When set, the next `chatList`, `history` or `publish` throws it.
  Exception? failChatList;
  Exception? failHistory;
  Exception? failPublish;

  /// Whether `publish` echoes the message back like the server does.
  bool echo = true;

  final _messages = StreamController<DataMessage>.broadcast(sync: true);
  final _presence = StreamController<PresMessage>.broadcast(sync: true);
  final _info = StreamController<InfoMessage>.broadcast(sync: true);
  // Sync, like the stream controllers: a fake made in `setUp` lives outside
  // a widget test's fake-async zone, where async callbacks would never run.
  final _closed = Completer<void>.sync();
  bool get isClosed => _closed.isCompleted;

  String get token => 'token-$userId';

  void emitMessage(DataMessage message) => _messages.add(message);

  void emitPresence(PresMessage presence) => _presence.add(presence);

  /// Simulates the server dropping the connection.
  void dropConnection() {
    if (!_closed.isCompleted) _closed.complete();
  }

  @override
  Stream<DataMessage> get messages => _messages.stream;

  @override
  Stream<PresMessage> get presence => _presence.stream;

  @override
  Stream<InfoMessage> get info => _info.stream;

  @override
  Future<void> get closed => _closed.future;

  @override
  Future<LoginResult> loginBasic(String login, String password) async {
    calls.add('loginBasic $login');
    if (passwords[login] != password) {
      throw const ServerException(401, 'authentication failed');
    }
    return LoginResult(userId: userId, token: token);
  }

  @override
  Future<LoginResult> loginToken(String token) async {
    calls.add('loginToken');
    if (token != this.token) {
      throw const ServerException(401, 'authentication failed');
    }
    return LoginResult(userId: userId, token: token);
  }

  @override
  Future<String> attach(String topic) async {
    calls.add('attach $topic');
    return topic;
  }

  @override
  Future<void> detach(String topic) async => calls.add('detach $topic');

  @override
  Future<List<Subscription>> chatList() async {
    calls.add('chatList');
    if (failChatList case final error?) {
      failChatList = null;
      throw error;
    }
    return List.of(chats);
  }

  @override
  Future<List<DataMessage>> history(
    String topic, {
    required int limit,
    int? before,
  }) async {
    calls.add('history $topic${before == null ? '' : ' before $before'}');
    await holdHistory?.future;
    if (failHistory case final error?) {
      failHistory = null;
      throw error;
    }
    final all = [
      for (final m in histories[topic] ?? const <DataMessage>[])
        if (before == null || m.seq < before) m,
    ]..sort((a, b) => a.seq.compareTo(b.seq));
    return all.length <= limit ? all : all.sublist(all.length - limit);
  }

  @override
  Future<PublishResult> publish(String topic, MessageContent content) async {
    calls.add('publish $topic ${content.text}');
    if (failPublish case final error?) {
      failPublish = null;
      throw error;
    }
    final history = histories.putIfAbsent(topic, () => []);
    final seq = history.fold(0, (max, m) => m.seq > max ? m.seq : max) + 1;
    final time = DateTime.utc(2026, 10, 4, 12).add(Duration(seconds: seq));
    final sent = DataMessage(
      topic: topic,
      seq: seq,
      time: time,
      from: userId,
      content: content,
    );
    history.add(sent);
    if (echo) scheduleMicrotask(() => emitMessage(sent));
    return PublishResult(seq: seq, time: time);
  }

  @override
  void sendTyping(String topic) => calls.add('sendTyping $topic');

  @override
  void markRead(String topic, int seq) => calls.add('markRead $topic $seq');

  @override
  Future<void> close() async {
    calls.add('close');
    dropConnection();
  }
}

/// A connector that hands out [session], or fails with [error].
SessionConnector connectTo(FakeTinodeSession session, {Exception? error}) =>
    (_) async => error == null ? session : throw error;
