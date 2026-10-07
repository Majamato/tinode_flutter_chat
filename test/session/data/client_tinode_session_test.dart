import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/data/client_tinode_session.dart';
import 'package:web_socket/testing.dart';
import 'package:web_socket/web_socket.dart';

import '../../support/test_container.dart';

/// Answers the client's requests the way a Tinode server would, just
/// enough for these tests.
final class _Server {
  _Server(this.socket) {
    socket.events.listen((event) {
      if (event case TextDataReceived(:final text)) {
        _answer(jsonDecode(text) as Map<String, Object?>);
      }
    });
  }

  final WebSocket socket;

  /// How many `sub` requests to answer with `503 locked` first.
  int lockedReplies = 0;

  /// How many `sub` requests to refuse with `403` first.
  int refusedReplies = 0;

  /// Every request as `<type> <topic>`, e.g. `sub usrBob`.
  final requests = <String>[];

  void send(Map<String, Object?> packet) => socket.sendText(jsonEncode(packet));

  void _answer(Map<String, Object?> packet) {
    final MapEntry(:key, :value) = packet.entries.single;
    final body = value! as Map<String, Object?>;
    final id = body['id'];
    final ts = DateTime.utc(2026).toIso8601String();
    requests.add('$key ${body['topic'] ?? ''}'.trim());
    switch (key) {
      case 'hi':
        send({
          'ctrl': {
            'id': id,
            'code': 201,
            'text': 'created',
            'ts': ts,
            'params': {'ver': '0.25'},
          },
        });
      case 'sub' when lockedReplies > 0:
        lockedReplies--;
        send({
          'ctrl': {'id': id, 'code': 503, 'text': 'locked', 'ts': ts},
        });
      case 'sub' when refusedReplies > 0:
        refusedReplies--;
        send({
          'ctrl': {'id': id, 'code': 403, 'text': 'forbidden', 'ts': ts},
        });
      case 'sub' || 'leave':
        send({
          'ctrl': {'id': id, 'code': 200, 'text': 'ok', 'ts': ts},
        });
      case 'get':
        send({
          'meta': {
            'id': id,
            'topic': 'me',
            'ts': ts,
            'sub': [
              {'topic': 'usrBob', 'seq': 2, 'read': 1},
              {'user': 'usrNoTopic'},
            ],
          },
        });
    }
  }
}

void main() {
  late _Server server;
  late ClientTinodeSession session;

  setUp(() async {
    final (client, serverSocket) = fakes();
    server = _Server(serverSocket);
    session = ClientTinodeSession(
      await TinodeClient.connect(testConfig, connector: (_) async => client),
    );
  });

  test('routes server packets to typed streams', () async {
    final message = session.messages.first;
    final presence = session.presence.first;

    server
      ..send({
        'pres': {'topic': 'me', 'what': 'msg', 'src': 'usrBob', 'seq': 3},
      })
      ..send({
        'data': {
          'topic': 'usrBob',
          'from': 'usrBob',
          'seq': 3,
          'ts': DateTime.utc(2026).toIso8601String(),
          'content': 'hi',
        },
      });

    expect((await message).content.text, 'hi');
    expect((await presence).event, PresenceEvent.message);
  });

  test('a malformed packet is dropped, not fatal', () async {
    final message = session.messages.first;

    server.socket.sendText('not json');
    server.send({
      'data': {
        'topic': 'usrBob',
        'seq': 4,
        'ts': DateTime.utc(2026).toIso8601String(),
        'content': 'still here',
      },
    });

    expect((await message).content.text, 'still here');
  });

  test('the chat list keeps only entries that name a topic', () async {
    final chats = await session.chatList();

    expect(chats.map((s) => s.topic), ['usrBob']);
  });

  test('attach rides out a topic the server reports locked', () async {
    server.lockedReplies = 2;

    expect(await session.attach('usrBob'), 'usrBob');
    expect(server.lockedReplies, 0);
  });

  group('attaches are counted', () {
    test('a second attach and the first detach stay local', () async {
      await session.attach('usrBob');
      await session.attach('usrBob');
      await session.detach('usrBob');
      expect(server.requests, ['hi', 'sub usrBob']);

      await session.detach('usrBob');
      expect(server.requests.last, 'leave usrBob');
    });

    test('overlapping attaches share one request', () async {
      await Future.wait([session.attach('usrBob'), session.attach('usrBob')]);
      expect(server.requests.where((r) => r == 'sub usrBob'), hasLength(1));

      await session.detach('usrBob');
      expect(server.requests.last, 'sub usrBob');
    });

    test('a failed attach holds nothing', () async {
      server.refusedReplies = 1;
      await expectLater(
        session.attach('usrBob'),
        throwsA(isA<ServerException>()),
      );

      await session.attach('usrBob');
      await session.detach('usrBob');
      expect(server.requests.last, 'leave usrBob');
    });
  });

  test('a dropped socket shows as reconnecting, not as the end', () async {
    final status = session.statusChanges.first;
    await server.socket.close(1000);

    expect(await status, isA<Reconnecting>());
  });

  test('a refused connection reports the server unreachable', () async {
    final closedPort = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closedPort.port;
    await closedPort.close();

    await expectLater(
      ClientTinodeSession.connect(
        TinodeConfig(
          server: Uri.parse('ws://127.0.0.1:$port'),
          apiKey: testConfig.apiKey,
          userAgent: testConfig.userAgent,
        ),
      ),
      throwsA(isA<ServerUnreachableException>()),
    );
  });
}
