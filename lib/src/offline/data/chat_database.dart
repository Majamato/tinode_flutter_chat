import 'package:drift/drift.dart';

part 'chat_database.g.dart';

/// What an outbox entry asks the server for.
enum OutboxKind { publish, delete, read }

/// The chat list: the subscriptions of `me`, in their wire form.
@DataClassName('ChatRow')
class Chats extends Table {
  TextColumn get topic => text()();

  /// `Subscription.toJson`.
  TextColumn get json => text()();

  @override
  Set<Column<Object>> get primaryKey => {topic};
}

/// The members of each chat (the subscriptions of the topic), in their
/// wire form: names and avatars for sender labels, counters for receipts.
@DataClassName('MemberRow')
class Members extends Table {
  TextColumn get topic => text()();
  TextColumn get userId => text()();

  /// `Subscription.toJson`.
  TextColumn get json => text()();

  @override
  Set<Column<Object>> get primaryKey => {topic, userId};
}

/// What the cache knows about a topic's history, beyond its messages.
@DataClassName('TopicSyncRow')
class TopicSyncs extends Table {
  TextColumn get topic => text()();

  /// The covered seqs, `SeqRanges.toJson`.
  TextColumn get covered => text().withDefault(const Constant('[]'))();

  /// The newest delete ID applied to the stored messages.
  IntColumn get syncedDeleteId => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {topic};
}

@DataClassName('MessageRow')
@TableIndex(name: 'messages_client_id', columns: {#topic, #clientId})
class Messages extends Table {
  TextColumn get topic => text()();
  IntColumn get seq => integer()();

  /// `DataMessage.toJson`.
  TextColumn get json => text()();

  /// Set on the messages this package sent, from their head.
  TextColumn get clientId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {topic, seq};
}

/// What the user did that the server has not taken yet, oldest first.
@DataClassName('OutboxRow')
class Outbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get topic => text()();
  TextColumn get kind => textEnum<OutboxKind>()();

  /// Set on [OutboxKind.publish] entries.
  TextColumn get clientId => text().nullable().unique()();

  /// The request's own fields as JSON: content, ranges, seq…
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();

  /// Set when the server refused it or it kept failing: `ChatFailure.name`.
  TextColumn get failure => text().nullable()();

  /// Sent without a reply: the server may have it already.
  BoolColumn get inFlight => boolean().withDefault(const Constant(false))();

  /// The topic's newest seq when it was sent, where to look for it.
  IntColumn get sentAfterSeq => integer().withDefault(const Constant(0))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
}

/// One user's cache on one server.
@DriftDatabase(tables: [Chats, Members, TopicSyncs, Messages, Outbox])
final class ChatDatabase extends _$ChatDatabase {
  ChatDatabase(super.e);

  /// 2: [Members].
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(members);
      }
    },
  );
}
