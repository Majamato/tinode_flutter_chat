import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log_database.dart';

import '../../support/fixtures.dart';
import 'generated_call_log_migrations/schema.dart';

// The schemas come from drift_schemas/call_log/. A change to the table must
// bump `schemaVersion`, dump the schema there and add a step here that
// keeps the rows: unlike the cache, nothing in this file can be fetched
// again.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('the tables are the ones dumped for this version', () async {
    final db = CallLogDatabase(await verifier.startAt(1));
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);
  });

  test('a file of the first version reads as it was written', () async {
    const base =
        '{"topic":"$bob","seq":1,"ts":"2026-10-04T09:01:00.000Z",'
        '"head":{"webrtc":"started"},"content":" "}';
    const update =
        '{"topic":"$bob","seq":2,"ts":"2026-10-04T09:02:00.000Z",'
        '"head":{"webrtc":"finished","replace":":1"},"content":" "}';
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase
      ..execute(
        'INSERT INTO call_messages (topic, seq, replaces, json) '
        'VALUES (?, ?, ?, ?)',
        [bob, 1, null, base],
      )
      ..execute(
        'INSERT INTO call_messages (topic, seq, replaces, json) '
        'VALUES (?, ?, ?, ?)',
        [bob, 2, ':1', update],
      );

    final log = CallLog(CallLogDatabase(schema.newConnection()));
    addTearDown(log.close);

    final call = (await log.calls()).single;
    expect(call.message.seq, 1);
    expect(call.updates.single.seq, 2);
  });
}
