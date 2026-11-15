import 'dart:convert';

import 'package:drift/drift.dart';

part 'call_log_database.g.dart';

/// The call messages of direct chats, base messages and the server's
/// updates alike.
@DataClassName('CallMessageRow')
@TableIndex(name: 'call_messages_replaces', columns: {#topic, #replaces})
@TableIndex.sql(
  'CREATE INDEX call_messages_newest ON call_messages (time, topic, seq) '
  'WHERE replaces IS NULL',
)
class CallMessages extends Table {
  TextColumn get topic => text()();
  IntColumn get seq => integer()();

  /// `head.replace` as the server sent it, `:<seq>` of the call this one
  /// updates; null on the message that started a call.
  TextColumn get replaces => text().nullable()();

  /// `DataMessage.time` in ms since the epoch, so the calls of every chat
  /// page newest first. 0 on a row of the first version whose JSON can't
  /// be read.
  IntColumn get time => integer().withDefault(const Constant(0))();

  /// `DataMessage.toJson`.
  TextColumn get json => text()();

  @override
  Set<Column<Object>> get primaryKey => {topic, seq};
}

/// One user's call log on one server, in a file of its own: unlike the
/// cache it outlives a logout, so nothing here can be fetched again. A new
/// schema must keep what the file holds.
@DriftDatabase(tables: [CallMessages])
final class CallLogDatabase extends _$CallLogDatabase {
  CallLogDatabase(super.e);

  /// 2: [CallMessages.time], to page the calls newest first.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(callMessages, callMessages.time);
        await m.create(callMessagesNewest);
        await _backfillTimes();
      }
    },
  );

  /// Fills [CallMessages.time] from each row's `ts`, to the ms. A row
  /// that can't be read keeps 0: the log leaves it out anyway.
  Future<void> _backfillTimes() async {
    final rows = await customSelect(
      'SELECT topic, seq, json FROM call_messages',
      readsFrom: {callMessages},
    ).get();
    await batch((b) {
      for (final row in rows) {
        if (_time(row.read<String>('json')) case final time?) {
          b.update(
            callMessages,
            CallMessagesCompanion(time: Value(time)),
            where: (m) =>
                m.topic.equals(row.read<String>('topic')) &
                m.seq.equals(row.read<int>('seq')),
          );
        }
      }
    });
  }

  static int? _time(String json) {
    try {
      final ts = (jsonDecode(json) as Map<String, Object?>)['ts'];
      return ts is String ? DateTime.parse(ts).millisecondsSinceEpoch : null;
    } on Object {
      return null;
    }
  }
}
