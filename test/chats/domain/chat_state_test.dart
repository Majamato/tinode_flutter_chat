import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/call_record.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_message.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import '../../support/fixtures.dart';

ChatMessage msg(int seq, {String text = 'hi', bool own = false}) => ChatMessage(
  seq: seq,
  time: at(seq),
  content: PlainText(text),
  isOwn: own,
  from: own ? alice : bob,
);

/// Call [seq], started by bob.
ChatMessage callMsg(int seq, {bool audioOnly = false}) => ChatMessage(
  seq: seq,
  time: at(seq),
  content: const PlainText(' '),
  isOwn: false,
  from: bob,
  call: CallRecord(state: CallState.started, audioOnly: audioOnly),
);

/// The server's update [seq] to call [target], in the caller's name.
ChatMessage update(
  int seq,
  int target,
  CallState state, {
  Duration? duration,
  String from = bob,
}) => ChatMessage(
  seq: seq,
  time: at(seq),
  content: const PlainText(' '),
  isOwn: false,
  from: from,
  call: CallRecord(state: state, duration: duration),
  replaces: target,
);

void main() {
  const empty = ChatState.loading();

  test('merges messages in seq order', () {
    final state = empty.withMessages([msg(3), msg(1), msg(2)]);

    expect(state.seqs, [1, 2, 3]);
    expect(state.firstSeq, 1);
    expect(state.lastSeq, 3);
  });

  test('an equal message changes nothing', () {
    final state = empty.withMessages([msg(1), msg(2)]);

    expect(state.withMessages([msg(2)]), same(state));
  });

  test('a changed message keeps the same seqs list', () {
    final state = empty.withMessages([msg(1), msg(2)]);

    final edited = state.withMessages([msg(2, text: 'edited')]);

    expect(edited, isNot(same(state)));
    expect(edited.seqs, same(state.seqs));
    expect(edited.bySeq[2]!.content.text, 'edited');
  });

  test('a new seq replaces the seqs list', () {
    final state = empty.withMessages([msg(1)]);

    expect(state.withMessages([msg(2)]).seqs, isNot(same(state.seqs)));
  });

  test('the publish ack and its echo are one message', () {
    final ack = empty.withMessages([msg(5, own: true)]);

    final echoed = ack.withMessages([msg(5, own: true)]);

    expect(echoed, same(ack));
    expect(echoed.seqs, [5]);
  });

  group('updates', () {
    test('change their target instead of adding a bubble', () {
      final state = empty.withMessages([callMsg(1, audioOnly: true)]);

      final accepted = state.withMessages([update(2, 1, CallState.accepted)]);

      expect(accepted.seqs, same(state.seqs));
      final call = accepted.bySeq[1]!;
      expect(call.call!.state, CallState.accepted);
      expect(call.call!.audioOnly, isTrue, reason: 'kept from the original');
      expect(call.revision, 2);
      expect(call.time, at(1), reason: 'the bubble keeps its place');
    });

    test('count towards the seq bounds', () {
      final state = empty.withMessages([
        callMsg(1),
        update(2, 1, CallState.accepted),
      ]);

      expect(state.seqs, [1]);
      expect(state.firstSeq, 1);
      expect(state.lastSeq, 2);
    });

    test('wait for a target that is not loaded yet', () {
      final newest = empty.withMessages([
        msg(5),
        update(6, 1, CallState.accepted),
        update(7, 1, CallState.finished, duration: const Duration(minutes: 2)),
      ]);
      expect(newest.seqs, [5]);
      expect(newest.pending.keys, [1]);

      final older = newest.withMessages([callMsg(1)]);

      expect(older.seqs, [1, 5]);
      expect(older.pending, isEmpty);
      expect(older.bySeq[1]!.call!.state, CallState.finished);
      expect(older.bySeq[1]!.call!.duration, const Duration(minutes: 2));
    });

    test('out of order, the newest wins', () {
      final state = empty.withMessages([
        callMsg(1),
        update(3, 1, CallState.finished),
        update(2, 1, CallState.accepted),
      ]);

      expect(state.bySeq[1]!.call!.state, CallState.finished);
      expect(state.bySeq[1]!.revision, 3);
    });

    test('a plain copy of the target does not undo them', () {
      final state = empty.withMessages([
        callMsg(1),
        update(2, 1, CallState.missed),
      ]);

      expect(state.withMessages([callMsg(1)]), same(state));
    });

    test('from someone else are ignored', () {
      final state = empty.withMessages([callMsg(1)]);

      final forged = state.withMessages([
        update(2, 1, CallState.finished, from: alice),
      ]);

      expect(forged.bySeq[1], state.bySeq[1]);
    });
  });

  test('ready and failed set the status', () {
    expect(empty.ready(hasOlder: true).status, LoadStatus.ready);
    expect(empty.ready(hasOlder: true).hasOlder, isTrue);
    expect(empty.failed(ChatFailure.timeout).status, LoadStatus.failed);
  });

  test('loading older is a no-op when unchanged', () {
    expect(empty.withLoadingOlder(loading: false), same(empty));
    final loading = empty.withLoadingOlder(loading: true);
    expect(loading.loadingOlder, isTrue);
    expect(
      loading.withLoadingOlder(loading: false, hasOlder: false).loadingOlder,
      isFalse,
    );
  });

  group('outbox', () {
    OutgoingMessage outgoing(String id, {String text = 'hi'}) =>
        OutgoingMessage(
          clientId: id,
          topic: bob,
          content: PlainText(text),
          createdAt: at(0),
        );

    ChatMessage sentAs(int seq, String id) => ChatMessage(
      seq: seq,
      time: at(seq),
      content: const PlainText('hi'),
      isOwn: true,
      from: alice,
      clientId: id,
    );

    test('outgoing messages keep their order; a status change keeps ids', () {
      final queued = const ChatState.loading()
          .withOutgoing(outgoing('a'))
          .withOutgoing(outgoing('b'));
      expect(queued.outgoingIds, ['a', 'b']);

      final failed = queued.withOutgoing(
        outgoing(
          'a',
        ).withStatus(OutgoingStatus.failed, failure: ChatFailure.rejected),
      );
      expect(failed.outgoingIds, same(queued.outgoingIds));
      expect(failed.outgoingById['a']!.status, OutgoingStatus.failed);
      expect(failed.withOutgoing(failed.outgoingById['a']!), same(failed));
    });

    test('a numbered copy replaces the outgoing message', () {
      final queued = const ChatState.loading().withOutgoing(outgoing('a'));
      final sent = queued.withMessages([sentAs(4, 'a')]);
      expect(sent.outgoingIds, isEmpty);
      expect(sent.seqs, [4]);
      // The echo after the ack changes nothing.
      expect(sent.withMessages([sentAs(4, 'a')]), same(sent));
    });

    test('a restart keeps the outbox', () {
      final state = const ChatState.loading()
          .withMessages([msg(1), msg(2)])
          .withOutgoing(outgoing('a'))
          .ready(hasOlder: false);
      final restarted = state.restartedWith([msg(40), msg(41)]);
      expect(restarted.seqs, [40, 41]);
      expect(restarted.firstSeq, 40);
      expect(restarted.outgoingIds, ['a']);
      expect(restarted.status, LoadStatus.ready);
    });
  });

  group('withoutSeqs', () {
    test('drops the messages but keeps the bounds', () {
      final state = const ChatState.loading().withMessages([
        msg(1),
        msg(2),
        msg(3),
      ]);
      final deleted = state.withoutSeqs(const [SeqRange(1, 3)]);
      expect(deleted.seqs, [3]);
      expect(deleted.bySeq.keys, [3]);
      expect(deleted.firstSeq, 1);
      expect(deleted.lastSeq, 3);
    });

    test('nothing deleted returns the same state', () {
      final state = const ChatState.loading().withMessages([msg(1)]);
      expect(state.withoutSeqs(const [SeqRange(5, 9)]), same(state));
    });
  });

  group('runs', () {
    ChatMessage from(String sender, int seq, {int? minute}) => ChatMessage(
      seq: seq,
      time: at(minute ?? seq),
      content: const PlainText('hi'),
      isOwn: sender == alice,
      from: sender,
    );

    test("a sender's messages in a row make one run", () {
      final state = empty.withMessages([
        from(bob, 1),
        from(bob, 2),
        from(carol, 3),
        from(bob, 4),
      ]);
      expect(
        [for (final s in state.seqs) state.startsRun(s)],
        [true, false, true, true],
      );
      expect(
        [for (final s in state.seqs) state.endsRun(s)],
        [false, true, true, true],
      );
    });

    test('a long pause starts a new run', () {
      final state = empty.withMessages([
        from(bob, 1, minute: 1),
        from(bob, 2, minute: 1 + runGap.inMinutes + 1),
      ]);
      expect(state.endsRun(1), isTrue);
      expect(state.startsRun(2), isTrue);
    });

    test('updates are no part of runs; unknown seqs are neither', () {
      final state = empty.withMessages([
        callMsg(1),
        from(bob, 2),
        update(3, 1, CallState.accepted),
      ]);
      expect(state.startsRun(2), isFalse);
      expect(state.endsRun(2), isTrue);
      expect(state.startsRun(3), isFalse);
      expect(state.endsRun(9), isFalse);
      expect(empty.endsRun(1), isFalse);
    });
  });
}
