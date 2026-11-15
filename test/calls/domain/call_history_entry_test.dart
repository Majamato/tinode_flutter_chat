import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';
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
}
