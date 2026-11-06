// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_log_database.dart';

// ignore_for_file: type=lint
class $CallMessagesTable extends CallMessages
    with TableInfo<$CallMessagesTable, CallMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CallMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _replacesMeta = const VerificationMeta(
    'replaces',
  );
  @override
  late final GeneratedColumn<String> replaces = GeneratedColumn<String>(
    'replaces',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [topic, seq, replaces, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'call_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<CallMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('replaces')) {
      context.handle(
        _replacesMeta,
        replaces.isAcceptableOrUnknown(data['replaces']!, _replacesMeta),
      );
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {topic, seq};
  @override
  CallMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CallMessageRow(
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      replaces: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}replaces'],
      ),
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $CallMessagesTable createAlias(String alias) {
    return $CallMessagesTable(attachedDatabase, alias);
  }
}

class CallMessageRow extends DataClass implements Insertable<CallMessageRow> {
  final String topic;
  final int seq;

  /// `head.replace` as the server sent it, `:<seq>` of the call this one
  /// updates; null on the message that started a call.
  final String? replaces;

  /// `DataMessage.toJson`.
  final String json;
  const CallMessageRow({
    required this.topic,
    required this.seq,
    this.replaces,
    required this.json,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['topic'] = Variable<String>(topic);
    map['seq'] = Variable<int>(seq);
    if (!nullToAbsent || replaces != null) {
      map['replaces'] = Variable<String>(replaces);
    }
    map['json'] = Variable<String>(json);
    return map;
  }

  CallMessagesCompanion toCompanion(bool nullToAbsent) {
    return CallMessagesCompanion(
      topic: Value(topic),
      seq: Value(seq),
      replaces: replaces == null && nullToAbsent
          ? const Value.absent()
          : Value(replaces),
      json: Value(json),
    );
  }

  factory CallMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CallMessageRow(
      topic: serializer.fromJson<String>(json['topic']),
      seq: serializer.fromJson<int>(json['seq']),
      replaces: serializer.fromJson<String?>(json['replaces']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'topic': serializer.toJson<String>(topic),
      'seq': serializer.toJson<int>(seq),
      'replaces': serializer.toJson<String?>(replaces),
      'json': serializer.toJson<String>(json),
    };
  }

  CallMessageRow copyWith({
    String? topic,
    int? seq,
    Value<String?> replaces = const Value.absent(),
    String? json,
  }) => CallMessageRow(
    topic: topic ?? this.topic,
    seq: seq ?? this.seq,
    replaces: replaces.present ? replaces.value : this.replaces,
    json: json ?? this.json,
  );
  CallMessageRow copyWithCompanion(CallMessagesCompanion data) {
    return CallMessageRow(
      topic: data.topic.present ? data.topic.value : this.topic,
      seq: data.seq.present ? data.seq.value : this.seq,
      replaces: data.replaces.present ? data.replaces.value : this.replaces,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CallMessageRow(')
          ..write('topic: $topic, ')
          ..write('seq: $seq, ')
          ..write('replaces: $replaces, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(topic, seq, replaces, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CallMessageRow &&
          other.topic == this.topic &&
          other.seq == this.seq &&
          other.replaces == this.replaces &&
          other.json == this.json);
}

class CallMessagesCompanion extends UpdateCompanion<CallMessageRow> {
  final Value<String> topic;
  final Value<int> seq;
  final Value<String?> replaces;
  final Value<String> json;
  final Value<int> rowid;
  const CallMessagesCompanion({
    this.topic = const Value.absent(),
    this.seq = const Value.absent(),
    this.replaces = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CallMessagesCompanion.insert({
    required String topic,
    required int seq,
    this.replaces = const Value.absent(),
    required String json,
    this.rowid = const Value.absent(),
  }) : topic = Value(topic),
       seq = Value(seq),
       json = Value(json);
  static Insertable<CallMessageRow> custom({
    Expression<String>? topic,
    Expression<int>? seq,
    Expression<String>? replaces,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (topic != null) 'topic': topic,
      if (seq != null) 'seq': seq,
      if (replaces != null) 'replaces': replaces,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CallMessagesCompanion copyWith({
    Value<String>? topic,
    Value<int>? seq,
    Value<String?>? replaces,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return CallMessagesCompanion(
      topic: topic ?? this.topic,
      seq: seq ?? this.seq,
      replaces: replaces ?? this.replaces,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (replaces.present) {
      map['replaces'] = Variable<String>(replaces.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CallMessagesCompanion(')
          ..write('topic: $topic, ')
          ..write('seq: $seq, ')
          ..write('replaces: $replaces, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CallLogDatabase extends GeneratedDatabase {
  _$CallLogDatabase(QueryExecutor e) : super(e);
  $CallLogDatabaseManager get managers => $CallLogDatabaseManager(this);
  late final $CallMessagesTable callMessages = $CallMessagesTable(this);
  late final Index callMessagesReplaces = Index(
    'call_messages_replaces',
    'CREATE INDEX call_messages_replaces ON call_messages (topic, replaces)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    callMessages,
    callMessagesReplaces,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$CallMessagesTableCreateCompanionBuilder =
    CallMessagesCompanion Function({
      required String topic,
      required int seq,
      Value<String?> replaces,
      required String json,
      Value<int> rowid,
    });
typedef $$CallMessagesTableUpdateCompanionBuilder =
    CallMessagesCompanion Function({
      Value<String> topic,
      Value<int> seq,
      Value<String?> replaces,
      Value<String> json,
      Value<int> rowid,
    });

class $$CallMessagesTableFilterComposer
    extends Composer<_$CallLogDatabase, $CallMessagesTable> {
  $$CallMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replaces => $composableBuilder(
    column: $table.replaces,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CallMessagesTableOrderingComposer
    extends Composer<_$CallLogDatabase, $CallMessagesTable> {
  $$CallMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replaces => $composableBuilder(
    column: $table.replaces,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CallMessagesTableAnnotationComposer
    extends Composer<_$CallLogDatabase, $CallMessagesTable> {
  $$CallMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get replaces =>
      $composableBuilder(column: $table.replaces, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$CallMessagesTableTableManager
    extends
        RootTableManager<
          _$CallLogDatabase,
          $CallMessagesTable,
          CallMessageRow,
          $$CallMessagesTableFilterComposer,
          $$CallMessagesTableOrderingComposer,
          $$CallMessagesTableAnnotationComposer,
          $$CallMessagesTableCreateCompanionBuilder,
          $$CallMessagesTableUpdateCompanionBuilder,
          (
            CallMessageRow,
            BaseReferences<
              _$CallLogDatabase,
              $CallMessagesTable,
              CallMessageRow
            >,
          ),
          CallMessageRow,
          PrefetchHooks Function()
        > {
  $$CallMessagesTableTableManager(
    _$CallLogDatabase db,
    $CallMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CallMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CallMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CallMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> topic = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String?> replaces = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CallMessagesCompanion(
                topic: topic,
                seq: seq,
                replaces: replaces,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String topic,
                required int seq,
                Value<String?> replaces = const Value.absent(),
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => CallMessagesCompanion.insert(
                topic: topic,
                seq: seq,
                replaces: replaces,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CallMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$CallLogDatabase,
      $CallMessagesTable,
      CallMessageRow,
      $$CallMessagesTableFilterComposer,
      $$CallMessagesTableOrderingComposer,
      $$CallMessagesTableAnnotationComposer,
      $$CallMessagesTableCreateCompanionBuilder,
      $$CallMessagesTableUpdateCompanionBuilder,
      (
        CallMessageRow,
        BaseReferences<_$CallLogDatabase, $CallMessagesTable, CallMessageRow>,
      ),
      CallMessageRow,
      PrefetchHooks Function()
    >;

class $CallLogDatabaseManager {
  final _$CallLogDatabase _db;
  $CallLogDatabaseManager(this._db);
  $$CallMessagesTableTableManager get callMessages =>
      $$CallMessagesTableTableManager(_db, _db.callMessages);
}
