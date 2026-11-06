import 'package:drift/drift.dart';

part 'call_log_database.g.dart';

/// The call messages of direct chats, base messages and the server's
/// updates alike.
@DataClassName('CallMessageRow')
@TableIndex(name: 'call_messages_replaces', columns: {#topic, #replaces})
class CallMessages extends Table {
  TextColumn get topic => text()();
  IntColumn get seq => integer()();

  /// `head.replace` as the server sent it, `:<seq>` of the call this one
  /// updates; null on the message that started a call.
  TextColumn get replaces => text().nullable()();

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

  @override
  int get schemaVersion => 1;
}
