import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log_database.dart';
import 'package:tinode_flutter_chat/src/offline/domain/cached_call.dart';

import '../../support/faulty_database.dart';
import '../../support/fixtures.dart';

void main() {
  late CallLogDatabase db;
  late CallLog log;

  setUp(() {
    db = CallLogDatabase(NativeDatabase.memory());
    log = CallLog(db);
    addTearDown(log.close);
  });

  /// A call as [shape] writes it.
  String entry(String topic, int seq, List<int> updates) =>
      '$topic $seq $updates';

  /// The shape of [calls]: chat, seq and the seqs of the updates.
  List<String> shape(List<CachedCall> calls) => [
    for (final call in calls)
      entry(call.message.topic, call.message.seq, [
        for (final update in call.updates) update.seq,
      ]),
  ];

  Future<int> rows() async => (await db.select(db.callMessages).get()).length;

  DataMessage wire(Json json) => DataMessage.fromJson(json);

  group('put', () {
    test('each call with its updates, in order', () async {
      await log.put([
        callMessage(bob, 1, audioOnly: true),
        message(bob, 2),
        callUpdate(bob, 3, 1, CallState.accepted),
        callMessage(bob, 4),
        callUpdate(bob, 5, 1, CallState.finished),
        callMessage(carol, 8, from: alice),
      ]);

      final calls = await log.calls();
      expect(shape(calls), [
        entry(bob, 1, [3, 5]),
        entry(bob, 4, <int>[]),
        entry(carol, 8, <int>[]),
      ]);
      expect(calls.first.message.head?.audioOnly, isTrue);
      expect(shape(await log.calls(topic: carol)), [entry(carol, 8, <int>[])]);
    });

    test('says whether it kept anything', () async {
      expect(await log.put([message(bob, 1)]), isFalse);
      expect(await log.put(const []), isFalse);
      expect(await log.put([callMessage(friends, 1)]), isFalse);
      expect(await log.put([message(bob, 2), callMessage(bob, 3)]), isTrue);
    });

    test('keeps calls of direct chats only', () async {
      await log.put([
        message(bob, 1),
        callMessage(friends, 2),
        callMessage(channel, 3),
        callUpdate(friends, 4, 2, CallState.finished),
        callMessage('usrSomeoneElse', 5),
        callMessage('p2pSomeThing', 6),
      ]);

      expect(await rows(), 2);
      expect(await log.topics(), {'usrSomeoneElse', 'p2pSomeThing'});
    });

    test('the same page twice keeps one of each', () async {
      final page = [
        callMessage(bob, 1),
        callUpdate(bob, 2, 1, CallState.finished),
      ];
      await log.put(page);
      await log.put(page);

      expect(await rows(), 2);
      expect(shape(await log.calls()), [
        entry(bob, 1, [2]),
      ]);
    });

    test('a newer copy of a message replaces the older one', () async {
      await log.put([callMessage(bob, 1)]);
      await log.put([callMessage(bob, 1, audioOnly: true)]);

      expect((await log.calls()).single.message.head?.audioOnly, isTrue);
      expect(await rows(), 1);
    });

    test('a message that turns into an update stops being a call', () async {
      await log.put([callMessage(bob, 1), callMessage(bob, 2)]);
      await log.put([callUpdate(bob, 2, 1, CallState.missed)]);

      expect(shape(await log.calls()), [
        entry(bob, 1, [2]),
      ]);
    });

    test('all or nothing: a failure half way writes none of it', () async {
      final fault = DatabaseFault();
      final broken = CallLog(
        CallLogDatabase(NativeDatabase.memory().interceptWith(fault)),
      );
      addTearDown(broken.close);
      await broken.put([callMessage(bob, 1)]);

      fault.failingAfterBatch = true;
      await expectLater(
        broken.put([callMessage(bob, 2), callMessage(carol, 3)]),
        throwsA(isA<InjectedFault>()),
      );
      fault.failingAfterBatch = false;

      expect(shape(await broken.calls()), [entry(bob, 1, <int>[])]);
    });
  });

  group('updates', () {
    test('hide until their call arrives, then show', () async {
      await log.put([callUpdate(bob, 3, 2, CallState.missed)]);
      expect(await log.calls(), isEmpty);
      expect(await log.isEmpty, isFalse);
      expect(await log.topics(), {bob});

      await log.put([callMessage(bob, 2)]);
      expect(shape(await log.calls()), [
        entry(bob, 2, [3]),
      ]);
    });

    test('only join a call of their own chat', () async {
      await log.put([
        callMessage(bob, 1),
        callMessage(carol, 1),
        callUpdate(carol, 2, 1, CallState.finished),
      ]);

      expect(shape(await log.calls()), [
        entry(bob, 1, <int>[]),
        entry(carol, 1, [2]),
      ]);
    });

    test('come in seq order, whatever order they arrived in', () async {
      await log.put([callUpdate(bob, 9, 1, CallState.finished)]);
      await log.put([callUpdate(bob, 3, 1, CallState.accepted)]);
      await log.put([callUpdate(bob, 5, 1, CallState.accepted)]);
      await log.put([callMessage(bob, 1)]);

      expect(shape(await log.calls()), [
        entry(bob, 1, [3, 5, 9]),
      ]);
      // A later seq is what a bubble shows; a wrong order would lose it.
      final calls = await log.calls();
      final call = CallHistoryEntry.of(calls.single, me: alice)!;
      expect(call.call.state, CallState.finished);
    });

    for (final malformed in ['2', ':', ':x', 'garbage', ':1:2', '']) {
      test('"$malformed" as a replace is never a call', () async {
        await log.put([
          callMessage(bob, 1),
          wire({
            'topic': bob,
            'seq': 2,
            'from': bob,
            'ts': '2026-10-04T09:02:00.000Z',
            'head': {'webrtc': 'finished', 'replace': malformed},
            'content': ' ',
          }),
        ]);

        expect(shape(await log.calls()), [entry(bob, 1, <int>[])]);
      });
    }
  });

  group('what the server sends', () {
    const started = {
      'topic': bob,
      'seq': 7,
      'from': alice,
      'ts': '2026-10-04T09:07:00.123Z',
      'head': {'mime': 'text/x-drafty', 'webrtc': 'started', 'aonly': true},
      'content': {
        'txt': ' ',
        'fmt': [
          {'len': 1},
        ],
        'ent': [
          {
            'tp': 'VC',
            'data': {'aonly': true},
          },
        ],
      },
    };
    const finished = {
      'topic': bob,
      'seq': 8,
      'from': alice,
      'ts': '2026-10-04T09:12:00.456Z',
      'head': {
        'mime': 'text/x-drafty',
        'replace': ':7',
        'webrtc': 'finished',
        'webrtc-duration': 300000,
      },
      'content': {
        'txt': ' ',
        'fmt': [
          {'len': 1},
        ],
        'ent': [
          {
            'tp': 'VC',
            'data': {'aonly': true, 'state': 'finished'},
          },
        ],
      },
    };

    test('comes back the same, field by field', () async {
      await log.put([wire(started), wire(finished)]);

      final call = (await log.calls()).single;
      expect(jsonEncode(call.message.toJson()), jsonEncode(wire(started)));
      expect(
        jsonEncode(call.updates.single.toJson()),
        jsonEncode(wire(finished)),
      );
    });

    test('reads as the call it was', () async {
      await log.put([wire(started), wire(finished)]);

      final calls = await log.calls();
      final entry = CallHistoryEntry.of(calls.single, me: alice)!;
      expect(entry.outgoing, isTrue);
      expect(entry.time, DateTime.parse('2026-10-04T09:07:00.123Z'));
      expect(entry.call.state, CallState.finished);
      expect(entry.call.audioOnly, isTrue);
      expect(entry.call.duration, const Duration(minutes: 5));
    });

    test('a state this client does not know yet is kept', () async {
      await log.put([
        wire({
          ...started,
          'head': {'webrtc': 'from-the-future'},
        }),
      ]);

      final head = (await log.calls()).single.message.head!;
      expect(head.callState, CallState.unknown);
      expect(head.toJson()['webrtc'], 'from-the-future');
    });
  });

  group('deleteRanges', () {
    setUp(
      () => log.put([
        for (var seq = 1; seq <= 5; seq++) callMessage(bob, seq),
        callMessage(carol, 2),
      ]),
    );

    List<int> seqs(List<CachedCall> calls) => [
      for (final call in calls)
        if (call.message.topic == bob) call.message.seq,
    ];

    test('covers low, stops short of high, in its chat only', () async {
      await log.deleteRanges(bob, [const SeqRange(2, 4)]);

      final calls = await log.calls();
      expect(seqs(calls), [1, 4, 5]);
      expect(calls.last.message.topic, carol);
    });

    test('takes several ranges', () async {
      await log.deleteRanges(bob, [
        const SeqRange.single(1),
        const SeqRange(4, 6),
      ]);

      expect(seqs(await log.calls()), [2, 3]);
    });

    test('with none, or past the end, deletes nothing', () async {
      await log.deleteRanges(bob, const []);
      await log.deleteRanges(bob, [const SeqRange(50, 60)]);

      expect(seqs(await log.calls()), [1, 2, 3, 4, 5]);
    });

    test('of a call leaves its update hidden', () async {
      await log.put([callUpdate(bob, 6, 2, CallState.finished)]);

      await log.deleteRanges(bob, [const SeqRange.single(2)]);

      expect(seqs(await log.calls()), [1, 3, 4, 5]);
      expect(await rows(), 6);
    });

    test('of an update takes the call back a step', () async {
      await log.put([callUpdate(bob, 6, 2, CallState.finished)]);

      await log.deleteRanges(bob, [const SeqRange.single(6)]);

      final call = (await log.calls()).firstWhere((c) => c.message.seq == 2);
      expect(call.updates, isEmpty);
    });
  });

  test('deleteChat forgets that chat only', () async {
    await log.put([callMessage(bob, 1), callMessage(carol, 1)]);

    await log.deleteChat(bob);
    await log.deleteChat('usrNobody');

    expect(shape(await log.calls()), [entry(carol, 1, <int>[])]);
    expect(await log.topics(), {carol});
  });

  group('an empty log', () {
    test('says so', () async {
      expect(await log.isEmpty, isTrue);
      expect(await log.calls(), isEmpty);
      expect(await log.calls(topic: bob), isEmpty);
      expect(await log.topics(), isEmpty);
    });

    test('takes deletions without complaint', () async {
      await log.deleteChat(bob);
      await log.deleteRanges(bob, [const SeqRange(1, 9)]);

      expect(await log.isEmpty, isTrue);
    });

    test('becomes empty again', () async {
      await log.put([callMessage(bob, 1)]);
      expect(await log.isEmpty, isFalse);

      await log.deleteChat(bob);

      expect(await log.isEmpty, isTrue);
    });
  });

  group('a row that cannot be read', () {
    Future<void> corrupt(int seq, String json) => db.customUpdate(
      'UPDATE call_messages SET json = ? WHERE seq = ?',
      variables: [Variable.withString(json), Variable.withInt(seq)],
      updateKind: UpdateKind.update,
      updates: {db.callMessages},
    );

    setUp(
      () => log.put([
        callMessage(bob, 1),
        callUpdate(bob, 2, 1, CallState.accepted),
        callUpdate(bob, 3, 1, CallState.finished),
        callMessage(bob, 4),
      ]),
    );

    for (final (name, json) in [
      ('not JSON', '{oops'),
      ('empty', ''),
      ('not an object', '[1, 2]'),
      ('the wrong shape', '{"seq": "seven"}'),
    ]) {
      test('$name hides that call, no other', () async {
        await corrupt(1, json);

        expect(shape(await log.calls()), [entry(bob, 4, <int>[])]);
      });

      test('$name in an update hides that update, no other', () async {
        await corrupt(2, json);

        expect(shape(await log.calls()), [
          entry(bob, 1, [3]),
          entry(bob, 4, <int>[]),
        ]);
      });
    }
  });

  test('a store that does not own the database leaves it open', () async {
    await log.put([callMessage(bob, 1)]);
    final borrowed = CallLog(db, ownsDatabase: false);

    await borrowed.close();

    expect(await log.calls(), hasLength(1));
  });

  test('closes the database it owns', () async {
    final owned = CallLogDatabase(NativeDatabase.memory());
    await owned.customStatement('SELECT 1');

    await CallLog(owned).close();

    expect(() => owned.customStatement('SELECT 1'), throwsA(anything));
  });

  group('order of arrival never changes the result', () {
    for (var seed = 0; seed < 100; seed++) {
      test('seed $seed', () async {
        final random = Random(seed);
        // A few calls, each with a few updates, some plain messages.
        final messages = <DataMessage>[];
        var seq = 0;
        for (final topic in [bob, carol, friends]) {
          for (var call = 0; call < 1 + random.nextInt(4); call++) {
            final base = ++seq;
            messages.add(callMessage(topic, base));
            for (var update = 0; update < random.nextInt(3); update++) {
              messages.add(callUpdate(topic, ++seq, base, CallState.accepted));
            }
            if (random.nextBool()) {
              messages.add(message(topic, ++seq));
            }
          }
        }

        // The result of one tidy load, in order.
        await log.put(messages);
        final tidy = shape(await log.calls());

        // The same, shuffled, split in pages, some of them repeated.
        final other = CallLog(CallLogDatabase(NativeDatabase.memory()));
        addTearDown(other.close);
        final arriving = [...messages]..shuffle(random);
        while (arriving.isNotEmpty) {
          final page = arriving.take(1 + random.nextInt(5)).toList();
          arriving.removeRange(0, page.length);
          await other.put(page);
          if (random.nextBool()) {
            await other.put(page);
          }
        }

        expect(shape(await other.calls()), tidy, reason: 'seed $seed');
      });
    }
  });
}
