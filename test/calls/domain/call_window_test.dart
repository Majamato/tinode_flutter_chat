import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_window.dart';
import 'package:tinode_flutter_chat/src/chats/domain/call_record.dart';
import 'package:tinode_flutter_chat/src/offline/domain/call_page.dart';

import '../../support/fixtures.dart';

void main() {
  CallHistoryEntry call(
    String topic,
    int seq, {
    int? minute,
    CallState state = CallState.finished,
  }) => CallHistoryEntry(
    topic: topic,
    seq: seq,
    time: at(minute ?? seq),
    outgoing: false,
    call: CallRecord(state: state),
  );

  CallKey key(String topic, int seq) => call(topic, seq).key;

  test('has nothing and has read nothing at first', () {
    const window = CallWindow();

    expect(window.ids, isEmpty);
    expect(window.started, isFalse);
    expect(window.reachedEnd, isFalse);
  });

  test('takes pages below what it holds, newest first', () {
    final first = const CallWindow().withPage([
      call(bob, 9),
      call(carol, 7),
    ], next: key(carol, 7));
    final second = first.withPage([call(bob, 5), call(carol, 2)]);

    expect(first.started, isTrue);
    expect(first.reachedEnd, isFalse);
    expect(first.cursor, key(carol, 7));
    expect(second.ids, [
      (topic: bob, seq: 9),
      (topic: carol, seq: 7),
      (topic: bob, seq: 5),
      (topic: carol, seq: 2),
    ]);
    expect(second.reachedEnd, isTrue);
    expect(second[(topic: carol, seq: 2)]?.time, at(2));
  });

  test('orders as the call log does: time, then chat, then seq', () {
    final window = const CallWindow().withPage([
      call(bob, 3, minute: 5),
      call(carol, 1, minute: 5),
      call(bob, 4, minute: 5),
      call(bob, 9, minute: 1),
    ]);

    expect(window.ids, [
      (topic: carol, seq: 1),
      (topic: bob, seq: 4),
      (topic: bob, seq: 3),
      (topic: bob, seq: 9),
    ]);
  });

  group('a chat read again', () {
    final window = const CallWindow().withPage([
      call(bob, 9),
      call(carol, 8),
      call(bob, 6),
      call(carol, 5),
    ], next: key(carol, 5));

    test('gets its new calls, loses its deleted ones', () {
      final read = window.withChat(bob, [
        call(bob, 12),
        call(bob, 9),
      ], from: key(carol, 5));

      expect(read.ids, [
        (topic: bob, seq: 12),
        (topic: bob, seq: 9),
        (topic: carol, seq: 8),
        (topic: carol, seq: 5),
      ]);
      expect(read.cursor, key(carol, 5));
    });

    test('changes the calls that changed', () {
      final read = window.withChat(bob, [
        call(bob, 9, state: CallState.missed),
        call(bob, 6),
      ], from: key(carol, 5));

      expect(read[(topic: bob, seq: 9)]?.call.state, CallState.missed);
      expect(read.ids, same(window.ids));
    });

    test('keeps its calls older than where it was read from', () {
      // Read from (carol, 8), then a page came in below it.
      final paged = window.withPage([call(bob, 2)]);
      final read = paged.withChat(bob, [
        call(bob, 9, state: CallState.missed),
      ], from: key(carol, 8));

      expect(read.ids, [
        (topic: bob, seq: 9),
        (topic: carol, seq: 8),
        (topic: bob, seq: 6),
        (topic: carol, seq: 5),
        (topic: bob, seq: 2),
      ]);
      expect(read[(topic: bob, seq: 9)]?.call.state, CallState.missed);
    });

    test('is read whole once the end was reached', () {
      final ended = window.withPage(const []);
      final read = ended.withChat(carol, [call(carol, 1)]);

      expect(ended.cursor, isNull);
      expect(read.ids, [
        (topic: bob, seq: 9),
        (topic: bob, seq: 6),
        (topic: carol, seq: 1),
      ]);
    });

    test('changes nothing before the first page', () {
      const window = CallWindow();

      expect(window.withChat(bob, [call(bob, 1)]), same(window));
    });
  });

  test('keeps its order instance while the order holds', () {
    final window = const CallWindow().withPage([call(bob, 1), call(carol, 3)]);

    expect(window.withChat(bob, [call(bob, 1)]).ids, same(window.ids));
    expect(window.withChat(bob, const []).ids, [(topic: carol, seq: 3)]);
  });
}
