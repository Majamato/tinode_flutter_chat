import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';
import 'package:tinode_flutter_chat/src/offline/data/cached_tinode_session.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/domain/cached_call.dart';
import 'package:tinode_flutter_chat/src/offline/domain/tinode_cache_limits.dart';

import '../../support/cached_calls_oracle.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/faulty_database.dart';
import '../../support/fixtures.dart';

const dave = 'usrDave';
const erin = 'usrErin';
const List<String> direct = [bob, carol, dave, erin];
const seeds = 300;
const stepsPerSeed = 60;
const catchUpPage = 8;

/// Random days with the app, through the real session and SQLite. A plain
/// model says what the log must hold after every step, and each day runs
/// twice, the second time with a log that always fails: the cache must come
/// out the same, so the log can't be changing what already worked.
///
/// A failure names its seed, and its steps replay exactly from that seed.
void main() {
  for (var seed = 0; seed < seeds; seed++) {
    test('seed $seed', () async {
      final model = Model(Random(seed));
      final healthy = World(brokenLog: false);
      final broken = World(brokenLog: true);
      addTearDown(healthy.dispose);
      addTearDown(broken.dispose);
      final steps = <String>[];

      for (var i = 0; i < stepsPerSeed; i++) {
        final step = model.next();
        steps.add(step.label);
        await step.run(healthy);
        await step.run(broken);

        final reason = 'seed $seed, after:\n  ${steps.join('\n  ')}';
        await healthy.expectLog(model, reason);
        await healthy.expectCacheInLog(reason);
        await healthy.expectSameCache(broken, reason);
      }
    });
  }
}

/// One thing that happens, for a [World].
final class Step {
  Step(this.label, this.run);

  final String label;
  final Future<void> Function(World) run;
}

/// What should be true, worked out with no session or database at all.
final class Model {
  Model(this.random);

  final Random random;

  /// What the server has, by topic.
  final server = <String, List<DataMessage>>{
    for (final topic in [...direct, friends]) topic: [],
  };

  /// What the device has seen and hasn't heard is deleted, by topic.
  final seen = <String, Map<int, DataMessage>>{
    for (final topic in [...direct, friends]) topic: {},
  };

  final _nextSeq = <String, int>{};
  var _connected = true;

  List<String> get _alive => server.keys.toList();

  List<String> get _aliveDirect => [
    for (final topic in _alive)
      if (topic != friends) topic,
  ];

  String _pick(List<String> topics) => topics[random.nextInt(topics.length)];

  int _seq(String topic) =>
      _nextSeq.update(topic, (seq) => seq + 1, ifAbsent: () => 1);

  /// A new message on the server, which the device sees if connected.
  Step _arrive(DataMessage message, String what) {
    final topic = message.topic;
    server[topic]!.add(message);
    if (_connected) {
      seen[topic]![message.seq] = message;
      return Step('$what live: $topic ${message.seq}', (world) async {
        world.remote
          ..histories[topic]!.add(message)
          ..emitMessage(message);
      });
    }
    return Step('$what offline: $topic ${message.seq}', (world) async {
      world.remote.histories[topic]!.add(message);
    });
  }

  Step _call() {
    final topic = _pick(_alive);
    return _arrive(
      callMessage(topic, _seq(topic), from: random.nextBool() ? alice : bob),
      'call',
    );
  }

  Step _update() {
    final topic = _pick(_alive);
    final calls = [
      for (final message in server[topic]!)
        if (message.head?.callState != null && message.head?.replaces == null)
          message,
    ];
    if (calls.isEmpty) {
      return _call();
    }
    final call = calls[random.nextInt(calls.length)];
    const states = [
      CallState.accepted,
      CallState.declined,
      CallState.missed,
      CallState.finished,
    ];
    return _arrive(
      callUpdate(
        topic,
        _seq(topic),
        call.seq,
        states[random.nextInt(states.length)],
        from: call.from,
        duration: Duration(seconds: random.nextInt(600)),
      ),
      'update of ${call.seq}',
    );
  }

  Step _text() {
    final topic = _pick(_alive);
    return _arrive(message(topic, _seq(topic)), 'text');
  }

  /// What the server answers, as `FakeTinodeSession.history` does.
  List<DataMessage> _page(String topic, int limit, {int? since, int? before}) {
    final all = [
      for (final message in server[topic]!)
        if ((before == null || message.seq < before) &&
            (since == null || message.seq >= since))
          message,
    ]..sort((a, b) => a.seq.compareTo(b.seq));
    return all.length <= limit ? all : all.sublist(all.length - limit);
  }

  void _see(List<DataMessage> page) {
    for (final message in page) {
      seen[message.topic]![message.seq] = message;
    }
  }

  Step _fetch() {
    final topic = _pick(_alive);
    final newest = _nextSeq[topic] ?? 0;
    final before = random.nextBool() ? 1 + random.nextInt(newest + 2) : null;
    final since = random.nextBool() ? 1 + random.nextInt(newest + 1) : null;
    final limit = 1 + random.nextInt(12);
    _see(_page(topic, limit, since: since, before: before));
    return Step('page: $topic since $since before $before limit $limit', (
      world,
    ) async {
      await world.session.history(
        topic,
        limit: limit,
        since: since,
        before: before,
      );
    });
  }

  /// A few seqs that were given out: a server can't delete any others, and
  /// a seq is never used twice.
  SeqRange? _range(String topic) {
    final newest = _nextSeq[topic] ?? 0;
    if (newest == 0) {
      return null;
    }
    final low = 1 + random.nextInt(newest);
    return SeqRange(low, min(low + 1 + random.nextInt(3), newest + 1));
  }

  void _forget(String topic, SeqRange range) {
    server[topic]!.removeWhere((message) => range.contains(message.seq));
    seen[topic]!.removeWhere((seq, _) => range.contains(seq));
  }

  Step _deleteHere() {
    final topic = _pick(_alive);
    final range = _range(topic);
    if (range == null) {
      return _call();
    }
    _forget(topic, range);
    final hard = random.nextBool();
    return Step('delete here: $topic $range hard $hard', (world) async {
      await world.session.delete(topic, [range], forEveryone: hard);
      await world.outboxDrained();
    });
  }

  Step _deleteElsewhere() {
    final topic = _pick(_alive);
    final range = _range(topic);
    if (range == null) {
      return _call();
    }
    _forget(topic, range);
    return Step('delete elsewhere: $topic $range', (world) async {
      final id = world.remote.recordDeletion(topic, [range]);
      world.remote.emitPresence(
        PresMessage(
          topic: topic,
          event: PresenceEvent.deleted,
          lastDeleteId: id,
          deletedRanges: [range],
        ),
      );
      await world.settled();
    });
  }

  void _drop(String topic) {
    server.remove(topic);
    seen.remove(topic);
  }

  Step _leave() {
    final topic = _pick(_aliveDirect);
    _drop(topic);
    return Step('leave $topic', (world) async {
      await world.session.leaveChat(topic);
      await world.settled();
    });
  }

  Step _gone() {
    final topic = _pick(_aliveDirect);
    _drop(topic);
    return Step('gone from the server: $topic', (world) async {
      world.remote
        ..chats.removeWhere((c) => c.topic == topic)
        ..emitPresence(
          PresMessage(topic: 'me', event: PresenceEvent.gone, source: topic),
        );
      await world.settled();
    });
  }

  Step _linkDown() {
    _connected = false;
    return Step('link down', (world) async {
      world.remote.emitStatus(
        const Reconnecting(attempt: 1, retryIn: Duration.zero),
      );
    });
  }

  Step _linkUp() {
    _connected = true;
    return Step('link up', (world) async {
      world.remote.emitStatus(const Connected());
      await world.settled();
    });
  }

  Step _restart() {
    _connected = true;
    final keep = 1 + random.nextInt(10);
    return Step('restart keeping $keep per chat', (world) async {
      await world.restart(TinodeCacheLimits(messagesPerChat: keep));
    });
  }

  /// Logs out, with things happening meanwhile, and in again.
  Step _logOutAndIn() {
    _connected = true;
    final deletions = <(String, SeqRange)>[];
    for (final topic in _alive) {
      if (random.nextInt(3) == 0) {
        if (_range(topic) case final range?) {
          _forget(topic, range);
          deletions.add((topic, range));
        }
      }
    }
    final gone = <String>[];
    if (_aliveDirect.length > 1 && random.nextInt(4) == 0) {
      final topic = _pick(_aliveDirect);
      gone.add(topic);
      _drop(topic);
    }
    final topics = _alive..forEach(_seeLatest);
    return Step('log out and in; meanwhile $deletions, gone $gone', (
      world,
    ) async {
      await world.logOutAndIn(deletions, gone, topics);
    });
  }

  void _seeLatest(String topic) => _see(_page(topic, catchUpPage));

  Step next() {
    if (!_connected) {
      return switch (random.nextInt(4)) {
        0 => _linkUp(),
        1 => _call(),
        2 => _update(),
        _ => _text(),
      };
    }
    final roll = random.nextInt(100);
    if (roll < 22) {
      return _call();
    }
    if (roll < 40) {
      return _update();
    }
    if (roll < 50) {
      return _text();
    }
    if (roll < 68) {
      return _fetch();
    }
    if (roll < 75) {
      return _deleteHere();
    }
    if (roll < 81) {
      return _deleteElsewhere();
    }
    if (roll < 83 && _aliveDirect.length > 1) {
      return _leave();
    }
    if (roll < 85 && _aliveDirect.length > 1) {
      return _gone();
    }
    if (roll < 89) {
      return _linkDown();
    }
    if (roll < 94) {
      return _restart();
    }
    return _logOutAndIn();
  }

  /// The calls the log must hold: `topic seq [updates] state`, sorted.
  List<String> expected() => [
    for (final topic in seen.keys.where(direct.contains).toList()..sort())
      ..._expectedIn(topic),
  ];

  List<String> _expectedIn(String topic) {
    final messages =
        seen[topic]!.values.where((m) => m.head?.callState != null).toList()
          ..sort((a, b) => a.seq.compareTo(b.seq));
    return [
      for (final base in messages)
        if (base.head?.replaces == null)
          () {
            final updates = [
              for (final message in messages)
                if (message.head?.replaces == ':${base.seq}') message,
            ];
            final state =
                updates.lastOrNull?.head?.callState ?? base.head?.callState;
            return '$topic ${base.seq} '
                '${[for (final update in updates) update.seq]} $state';
          }(),
    ];
  }
}

/// The app and its own copy of the server.
final class World {
  World({required this.brokenLog}) {
    logFault.failing = brokenLog;
    _log = CallLogDatabase(NativeDatabase.memory().interceptWith(logFault));
    _cache = ChatDatabase(NativeDatabase.memory());
    remote = FakeTinodeSession(chats: _chats, histories: _histories);
    _open();
  }

  final bool brokenLog;
  final logFault = DatabaseFault();
  late final CallLogDatabase _log;
  late ChatDatabase _cache;
  late ChatStore _store;
  late FakeTinodeSession remote;
  late CachedTinodeSession session;

  // Their `lastSeq` stays 0, so the latest catch-up stays out of it: a day's
  // fetches are its steps, and the model knows what they bring.
  final List<Subscription> _chats = [
    for (final topic in [...direct, friends]) chat(topic),
  ];
  final _histories = <String, List<DataMessage>>{
    for (final topic in [...direct, friends]) topic: [],
  };

  void _open({TinodeCacheLimits limits = const TinodeCacheLimits()}) {
    _store = ChatStore(_cache, ownsDatabase: false);
    session = CachedTinodeSession(
      remote,
      _store,
      userId: alice,
      calls: CallLog(_log, ownsDatabase: false),
      limits: limits,
    );
  }

  void _relink() {
    final next = FakeTinodeSession(chats: _chats, histories: _histories);
    next.deleteLogs.addAll(remote.deleteLogs);
    remote = next;
  }

  Future<void> settled() => pumpEventQueue(times: 30);

  Future<void> outboxDrained() async {
    for (var i = 0; i < 200 && (await _store.outbox()).isNotEmpty; i++) {
      await settled();
    }
    expect(await _store.outbox(), isEmpty, reason: 'the outbox is stuck');
  }

  Future<void> restart(TinodeCacheLimits limits) async {
    await session.close();
    _relink();
    _open(limits: limits);
  }

  Future<void> logOutAndIn(
    List<(String, SeqRange)> deletions,
    List<String> gone,
    List<String> topics,
  ) async {
    await session.close();
    await _cache.close();
    _cache = ChatDatabase(NativeDatabase.memory());
    _relink();
    for (final (topic, range) in deletions) {
      remote.recordDeletion(topic, [range]);
    }
    remote.chats.removeWhere((c) => gone.contains(c.topic));
    _open();
    await session.chatList();
    for (final topic in topics) {
      await session.catchUp(topic, limit: catchUpPage);
    }
    await settled();
  }

  Future<void> expectLog(Model model, String reason) async {
    final calls = await session.storedCalls();
    String line(CachedCall call) {
      final updates = [for (final update in call.updates) update.seq];
      final state = CallHistoryEntry.of(call, me: alice)?.call.state;
      return '${call.message.topic} ${call.message.seq} $updates $state';
    }

    final actual = calls.map(line).toList();
    expect(actual, model.expected(), reason: reason);
  }

  /// Every call the cache holds is in the log, with all its updates.
  Future<void> expectCacheInLog(String reason) async {
    await session.storedPage(bob, limit: 1);
    final logged = {
      for (final call in await session.storedCalls())
        (call.message.topic, call.message.seq): {
          for (final update in call.updates) update.seq,
        },
    };
    for (final call in await cachedCallsOracle(_cache)) {
      if (call.message.topic == friends) {
        continue;
      }
      final id = (call.message.topic, call.message.seq);
      expect(logged.keys, contains(id), reason: reason);
      expect(
        logged[id],
        containsAll([for (final update in call.updates) update.seq]),
        reason: reason,
      );
    }
  }

  /// What [_cache] holds: messages and what it knows it fetched.
  Future<List<String>> cacheDump() async {
    await session.storedPage(bob, limit: 1);
    final rows =
        await (_cache.select(_cache.messages)..orderBy([
              (m) => OrderingTerm.asc(m.topic),
              (m) => OrderingTerm.asc(m.seq),
            ]))
            .get();
    final coverage = [
      for (final topic in [...direct, friends])
        '$topic ${jsonEncode(await _store.coverage(topic))}',
    ];
    return [for (final row in rows) row.json, ...coverage];
  }

  Future<void> expectSameCache(World other, String reason) async {
    expect(await cacheDump(), await other.cacheDump(), reason: reason);
  }

  Future<void> dispose() async {
    logFault.failing = false;
    await session.close();
    await _cache.close();
    await _log.close();
  }
}
