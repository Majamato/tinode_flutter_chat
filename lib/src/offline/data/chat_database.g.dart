// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_database.dart';

// ignore_for_file: type=lint
class $ChatsTable extends Chats with TableInfo<$ChatsTable, ChatRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [topic, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chats';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatRow> instance, {
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
  Set<GeneratedColumn> get $primaryKey => {topic};
  @override
  ChatRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatRow(
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $ChatsTable createAlias(String alias) {
    return $ChatsTable(attachedDatabase, alias);
  }
}

class ChatRow extends DataClass implements Insertable<ChatRow> {
  final String topic;

  /// `Subscription.toJson`.
  final String json;
  const ChatRow({required this.topic, required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['topic'] = Variable<String>(topic);
    map['json'] = Variable<String>(json);
    return map;
  }

  ChatsCompanion toCompanion(bool nullToAbsent) {
    return ChatsCompanion(topic: Value(topic), json: Value(json));
  }

  factory ChatRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatRow(
      topic: serializer.fromJson<String>(json['topic']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'topic': serializer.toJson<String>(topic),
      'json': serializer.toJson<String>(json),
    };
  }

  ChatRow copyWith({String? topic, String? json}) =>
      ChatRow(topic: topic ?? this.topic, json: json ?? this.json);
  ChatRow copyWithCompanion(ChatsCompanion data) {
    return ChatRow(
      topic: data.topic.present ? data.topic.value : this.topic,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatRow(')
          ..write('topic: $topic, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(topic, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatRow &&
          other.topic == this.topic &&
          other.json == this.json);
}

class ChatsCompanion extends UpdateCompanion<ChatRow> {
  final Value<String> topic;
  final Value<String> json;
  final Value<int> rowid;
  const ChatsCompanion({
    this.topic = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatsCompanion.insert({
    required String topic,
    required String json,
    this.rowid = const Value.absent(),
  }) : topic = Value(topic),
       json = Value(json);
  static Insertable<ChatRow> custom({
    Expression<String>? topic,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (topic != null) 'topic': topic,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatsCompanion copyWith({
    Value<String>? topic,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return ChatsCompanion(
      topic: topic ?? this.topic,
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
    return (StringBuffer('ChatsCompanion(')
          ..write('topic: $topic, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends Members with TableInfo<$MembersTable, MemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [topic, userId, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberRow> instance, {
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
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {topic, userId};
  @override
  MemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberRow(
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class MemberRow extends DataClass implements Insertable<MemberRow> {
  final String topic;
  final String userId;

  /// `Subscription.toJson`.
  final String json;
  const MemberRow({
    required this.topic,
    required this.userId,
    required this.json,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['topic'] = Variable<String>(topic);
    map['user_id'] = Variable<String>(userId);
    map['json'] = Variable<String>(json);
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      topic: Value(topic),
      userId: Value(userId),
      json: Value(json),
    );
  }

  factory MemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberRow(
      topic: serializer.fromJson<String>(json['topic']),
      userId: serializer.fromJson<String>(json['userId']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'topic': serializer.toJson<String>(topic),
      'userId': serializer.toJson<String>(userId),
      'json': serializer.toJson<String>(json),
    };
  }

  MemberRow copyWith({String? topic, String? userId, String? json}) =>
      MemberRow(
        topic: topic ?? this.topic,
        userId: userId ?? this.userId,
        json: json ?? this.json,
      );
  MemberRow copyWithCompanion(MembersCompanion data) {
    return MemberRow(
      topic: data.topic.present ? data.topic.value : this.topic,
      userId: data.userId.present ? data.userId.value : this.userId,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberRow(')
          ..write('topic: $topic, ')
          ..write('userId: $userId, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(topic, userId, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberRow &&
          other.topic == this.topic &&
          other.userId == this.userId &&
          other.json == this.json);
}

class MembersCompanion extends UpdateCompanion<MemberRow> {
  final Value<String> topic;
  final Value<String> userId;
  final Value<String> json;
  final Value<int> rowid;
  const MembersCompanion({
    this.topic = const Value.absent(),
    this.userId = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String topic,
    required String userId,
    required String json,
    this.rowid = const Value.absent(),
  }) : topic = Value(topic),
       userId = Value(userId),
       json = Value(json);
  static Insertable<MemberRow> custom({
    Expression<String>? topic,
    Expression<String>? userId,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (topic != null) 'topic': topic,
      if (userId != null) 'user_id': userId,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<String>? topic,
    Value<String>? userId,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return MembersCompanion(
      topic: topic ?? this.topic,
      userId: userId ?? this.userId,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
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
    return (StringBuffer('MembersCompanion(')
          ..write('topic: $topic, ')
          ..write('userId: $userId, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TopicSyncsTable extends TopicSyncs
    with TableInfo<$TopicSyncsTable, TopicSyncRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicSyncsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coveredMeta = const VerificationMeta(
    'covered',
  );
  @override
  late final GeneratedColumn<String> covered = GeneratedColumn<String>(
    'covered',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _syncedDeleteIdMeta = const VerificationMeta(
    'syncedDeleteId',
  );
  @override
  late final GeneratedColumn<int> syncedDeleteId = GeneratedColumn<int>(
    'synced_delete_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [topic, covered, syncedDeleteId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topic_syncs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TopicSyncRow> instance, {
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
    if (data.containsKey('covered')) {
      context.handle(
        _coveredMeta,
        covered.isAcceptableOrUnknown(data['covered']!, _coveredMeta),
      );
    }
    if (data.containsKey('synced_delete_id')) {
      context.handle(
        _syncedDeleteIdMeta,
        syncedDeleteId.isAcceptableOrUnknown(
          data['synced_delete_id']!,
          _syncedDeleteIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {topic};
  @override
  TopicSyncRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopicSyncRow(
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      covered: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}covered'],
      )!,
      syncedDeleteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_delete_id'],
      )!,
    );
  }

  @override
  $TopicSyncsTable createAlias(String alias) {
    return $TopicSyncsTable(attachedDatabase, alias);
  }
}

class TopicSyncRow extends DataClass implements Insertable<TopicSyncRow> {
  final String topic;

  /// The covered seqs, `SeqRanges.toJson`.
  final String covered;

  /// The newest delete ID applied to the stored messages.
  final int syncedDeleteId;
  const TopicSyncRow({
    required this.topic,
    required this.covered,
    required this.syncedDeleteId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['topic'] = Variable<String>(topic);
    map['covered'] = Variable<String>(covered);
    map['synced_delete_id'] = Variable<int>(syncedDeleteId);
    return map;
  }

  TopicSyncsCompanion toCompanion(bool nullToAbsent) {
    return TopicSyncsCompanion(
      topic: Value(topic),
      covered: Value(covered),
      syncedDeleteId: Value(syncedDeleteId),
    );
  }

  factory TopicSyncRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopicSyncRow(
      topic: serializer.fromJson<String>(json['topic']),
      covered: serializer.fromJson<String>(json['covered']),
      syncedDeleteId: serializer.fromJson<int>(json['syncedDeleteId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'topic': serializer.toJson<String>(topic),
      'covered': serializer.toJson<String>(covered),
      'syncedDeleteId': serializer.toJson<int>(syncedDeleteId),
    };
  }

  TopicSyncRow copyWith({
    String? topic,
    String? covered,
    int? syncedDeleteId,
  }) => TopicSyncRow(
    topic: topic ?? this.topic,
    covered: covered ?? this.covered,
    syncedDeleteId: syncedDeleteId ?? this.syncedDeleteId,
  );
  TopicSyncRow copyWithCompanion(TopicSyncsCompanion data) {
    return TopicSyncRow(
      topic: data.topic.present ? data.topic.value : this.topic,
      covered: data.covered.present ? data.covered.value : this.covered,
      syncedDeleteId: data.syncedDeleteId.present
          ? data.syncedDeleteId.value
          : this.syncedDeleteId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopicSyncRow(')
          ..write('topic: $topic, ')
          ..write('covered: $covered, ')
          ..write('syncedDeleteId: $syncedDeleteId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(topic, covered, syncedDeleteId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopicSyncRow &&
          other.topic == this.topic &&
          other.covered == this.covered &&
          other.syncedDeleteId == this.syncedDeleteId);
}

class TopicSyncsCompanion extends UpdateCompanion<TopicSyncRow> {
  final Value<String> topic;
  final Value<String> covered;
  final Value<int> syncedDeleteId;
  final Value<int> rowid;
  const TopicSyncsCompanion({
    this.topic = const Value.absent(),
    this.covered = const Value.absent(),
    this.syncedDeleteId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TopicSyncsCompanion.insert({
    required String topic,
    this.covered = const Value.absent(),
    this.syncedDeleteId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : topic = Value(topic);
  static Insertable<TopicSyncRow> custom({
    Expression<String>? topic,
    Expression<String>? covered,
    Expression<int>? syncedDeleteId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (topic != null) 'topic': topic,
      if (covered != null) 'covered': covered,
      if (syncedDeleteId != null) 'synced_delete_id': syncedDeleteId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TopicSyncsCompanion copyWith({
    Value<String>? topic,
    Value<String>? covered,
    Value<int>? syncedDeleteId,
    Value<int>? rowid,
  }) {
    return TopicSyncsCompanion(
      topic: topic ?? this.topic,
      covered: covered ?? this.covered,
      syncedDeleteId: syncedDeleteId ?? this.syncedDeleteId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (covered.present) {
      map['covered'] = Variable<String>(covered.value);
    }
    if (syncedDeleteId.present) {
      map['synced_delete_id'] = Variable<int>(syncedDeleteId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicSyncsCompanion(')
          ..write('topic: $topic, ')
          ..write('covered: $covered, ')
          ..write('syncedDeleteId: $syncedDeleteId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [topic, seq, json, clientId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageRow> instance, {
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
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {topic, seq};
  @override
  MessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageRow(
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class MessageRow extends DataClass implements Insertable<MessageRow> {
  final String topic;
  final int seq;

  /// `DataMessage.toJson`.
  final String json;

  /// Set on the messages this package sent, from their head.
  final String? clientId;
  const MessageRow({
    required this.topic,
    required this.seq,
    required this.json,
    this.clientId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['topic'] = Variable<String>(topic);
    map['seq'] = Variable<int>(seq);
    map['json'] = Variable<String>(json);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      topic: Value(topic),
      seq: Value(seq),
      json: Value(json),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
    );
  }

  factory MessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageRow(
      topic: serializer.fromJson<String>(json['topic']),
      seq: serializer.fromJson<int>(json['seq']),
      json: serializer.fromJson<String>(json['json']),
      clientId: serializer.fromJson<String?>(json['clientId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'topic': serializer.toJson<String>(topic),
      'seq': serializer.toJson<int>(seq),
      'json': serializer.toJson<String>(json),
      'clientId': serializer.toJson<String?>(clientId),
    };
  }

  MessageRow copyWith({
    String? topic,
    int? seq,
    String? json,
    Value<String?> clientId = const Value.absent(),
  }) => MessageRow(
    topic: topic ?? this.topic,
    seq: seq ?? this.seq,
    json: json ?? this.json,
    clientId: clientId.present ? clientId.value : this.clientId,
  );
  MessageRow copyWithCompanion(MessagesCompanion data) {
    return MessageRow(
      topic: data.topic.present ? data.topic.value : this.topic,
      seq: data.seq.present ? data.seq.value : this.seq,
      json: data.json.present ? data.json.value : this.json,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageRow(')
          ..write('topic: $topic, ')
          ..write('seq: $seq, ')
          ..write('json: $json, ')
          ..write('clientId: $clientId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(topic, seq, json, clientId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageRow &&
          other.topic == this.topic &&
          other.seq == this.seq &&
          other.json == this.json &&
          other.clientId == this.clientId);
}

class MessagesCompanion extends UpdateCompanion<MessageRow> {
  final Value<String> topic;
  final Value<int> seq;
  final Value<String> json;
  final Value<String?> clientId;
  final Value<int> rowid;
  const MessagesCompanion({
    this.topic = const Value.absent(),
    this.seq = const Value.absent(),
    this.json = const Value.absent(),
    this.clientId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String topic,
    required int seq,
    required String json,
    this.clientId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : topic = Value(topic),
       seq = Value(seq),
       json = Value(json);
  static Insertable<MessageRow> custom({
    Expression<String>? topic,
    Expression<int>? seq,
    Expression<String>? json,
    Expression<String>? clientId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (topic != null) 'topic': topic,
      if (seq != null) 'seq': seq,
      if (json != null) 'json': json,
      if (clientId != null) 'client_id': clientId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? topic,
    Value<int>? seq,
    Value<String>? json,
    Value<String?>? clientId,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      topic: topic ?? this.topic,
      seq: seq ?? this.seq,
      json: json ?? this.json,
      clientId: clientId ?? this.clientId,
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
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('topic: $topic, ')
          ..write('seq: $seq, ')
          ..write('json: $json, ')
          ..write('clientId: $clientId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<OutboxKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<OutboxKind>($OutboxTable.$converterkind);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failureMeta = const VerificationMeta(
    'failure',
  );
  @override
  late final GeneratedColumn<String> failure = GeneratedColumn<String>(
    'failure',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inFlightMeta = const VerificationMeta(
    'inFlight',
  );
  @override
  late final GeneratedColumn<bool> inFlight = GeneratedColumn<bool>(
    'in_flight',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("in_flight" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sentAfterSeqMeta = const VerificationMeta(
    'sentAfterSeq',
  );
  @override
  late final GeneratedColumn<int> sentAfterSeq = GeneratedColumn<int>(
    'sent_after_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    topic,
    kind,
    clientId,
    payload,
    createdAt,
    failure,
    inFlight,
    sentAfterSeq,
    attempts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('failure')) {
      context.handle(
        _failureMeta,
        failure.isAcceptableOrUnknown(data['failure']!, _failureMeta),
      );
    }
    if (data.containsKey('in_flight')) {
      context.handle(
        _inFlightMeta,
        inFlight.isAcceptableOrUnknown(data['in_flight']!, _inFlightMeta),
      );
    }
    if (data.containsKey('sent_after_seq')) {
      context.handle(
        _sentAfterSeqMeta,
        sentAfterSeq.isAcceptableOrUnknown(
          data['sent_after_seq']!,
          _sentAfterSeqMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      kind: $OutboxTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      failure: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure'],
      ),
      inFlight: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}in_flight'],
      )!,
      sentAfterSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sent_after_seq'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<OutboxKind, String, String> $converterkind =
      const EnumNameConverter<OutboxKind>(OutboxKind.values);
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int id;
  final String topic;
  final OutboxKind kind;

  /// Set on [OutboxKind.publish] entries.
  final String? clientId;

  /// The request's own fields as JSON: content, ranges, seq…
  final String payload;
  final DateTime createdAt;

  /// Set when the server refused it or it kept failing: `ChatFailure.name`.
  final String? failure;

  /// Sent without a reply: the server may have it already.
  final bool inFlight;

  /// The topic's newest seq when it was sent, where to look for it.
  final int sentAfterSeq;
  final int attempts;
  const OutboxRow({
    required this.id,
    required this.topic,
    required this.kind,
    this.clientId,
    required this.payload,
    required this.createdAt,
    this.failure,
    required this.inFlight,
    required this.sentAfterSeq,
    required this.attempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['topic'] = Variable<String>(topic);
    {
      map['kind'] = Variable<String>($OutboxTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || failure != null) {
      map['failure'] = Variable<String>(failure);
    }
    map['in_flight'] = Variable<bool>(inFlight);
    map['sent_after_seq'] = Variable<int>(sentAfterSeq);
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      id: Value(id),
      topic: Value(topic),
      kind: Value(kind),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      payload: Value(payload),
      createdAt: Value(createdAt),
      failure: failure == null && nullToAbsent
          ? const Value.absent()
          : Value(failure),
      inFlight: Value(inFlight),
      sentAfterSeq: Value(sentAfterSeq),
      attempts: Value(attempts),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<int>(json['id']),
      topic: serializer.fromJson<String>(json['topic']),
      kind: $OutboxTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      clientId: serializer.fromJson<String?>(json['clientId']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      failure: serializer.fromJson<String?>(json['failure']),
      inFlight: serializer.fromJson<bool>(json['inFlight']),
      sentAfterSeq: serializer.fromJson<int>(json['sentAfterSeq']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'topic': serializer.toJson<String>(topic),
      'kind': serializer.toJson<String>(
        $OutboxTable.$converterkind.toJson(kind),
      ),
      'clientId': serializer.toJson<String?>(clientId),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'failure': serializer.toJson<String?>(failure),
      'inFlight': serializer.toJson<bool>(inFlight),
      'sentAfterSeq': serializer.toJson<int>(sentAfterSeq),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  OutboxRow copyWith({
    int? id,
    String? topic,
    OutboxKind? kind,
    Value<String?> clientId = const Value.absent(),
    String? payload,
    DateTime? createdAt,
    Value<String?> failure = const Value.absent(),
    bool? inFlight,
    int? sentAfterSeq,
    int? attempts,
  }) => OutboxRow(
    id: id ?? this.id,
    topic: topic ?? this.topic,
    kind: kind ?? this.kind,
    clientId: clientId.present ? clientId.value : this.clientId,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    failure: failure.present ? failure.value : this.failure,
    inFlight: inFlight ?? this.inFlight,
    sentAfterSeq: sentAfterSeq ?? this.sentAfterSeq,
    attempts: attempts ?? this.attempts,
  );
  OutboxRow copyWithCompanion(OutboxCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      topic: data.topic.present ? data.topic.value : this.topic,
      kind: data.kind.present ? data.kind.value : this.kind,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      failure: data.failure.present ? data.failure.value : this.failure,
      inFlight: data.inFlight.present ? data.inFlight.value : this.inFlight,
      sentAfterSeq: data.sentAfterSeq.present
          ? data.sentAfterSeq.value
          : this.sentAfterSeq,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('topic: $topic, ')
          ..write('kind: $kind, ')
          ..write('clientId: $clientId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('failure: $failure, ')
          ..write('inFlight: $inFlight, ')
          ..write('sentAfterSeq: $sentAfterSeq, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    topic,
    kind,
    clientId,
    payload,
    createdAt,
    failure,
    inFlight,
    sentAfterSeq,
    attempts,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.topic == this.topic &&
          other.kind == this.kind &&
          other.clientId == this.clientId &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.failure == this.failure &&
          other.inFlight == this.inFlight &&
          other.sentAfterSeq == this.sentAfterSeq &&
          other.attempts == this.attempts);
}

class OutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> id;
  final Value<String> topic;
  final Value<OutboxKind> kind;
  final Value<String?> clientId;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<String?> failure;
  final Value<bool> inFlight;
  final Value<int> sentAfterSeq;
  final Value<int> attempts;
  const OutboxCompanion({
    this.id = const Value.absent(),
    this.topic = const Value.absent(),
    this.kind = const Value.absent(),
    this.clientId = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.failure = const Value.absent(),
    this.inFlight = const Value.absent(),
    this.sentAfterSeq = const Value.absent(),
    this.attempts = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.id = const Value.absent(),
    required String topic,
    required OutboxKind kind,
    this.clientId = const Value.absent(),
    required String payload,
    required DateTime createdAt,
    this.failure = const Value.absent(),
    this.inFlight = const Value.absent(),
    this.sentAfterSeq = const Value.absent(),
    this.attempts = const Value.absent(),
  }) : topic = Value(topic),
       kind = Value(kind),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<OutboxRow> custom({
    Expression<int>? id,
    Expression<String>? topic,
    Expression<String>? kind,
    Expression<String>? clientId,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<String>? failure,
    Expression<bool>? inFlight,
    Expression<int>? sentAfterSeq,
    Expression<int>? attempts,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (topic != null) 'topic': topic,
      if (kind != null) 'kind': kind,
      if (clientId != null) 'client_id': clientId,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (failure != null) 'failure': failure,
      if (inFlight != null) 'in_flight': inFlight,
      if (sentAfterSeq != null) 'sent_after_seq': sentAfterSeq,
      if (attempts != null) 'attempts': attempts,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? id,
    Value<String>? topic,
    Value<OutboxKind>? kind,
    Value<String?>? clientId,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<String?>? failure,
    Value<bool>? inFlight,
    Value<int>? sentAfterSeq,
    Value<int>? attempts,
  }) {
    return OutboxCompanion(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      kind: kind ?? this.kind,
      clientId: clientId ?? this.clientId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      failure: failure ?? this.failure,
      inFlight: inFlight ?? this.inFlight,
      sentAfterSeq: sentAfterSeq ?? this.sentAfterSeq,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $OutboxTable.$converterkind.toSql(kind.value),
      );
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (failure.present) {
      map['failure'] = Variable<String>(failure.value);
    }
    if (inFlight.present) {
      map['in_flight'] = Variable<bool>(inFlight.value);
    }
    if (sentAfterSeq.present) {
      map['sent_after_seq'] = Variable<int>(sentAfterSeq.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('id: $id, ')
          ..write('topic: $topic, ')
          ..write('kind: $kind, ')
          ..write('clientId: $clientId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('failure: $failure, ')
          ..write('inFlight: $inFlight, ')
          ..write('sentAfterSeq: $sentAfterSeq, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }
}

abstract class _$ChatDatabase extends GeneratedDatabase {
  _$ChatDatabase(QueryExecutor e) : super(e);
  $ChatDatabaseManager get managers => $ChatDatabaseManager(this);
  late final $ChatsTable chats = $ChatsTable(this);
  late final $MembersTable members = $MembersTable(this);
  late final $TopicSyncsTable topicSyncs = $TopicSyncsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final Index messagesClientId = Index(
    'messages_client_id',
    'CREATE INDEX messages_client_id ON messages (topic, client_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    chats,
    members,
    topicSyncs,
    messages,
    outbox,
    messagesClientId,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ChatsTableCreateCompanionBuilder =
    ChatsCompanion Function({
      required String topic,
      required String json,
      Value<int> rowid,
    });
typedef $$ChatsTableUpdateCompanionBuilder =
    ChatsCompanion Function({
      Value<String> topic,
      Value<String> json,
      Value<int> rowid,
    });

class $$ChatsTableFilterComposer extends Composer<_$ChatDatabase, $ChatsTable> {
  $$ChatsTableFilterComposer({
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

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatsTableOrderingComposer
    extends Composer<_$ChatDatabase, $ChatsTable> {
  $$ChatsTableOrderingComposer({
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

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatsTableAnnotationComposer
    extends Composer<_$ChatDatabase, $ChatsTable> {
  $$ChatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$ChatsTableTableManager
    extends
        RootTableManager<
          _$ChatDatabase,
          $ChatsTable,
          ChatRow,
          $$ChatsTableFilterComposer,
          $$ChatsTableOrderingComposer,
          $$ChatsTableAnnotationComposer,
          $$ChatsTableCreateCompanionBuilder,
          $$ChatsTableUpdateCompanionBuilder,
          (ChatRow, BaseReferences<_$ChatDatabase, $ChatsTable, ChatRow>),
          ChatRow,
          PrefetchHooks Function()
        > {
  $$ChatsTableTableManager(_$ChatDatabase db, $ChatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> topic = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatsCompanion(topic: topic, json: json, rowid: rowid),
          createCompanionCallback:
              ({
                required String topic,
                required String json,
                Value<int> rowid = const Value.absent(),
              }) =>
                  ChatsCompanion.insert(topic: topic, json: json, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatsTableProcessedTableManager =
    ProcessedTableManager<
      _$ChatDatabase,
      $ChatsTable,
      ChatRow,
      $$ChatsTableFilterComposer,
      $$ChatsTableOrderingComposer,
      $$ChatsTableAnnotationComposer,
      $$ChatsTableCreateCompanionBuilder,
      $$ChatsTableUpdateCompanionBuilder,
      (ChatRow, BaseReferences<_$ChatDatabase, $ChatsTable, ChatRow>),
      ChatRow,
      PrefetchHooks Function()
    >;
typedef $$MembersTableCreateCompanionBuilder =
    MembersCompanion Function({
      required String topic,
      required String userId,
      required String json,
      Value<int> rowid,
    });
typedef $$MembersTableUpdateCompanionBuilder =
    MembersCompanion Function({
      Value<String> topic,
      Value<String> userId,
      Value<String> json,
      Value<int> rowid,
    });

class $$MembersTableFilterComposer
    extends Composer<_$ChatDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MembersTableOrderingComposer
    extends Composer<_$ChatDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MembersTableAnnotationComposer
    extends Composer<_$ChatDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$MembersTableTableManager
    extends
        RootTableManager<
          _$ChatDatabase,
          $MembersTable,
          MemberRow,
          $$MembersTableFilterComposer,
          $$MembersTableOrderingComposer,
          $$MembersTableAnnotationComposer,
          $$MembersTableCreateCompanionBuilder,
          $$MembersTableUpdateCompanionBuilder,
          (MemberRow, BaseReferences<_$ChatDatabase, $MembersTable, MemberRow>),
          MemberRow,
          PrefetchHooks Function()
        > {
  $$MembersTableTableManager(_$ChatDatabase db, $MembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> topic = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion(
                topic: topic,
                userId: userId,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String topic,
                required String userId,
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion.insert(
                topic: topic,
                userId: userId,
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

typedef $$MembersTableProcessedTableManager =
    ProcessedTableManager<
      _$ChatDatabase,
      $MembersTable,
      MemberRow,
      $$MembersTableFilterComposer,
      $$MembersTableOrderingComposer,
      $$MembersTableAnnotationComposer,
      $$MembersTableCreateCompanionBuilder,
      $$MembersTableUpdateCompanionBuilder,
      (MemberRow, BaseReferences<_$ChatDatabase, $MembersTable, MemberRow>),
      MemberRow,
      PrefetchHooks Function()
    >;
typedef $$TopicSyncsTableCreateCompanionBuilder =
    TopicSyncsCompanion Function({
      required String topic,
      Value<String> covered,
      Value<int> syncedDeleteId,
      Value<int> rowid,
    });
typedef $$TopicSyncsTableUpdateCompanionBuilder =
    TopicSyncsCompanion Function({
      Value<String> topic,
      Value<String> covered,
      Value<int> syncedDeleteId,
      Value<int> rowid,
    });

class $$TopicSyncsTableFilterComposer
    extends Composer<_$ChatDatabase, $TopicSyncsTable> {
  $$TopicSyncsTableFilterComposer({
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

  ColumnFilters<String> get covered => $composableBuilder(
    column: $table.covered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedDeleteId => $composableBuilder(
    column: $table.syncedDeleteId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TopicSyncsTableOrderingComposer
    extends Composer<_$ChatDatabase, $TopicSyncsTable> {
  $$TopicSyncsTableOrderingComposer({
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

  ColumnOrderings<String> get covered => $composableBuilder(
    column: $table.covered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedDeleteId => $composableBuilder(
    column: $table.syncedDeleteId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TopicSyncsTableAnnotationComposer
    extends Composer<_$ChatDatabase, $TopicSyncsTable> {
  $$TopicSyncsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get covered =>
      $composableBuilder(column: $table.covered, builder: (column) => column);

  GeneratedColumn<int> get syncedDeleteId => $composableBuilder(
    column: $table.syncedDeleteId,
    builder: (column) => column,
  );
}

class $$TopicSyncsTableTableManager
    extends
        RootTableManager<
          _$ChatDatabase,
          $TopicSyncsTable,
          TopicSyncRow,
          $$TopicSyncsTableFilterComposer,
          $$TopicSyncsTableOrderingComposer,
          $$TopicSyncsTableAnnotationComposer,
          $$TopicSyncsTableCreateCompanionBuilder,
          $$TopicSyncsTableUpdateCompanionBuilder,
          (
            TopicSyncRow,
            BaseReferences<_$ChatDatabase, $TopicSyncsTable, TopicSyncRow>,
          ),
          TopicSyncRow,
          PrefetchHooks Function()
        > {
  $$TopicSyncsTableTableManager(_$ChatDatabase db, $TopicSyncsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicSyncsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicSyncsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicSyncsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> topic = const Value.absent(),
                Value<String> covered = const Value.absent(),
                Value<int> syncedDeleteId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TopicSyncsCompanion(
                topic: topic,
                covered: covered,
                syncedDeleteId: syncedDeleteId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String topic,
                Value<String> covered = const Value.absent(),
                Value<int> syncedDeleteId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TopicSyncsCompanion.insert(
                topic: topic,
                covered: covered,
                syncedDeleteId: syncedDeleteId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TopicSyncsTableProcessedTableManager =
    ProcessedTableManager<
      _$ChatDatabase,
      $TopicSyncsTable,
      TopicSyncRow,
      $$TopicSyncsTableFilterComposer,
      $$TopicSyncsTableOrderingComposer,
      $$TopicSyncsTableAnnotationComposer,
      $$TopicSyncsTableCreateCompanionBuilder,
      $$TopicSyncsTableUpdateCompanionBuilder,
      (
        TopicSyncRow,
        BaseReferences<_$ChatDatabase, $TopicSyncsTable, TopicSyncRow>,
      ),
      TopicSyncRow,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String topic,
      required int seq,
      required String json,
      Value<String?> clientId,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> topic,
      Value<int> seq,
      Value<String> json,
      Value<String?> clientId,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$ChatDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
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

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$ChatDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
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

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$ChatDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
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

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$ChatDatabase,
          $MessagesTable,
          MessageRow,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (
            MessageRow,
            BaseReferences<_$ChatDatabase, $MessagesTable, MessageRow>,
          ),
          MessageRow,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$ChatDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> topic = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                topic: topic,
                seq: seq,
                json: json,
                clientId: clientId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String topic,
                required int seq,
                required String json,
                Value<String?> clientId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                topic: topic,
                seq: seq,
                json: json,
                clientId: clientId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$ChatDatabase,
      $MessagesTable,
      MessageRow,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (MessageRow, BaseReferences<_$ChatDatabase, $MessagesTable, MessageRow>),
      MessageRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> id,
      required String topic,
      required OutboxKind kind,
      Value<String?> clientId,
      required String payload,
      required DateTime createdAt,
      Value<String?> failure,
      Value<bool> inFlight,
      Value<int> sentAfterSeq,
      Value<int> attempts,
    });
typedef $$OutboxTableUpdateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> id,
      Value<String> topic,
      Value<OutboxKind> kind,
      Value<String?> clientId,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<String?> failure,
      Value<bool> inFlight,
      Value<int> sentAfterSeq,
      Value<int> attempts,
    });

class $$OutboxTableFilterComposer
    extends Composer<_$ChatDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OutboxKind, OutboxKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failure => $composableBuilder(
    column: $table.failure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inFlight => $composableBuilder(
    column: $table.inFlight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentAfterSeq => $composableBuilder(
    column: $table.sentAfterSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$ChatDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failure => $composableBuilder(
    column: $table.failure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inFlight => $composableBuilder(
    column: $table.inFlight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentAfterSeq => $composableBuilder(
    column: $table.sentAfterSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$ChatDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OutboxKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get failure =>
      $composableBuilder(column: $table.failure, builder: (column) => column);

  GeneratedColumn<bool> get inFlight =>
      $composableBuilder(column: $table.inFlight, builder: (column) => column);

  GeneratedColumn<int> get sentAfterSeq => $composableBuilder(
    column: $table.sentAfterSeq,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$ChatDatabase,
          $OutboxTable,
          OutboxRow,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxRow, BaseReferences<_$ChatDatabase, $OutboxTable, OutboxRow>),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$ChatDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<OutboxKind> kind = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> failure = const Value.absent(),
                Value<bool> inFlight = const Value.absent(),
                Value<int> sentAfterSeq = const Value.absent(),
                Value<int> attempts = const Value.absent(),
              }) => OutboxCompanion(
                id: id,
                topic: topic,
                kind: kind,
                clientId: clientId,
                payload: payload,
                createdAt: createdAt,
                failure: failure,
                inFlight: inFlight,
                sentAfterSeq: sentAfterSeq,
                attempts: attempts,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String topic,
                required OutboxKind kind,
                Value<String?> clientId = const Value.absent(),
                required String payload,
                required DateTime createdAt,
                Value<String?> failure = const Value.absent(),
                Value<bool> inFlight = const Value.absent(),
                Value<int> sentAfterSeq = const Value.absent(),
                Value<int> attempts = const Value.absent(),
              }) => OutboxCompanion.insert(
                id: id,
                topic: topic,
                kind: kind,
                clientId: clientId,
                payload: payload,
                createdAt: createdAt,
                failure: failure,
                inFlight: inFlight,
                sentAfterSeq: sentAfterSeq,
                attempts: attempts,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$ChatDatabase,
      $OutboxTable,
      OutboxRow,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$ChatDatabase, $OutboxTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;

class $ChatDatabaseManager {
  final _$ChatDatabase _db;
  $ChatDatabaseManager(this._db);
  $$ChatsTableTableManager get chats =>
      $$ChatsTableTableManager(_db, _db.chats);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$TopicSyncsTableTableManager get topicSyncs =>
      $$TopicSyncsTableTableManager(_db, _db.topicSyncs);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
}
