import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log_database.dart';

import '../../support/fixtures.dart';
import '../../support/stored_calls.dart';
import 'generated_call_log_migrations/schema.dart';

// The schemas come from drift_schemas/call_log/. A change to the table must
// bump `schemaVersion`, dump the schema there and add a step here that
// keeps the rows: unlike the cache, nothing in this file can be fetched
// again.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  for (final from in [1, 2]) {
    test('v$from upgrades to the current schema', () async {
      final db = CallLogDatabase(await verifier.startAt(from));
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, db.schemaVersion);
    });
  }

  group('a file of the first version', () {
    const base =
        '{"topic":"$bob","seq":1,"ts":"2026-10-04T09:01:00.123Z",'
        '"head":{"webrtc":"started"},"content":" "}';
    const update =
        '{"topic":"$bob","seq":2,"ts":"2026-10-04T09:02:00.000Z",'
        '"head":{"webrtc":"finished","replace":":1"},"content":" "}';
    const later =
        '{"topic":"$carol","seq":5,"ts":"2026-10-04T09:05:00.000Z",'
        '"head":{"webrtc":"started"},"content":" "}';

    Future<CallLogDatabase> v1(
      List<(String, int, String?, String)> rows,
    ) async {
      final schema = await verifier.schemaAt(1);
      for (final (topic, seq, replaces, json) in rows) {
        schema.rawDatabase.execute(
          'INSERT INTO call_messages (topic, seq, replaces, json) '
          'VALUES (?, ?, ?, ?)',
          [topic, seq, replaces, json],
        );
      }
      return CallLogDatabase(schema.newConnection());
    }

    test('reads as it was written', () async {
      final log = CallLog(
        await v1([(bob, 1, null, base), (bob, 2, ':1', update)]),
      );
      addTearDown(log.close);

      final call = (await log.calls()).single;
      expect(call.message.seq, 1);
      expect(call.updates.single.seq, 2);
    });

    test('takes the time of each row from its JSON, to the ms', () async {
      final db = await v1([
        (bob, 1, null, base),
        (bob, 2, ':1', update),
        (carol, 5, null, later),
      ]);
      addTearDown(db.close);

      final times = {
        for (final row in await db.select(db.callMessages).get())
          (row.topic, row.seq): row.time,
      };
      expect(times, {
        (bob, 1): DateTime.parse(
          '2026-10-04T09:01:00.123Z',
        ).millisecondsSinceEpoch,
        (bob, 2): DateTime.parse(
          '2026-10-04T09:02:00.000Z',
        ).millisecondsSinceEpoch,
        (carol, 5): DateTime.parse(
          '2026-10-04T09:05:00.000Z',
        ).millisecondsSinceEpoch,
      });
      final page = await CallLog(db, ownsDatabase: false).page(limit: 1);
      expect(page.calls.single.message.topic, carol);
    });

    test('keeps a row it cannot read, with no time', () async {
      final db = await v1([(bob, 1, null, '{oops'), (carol, 5, null, later)]);
      addTearDown(db.close);

      final rows = await db.select(db.callMessages).get();
      expect(rows, hasLength(2));
      expect(rows.firstWhere((r) => r.topic == bob).time, 0);
      expect(
        (await CallLog(db, ownsDatabase: false).calls()).single.message.topic,
        carol,
      );
    });
  });
}
