import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';
import 'package:tinode_flutter_chat/src/chats/domain/call_record.dart';
import 'package:tinode_flutter_chat/src/offline/domain/cached_call.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_chat_features.dart';

import '../../support/fixtures.dart';

void main() {
  CallHistoryEntry entry(CachedCall call) =>
      CallHistoryEntry.of(call, me: alice)!;

  test('a call takes its updates: an incoming one missed', () {
    final missed = entry(
      CachedCall(callMessage(bob, 1, audioOnly: true), [
        callUpdate(bob, 2, 1, CallState.missed),
      ]),
    );

    expect(missed.topic, bob);
    expect(missed.seq, 1);
    expect(missed.time, at(1));
    expect(missed.outgoing, isFalse);
    expect(missed.call.state, CallState.missed);
    expect(missed.call.audioOnly, isTrue);
    expect(missed.missed, isTrue);
  });

  test("the user's own call that nobody answered isn't missed", () {
    final unanswered = entry(
      CachedCall(callMessage(bob, 1, from: alice), [
        callUpdate(bob, 2, 1, CallState.missed, from: alice),
      ]),
    );

    expect(unanswered.outgoing, isTrue);
    expect(unanswered.call.failed, isTrue);
    expect(unanswered.missed, isFalse);
  });

  test('a message that is no call is no entry', () {
    expect(CallHistoryEntry.of(CachedCall(message(bob, 1)), me: alice), isNull);
  });

  test('calls back with the same kind, else the other, else not', () {
    final voice = entry(CachedCall(callMessage(bob, 1, audioOnly: true)));

    expect(voice.callBackAudioOnly(const TinodeChatFeatures()), isTrue);
    expect(
      voice.callBackAudioOnly(const TinodeChatFeatures(voiceCalls: false)),
      isFalse,
    );
    expect(
      voice.callBackAudioOnly(
        const TinodeChatFeatures(voiceCalls: false, videoCalls: false),
      ),
      isNull,
    );
  });

  group('the history', () {
    CallHistoryEntry entryAt(String topic, int seq, int minutes) =>
        CallHistoryEntry(
          topic: topic,
          seq: seq,
          time: at(minutes),
          outgoing: false,
          call: const CallRecord(state: CallState.finished),
        );

    test('shows the newest calls first, across chats', () {
      final history = const CallHistory().withCalls({
        bob: [entryAt(bob, 1, 1), entryAt(bob, 5, 9)],
        carol: [entryAt(carol, 3, 4)],
      });

      expect(history.loaded, isTrue);
      expect(history.ids, [
        (topic: bob, seq: 5),
        (topic: carol, seq: 3),
        (topic: bob, seq: 1),
      ]);
      expect(history[(topic: carol, seq: 3)]?.time, at(4));
    });

    test('keeps its order instance while the order holds', () {
      final history = const CallHistory().withCalls({
        bob: [entryAt(bob, 1, 1)],
        carol: [entryAt(carol, 3, 4)],
      });

      final unchanged = history.withCalls({
        bob: [entryAt(bob, 1, 1)],
      });
      final emptied = history.withCalls({bob: const []});

      expect(unchanged.ids, same(history.ids));
      expect(emptied.ids, [(topic: carol, seq: 3)]);
      expect(emptied.byTopic.keys, [carol]);
    });
  });
}
