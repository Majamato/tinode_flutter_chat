import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/offline/data/cached_tinode_session.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

/// The real opener on real SQLite files: what memory can't show, such as
/// which file a delete takes, or what is left after the app is killed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final server = Uri.parse('ws://localhost:6060');
  final elsewhere = Uri.parse('wss://chat.example.com');
  late Directory dir;
  late DeviceChatStoreOpener opener;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('call_log_file_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    // Drift asks for a temporary folder; the plugin isn't here in tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => dir.path,
        );
    opener = DeviceChatStoreOpener(directory: () async => dir);
  });

  File inDir(String name) => File('${dir.path}/$name');

  List<String> files() => [
    for (final entity in dir.listSync())
      entity.path.substring(dir.path.length + 1),
  ]..sort();

  const cacheName = 'tinode_localhost_6060_$alice.sqlite';
  const logName = 'tinode_localhost_6060_${alice}_calls.sqlite';

  Future<void> fillLog({Uri? on, String user = alice}) async {
    final log = await opener.openCallLog(on ?? server, user);
    await log.put([callMessage(bob, 1)]);
    await log.close();
  }

  Future<void> fillCache({Uri? on, String user = alice}) async {
    final store = await opener.open(on ?? server, user);
    await store.putMessages(bob, [message(bob, 1)]);
    await store.close();
  }

  Future<List<int>> logged({Uri? on, String user = alice}) async {
    final log = await opener.openCallLog(on ?? server, user);
    final calls = await log.calls();
    await log.close();
    return [for (final call in calls) call.message.seq];
  }

  group('file names', () {
    test('the cache keeps its name; the log has its own', () async {
      await fillCache();
      await fillLog();

      expect(inDir(cacheName).existsSync(), isTrue);
      expect(inDir(logName).existsSync(), isTrue);
    });
  });

  group('delete', () {
    test('takes the cache, and leaves the log with its data', () async {
      await fillCache();
      await fillLog();

      await opener.delete(server, alice);

      expect(inDir(cacheName).existsSync(), isFalse);
      expect(inDir(logName).existsSync(), isTrue);
      expect(await logged(), [1]);
    });

    test('takes what is left beside the cache, not beside the log', () async {
      await fillCache();
      await fillLog();
      for (final extra in ['-wal', '-shm', '-journal']) {
        inDir('$cacheName$extra').writeAsStringSync('cache');
        inDir('$logName$extra').writeAsStringSync('log');
      }

      await opener.delete(server, alice);

      expect(files(), [
        logName,
        '$logName-journal',
        '$logName-shm',
        '$logName-wal',
      ]);
    });

    test('of a user with no files does nothing', () async {
      await opener.delete(server, alice);
      await opener.deleteCallLog(server, alice);

      expect(files(), isEmpty);
    });
  });

  group('deleteCallLog', () {
    test('takes the log and all beside it, not the cache', () async {
      await fillCache();
      await fillLog();
      for (final extra in ['-wal', '-shm', '-journal']) {
        inDir('$logName$extra').writeAsStringSync('log');
      }

      await opener.deleteCallLog(server, alice);

      expect(files(), [cacheName]);
    });

    test('and a log opened afterwards is empty', () async {
      await fillLog();

      await opener.deleteCallLog(server, alice);

      expect(await logged(), isEmpty);
    });
  });

  group('others on the device', () {
    test('another user is never touched', () async {
      await fillLog();
      await fillLog(user: carol);
      await fillCache(user: carol);

      await opener.delete(server, alice);
      await opener.deleteCallLog(server, alice);

      expect(await logged(user: carol), [1]);
      expect(inDir('tinode_localhost_6060_$carol.sqlite').existsSync(), isTrue);
    });

    test('the same user on another server is never touched', () async {
      await fillLog();
      await fillLog(on: elsewhere);

      await opener.deleteCallLog(server, alice);

      expect(await logged(on: elsewhere), [1]);
    });

    test('two users have two logs', () async {
      await fillLog();

      expect(await logged(user: carol), isEmpty);
    });
  });

  group('the data', () {
    test('survives closing and opening', () async {
      final log = await opener.openCallLog(server, alice);
      await log.put([
        callMessage(bob, 1),
        callUpdate(bob, 2, 1, CallState.finished),
      ]);
      await log.close();

      final again = await opener.openCallLog(server, alice);
      addTearDown(again.close);
      final call = (await again.calls()).single;
      expect(call.updates.single.head?.callState, CallState.finished);
    });

    test('survives the app being killed: nothing was closed', () async {
      final killed = await opener.openCallLog(server, alice);
      addTearDown(killed.close);
      await killed.put([callMessage(bob, 1)]);

      final next = DeviceChatStoreOpener(directory: () async => dir);
      final log = await next.openCallLog(server, alice);
      addTearDown(log.close);

      expect(await log.calls(), hasLength(1));
    });

    test('a failed write leaves the file as it was', () async {
      final file = inDir('direct.sqlite');
      final db = CallLogDatabase(NativeDatabase(file));
      final log = CallLog(db);
      await log.put([callMessage(bob, 1)]);

      await expectLater(
        db.transaction(() async {
          await log.put([callMessage(bob, 2)]);
          throw StateError('the disk is full');
        }),
        throwsStateError,
      );
      await log.close();

      final again = CallLog(CallLogDatabase(NativeDatabase(file)));
      addTearDown(again.close);
      expect(await again.calls(), hasLength(1));
    });
  });

  group('two connections at once, as when a session is rebuilt', () {
    test('lose no write', () async {
      // Opened as the app does: the old session's was read long ago.
      final old = await openCallLogOrFallBack(opener, server, alice);
      addTearDown(old.close);
      final fresh = await openCallLogOrFallBack(opener, server, alice);
      addTearDown(fresh.close);

      await Future.wait([
        for (var seq = 1; seq <= 60; seq += 2) old.put([callMessage(bob, seq)]),
        for (var seq = 2; seq <= 60; seq += 2)
          fresh.put([callMessage(bob, seq)]),
      ]);

      expect(await fresh.calls(), hasLength(60));
    });

    test('creating the file at the same moment costs at most one session '
        'its file: the other works, and so does the next', () async {
      final logs = await Future.wait([
        openCallLogOrFallBack(opener, server, alice),
        openCallLogOrFallBack(opener, server, alice),
      ]);
      addTearDown(() => Future.wait(logs.map((log) => log.close())));

      for (final log in logs) {
        await log.put([callMessage(bob, 1)]);
        expect(await log.calls(), hasLength(1));
      }

      final next = await openCallLogOrFallBack(opener, server, alice);
      addTearDown(next.close);
      await next.put([callMessage(bob, 2)]);
      expect(await logged(), contains(2));
    });
  });

  group('a file that cannot be read', () {
    for (final (name, damage) in [
      ('garbage', (File file) => file.writeAsStringSync('not a database' * 90)),
      (
        'cut short',
        (File file) =>
            file.writeAsBytesSync(file.readAsBytesSync().sublist(0, 2000)),
      ),
      (
        'with a broken header',
        (File file) => file.writeAsBytesSync([
          ...List.filled(100, 0xFF),
          ...file.readAsBytesSync().skip(100),
        ]),
      ),
    ]) {
      test('$name: the log falls back to memory and works', () async {
        await fillLog();
        damage(inDir(logName));

        final log = await openCallLogOrFallBack(opener, server, alice);
        addTearDown(log.close);

        await log.put([callMessage(carol, 2)]);
        expect(await log.calls(), hasLength(1));
        expect((await log.calls()).single.message.topic, carol);
      });
    }

    test('stays as it was, for someone to rescue', () async {
      inDir(logName).writeAsStringSync('not a database' * 90);
      final before = inDir(logName).readAsBytesSync();

      final log = await openCallLogOrFallBack(opener, server, alice);
      addTearDown(log.close);

      expect(inDir(logName).readAsBytesSync(), before);
    });

    test('a good file opens as itself, not as the fallback', () async {
      await fillLog();

      final log = await openCallLogOrFallBack(opener, server, alice);
      addTearDown(log.close);

      expect(await log.calls(), hasLength(1));
    });
  });

  group('an app updated from before the log', () {
    /// The cache file as the last version left it.
    Future<void> oldCache() async {
      final store = ChatStore(ChatDatabase(NativeDatabase(inDir(cacheName))));
      await store.replaceChats([chat(bob)]);
      await store.putMessages(bob, covering: const SeqRange(1, 4), [
        callMessage(bob, 1),
        callUpdate(bob, 2, 1, CallState.finished),
        callMessage(bob, 3),
      ]);
      await store.close();
    }

    CachedTinodeSession session(ChatStore store, CallLog log) =>
        CachedTinodeSession(
          FakeTinodeSession(chats: [chat(bob)]),
          store,
          userId: alice,
          calls: log,
        );

    test('keeps its calls, and then through a logout', () async {
      await oldCache();

      var active = session(
        await opener.open(server, alice),
        await opener.openCallLog(server, alice),
      );
      expect(await active.storedCalls(), hasLength(2));
      await active.close();

      await opener.delete(server, alice);

      active = session(
        await opener.open(server, alice),
        await opener.openCallLog(server, alice),
      );
      addTearDown(active.close);
      final calls = await active.storedCalls();
      expect(calls.map((c) => c.message.seq), [1, 3]);
      expect(calls.first.updates.single.seq, 2);
    });
  });

  group('the app on real files', () {
    Future<ProviderContainer> start(List<FakeTinodeSession> links) async {
      final container =
          createTestContainer(
              connector: (_) async => links.removeAt(0),
              storeOpener: opener,
              credentials: const TinodeCredentials.password(
                'alice',
                'alice123',
              ),
            )
            ..listen(sessionControllerProvider, (_, _) {})
            ..listen(chatListControllerProvider, (_, _) {})
            ..listen(callHistoryControllerProvider, (_, _) {});
      await container.read(sessionControllerProvider.future);
      return container;
    }

    FakeTinodeSession link() => FakeTinodeSession(
      chats: [chat(bob, lastSeq: 1, lastMessageAt: at(1))],
      histories: {
        bob: [callMessage(bob, 1)],
      },
    );

    Future<void> until(bool Function() done) async {
      for (var i = 0; i < 400 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(done(), isTrue, reason: 'timed out');
    }

    test('logging out deletes one file and keeps the other', () async {
      final container = await start([link(), link()]);
      await until(
        () => container.read(callHistoryControllerProvider).ids.isNotEmpty,
      );

      await container.read(sessionControllerProvider.notifier).logout();
      await container.read(sessionControllerProvider.future);

      expect(inDir(cacheName).existsSync(), isFalse);
      expect(inDir(logName).existsSync(), isTrue);

      await container
          .read(sessionControllerProvider.notifier)
          .login(const TinodeCredentials.password('alice', 'alice123'));
      await until(
        () => container.read(callHistoryControllerProvider).ids.isNotEmpty,
      );
    });

    test('deleting the account deletes both', () async {
      final container = await start([link(), link()]);
      await until(
        () => container.read(callHistoryControllerProvider).ids.isNotEmpty,
      );

      await container.read(sessionControllerProvider.notifier).deleteAccount();
      await container.read(sessionControllerProvider.future);

      expect(inDir(cacheName).existsSync(), isFalse);
      expect(inDir(logName).existsSync(), isFalse);
    });
  });

  group('who logged in last', () {
    test('is kept in the same folder, and forgotten', () async {
      await opener.rememberUser(server, alice);

      expect(await opener.lastUser(server), alice);
      expect(await opener.lastUser(elsewhere), isNull);

      await opener.forgetUser(server);

      expect(await opener.lastUser(server), isNull);
    });
  });
}
