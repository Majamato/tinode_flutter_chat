import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/call_record.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_message.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
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
}
