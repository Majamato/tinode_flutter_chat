import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/search/domain/message_match.dart';

import '../../support/fixtures.dart';
import 'generated_migrations/schema.dart';

// The schemas come from drift_schemas/. After a schema change: dump it,
// then `dart run drift_dev schema generate drift_schemas/
// test/offline/data/generated_migrations/`.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  for (final from in [1, 2]) {
    test('v$from upgrades to the current schema', () async {
      final db = ChatDatabase(await verifier.startAt(from));
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);
    });
  }

  test('a v1 cache keeps its data and gains members', () async {
    const stored =
        '{"topic":"$bob","seq":3,"ts":"2026-10-04T09:03:00.000Z",'
        '"content":"hi"}';
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase
      ..execute('INSERT INTO chats (topic, json) VALUES (?, ?)', [
        bob,
        '{"topic":"$bob","seq":3}',
      ])
      ..execute('INSERT INTO messages (topic, seq, json) VALUES (?, ?, ?)', [
        bob,
        3,
        stored,
      ]);

    final store = ChatStore(ChatDatabase(schema.newConnection()));
    addTearDown(store.close);
    expect((await store.chat(bob))?.lastSeq, 3);
    expect(
      (await store.messagesIn(bob, from: 1, before: 9, limit: 9)).single.seq,
      3,
    );
    await store.putMember(friends, member(bob, name: 'Bob'));
    expect((await store.members(friends)).single.public?.name, 'Bob');
  });

  test('a v2 cache makes its stored messages searchable', () async {
    const drafty =
        '{"topic":"$bob","seq":2,"ts":"2026-10-04T09:02:00.000Z",'
        '"content":{"txt":"Un café"}}';
    const update =
        '{"topic":"$bob","seq":3,"ts":"2026-10-04T09:03:00.000Z",'
        '"head":{"replace":":2"},"content":"café update"}';
    final schema = await verifier.schemaAt(2);
    schema.rawDatabase
      ..execute('INSERT INTO chats (topic, json) VALUES (?, ?)', [
        bob,
        '{"topic":"$bob","seq":3}',
      ])
      ..execute('INSERT INTO messages (topic, seq, json) VALUES (?, ?, ?)', [
        bob,
        2,
        drafty,
      ])
      ..execute('INSERT INTO messages (topic, seq, json) VALUES (?, ?, ?)', [
        bob,
        3,
        update,
      ]);

    final store = ChatStore(ChatDatabase(schema.newConnection()));
    addTearDown(store.close);
    final found = await store.searchMessages(
      bob,
      messageMatch('cafe')!,
      limit: 5,
    );
    expect([for (final f in found) f.seq], [2]);
  });
}
