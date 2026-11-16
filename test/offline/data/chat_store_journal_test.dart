import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';

import '../../support/fixtures.dart';

/// How the cache's file is written: a write-ahead log synced at its
/// checkpoints, the outbox synced as it commits. On real files in a folder
/// of their own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final server = Uri.parse('ws://localhost:6060');
  late Directory dir;
  late DeviceChatStoreOpener opener;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('chat_store_journal_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    // Drift asks for a temporary folder; the plugin isn't here in tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => dir.path,
        );
    opener = DeviceChatStoreOpener(directory: () async => dir);
  });

  const cacheName = 'tinode_localhost_6060_$alice.sqlite';

  /// The journal mode of [db], a connection of its own to a file.
  Future<String> journalOf(GeneratedDatabase db) async {
    addTearDown(db.close);
    final row = await db.customSelect('PRAGMA journal_mode').getSingle();
    return '${row.data.values.single}';
  }

  File inDir(String name) => File('${dir.path}/$name');

  /// A store on a file of the cache's journal mode, every statement it runs
  /// in [log].
  ChatStore open(List<String> log) => ChatStore(
    ChatDatabase(
      NativeDatabase(
        File('${dir.path}/cache.sqlite'),
        setup: (db) => db.execute('PRAGMA journal_mode = WAL'),
      ).interceptWith(_Recorder(log)),
    ),
  );

  test('the cache keeps a write-ahead log; the call log does not', () async {
    final store = await opener.open(server, alice);
    await store.replaceChats([chat(bob)]);
    final log = await opener.openCallLog(server, alice);
    await log.put([callMessage(bob, 1)]);

    expect(inDir('$cacheName-wal').existsSync(), isTrue);
    await store.close();
    await log.close();

    expect(
      await journalOf(ChatDatabase(NativeDatabase(inDir(cacheName)))),
      'wal',
    );
    expect(
      await journalOf(
        CallLogDatabase(
          NativeDatabase(inDir('tinode_localhost_6060_${alice}_calls.sqlite')),
        ),
      ),
      'delete',
    );
  });

  test('what was queued is there after the cache is opened again', () async {
    final store = await opener.open(server, alice);
    await store.enqueuePublish(bob, 'cid-1', const PlainText('hi'), at(1));
    await store.close();

    final again = await opener.open(server, alice);
    addTearDown(again.close);
    expect((await again.outbox()).single.clientId, 'cid-1');
  });

  test('deleting the cache deletes its log too', () async {
    final store = await opener.open(server, alice);
    await store.replaceChats([chat(bob)]);
    await store.close();

    await opener.delete(server, alice);

    expect(
      dir.listSync().map((f) => f.path).where((p) => p.contains(cacheName)),
      isEmpty,
    );
  });

  test('the outbox syncs as it commits, then the rest goes back to the '
      'checkpoints', () async {
    final log = <String>[];
    final store = open(log);
    addTearDown(store.close);
    await store.replaceChats([chat(bob)]);
    log.clear();

    final entry = await store.enqueuePublish(
      bob,
      'cid-1',
      const PlainText('hello'),
      at(1),
    );
    await store.updateOutbox(entry.id, inFlight: true);
    await store.advanceChat(bob, lastSeq: 2);

    final pragmas = log.where((s) => s.startsWith('PRAGMA synchronous'));
    expect(pragmas, [
      'PRAGMA synchronous = FULL',
      'PRAGMA synchronous = NORMAL',
      'PRAGMA synchronous = FULL',
      'PRAGMA synchronous = NORMAL',
    ]);
    final insert = log.indexWhere((s) => s.contains('INSERT INTO "outbox"'));
    expect(insert, greaterThan(log.indexOf('PRAGMA synchronous = FULL')));
    expect(insert, lessThan(log.indexOf('PRAGMA synchronous = NORMAL')));
  });

  test('outbox writes that overlap share the stricter sync', () async {
    final log = <String>[];
    final store = open(log);
    addTearDown(store.close);
    await store.replaceChats([chat(bob)]);
    log.clear();

    await Future.wait([
      for (var i = 0; i < 3; i++)
        store.enqueuePublish(bob, 'cid-$i', const PlainText('hi'), at(i)),
    ]);

    expect(log.where((s) => s.startsWith('PRAGMA synchronous')), [
      'PRAGMA synchronous = FULL',
      'PRAGMA synchronous = NORMAL',
    ]);
  });

  test('a cache in memory has no log, and no outbox write changes how it '
      'syncs', () async {
    final log = <String>[];
    final store = ChatStore(
      ChatDatabase(NativeDatabase.memory().interceptWith(_Recorder(log))),
    );
    addTearDown(store.close);

    await store.enqueuePublish(bob, 'cid-1', const PlainText('hi'), at(1));

    expect(log.where((s) => s.startsWith('PRAGMA synchronous')), isEmpty);
  });
}

/// Writes down every statement run.
final class _Recorder extends QueryInterceptor {
  _Recorder(this.log);

  final List<String> log;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    log.add(statement);
    return super.runSelect(executor, statement, args);
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    log.add(statement);
    return super.runInsert(executor, statement, args);
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    log.add(statement);
    return super.runUpdate(executor, statement, args);
  }

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    log.add(statement);
    return super.runCustom(executor, statement, args);
  }
}
