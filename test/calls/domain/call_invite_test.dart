import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_invite.dart';

import '../../support/fixtures.dart';

DataMessage callMessage(
  int seq, {
  String topic = bob,
  String from = bob,
  CallState state = CallState.started,
  bool audioOnly = false,
  int? replaces,
}) => DataMessage(
  topic: topic,
  seq: seq,
  from: from,
  time: at(seq),
  head: MessageHead(
    callState: state,
    audioOnly: audioOnly,
    replaces: replaces == null ? null : ':$replaces',
  ),
  content: DraftyContent(Drafty.videoCall(audioOnly: audioOnly)),
);

void main() {
  group('of', () {
    test("is a peer's call in a 1:1 chat", () {
      expect(
        CallInvite.of(callMessage(4, audioOnly: true), me: alice),
        const CallInvite(topic: bob, seq: 4, from: bob, audioOnly: true),
      );
    });

    test('ignores own calls, group chats, updates and other messages', () {
      expect(CallInvite.of(callMessage(4, from: alice), me: alice), isNull);
      expect(CallInvite.of(callMessage(4, topic: friends), me: alice), isNull);
      expect(
        CallInvite.of(
          callMessage(5, state: CallState.accepted, replaces: 4),
          me: alice,
        ),
        isNull,
      );
      expect(CallInvite.of(message(bob, 4), me: alice), isNull);
    });
  });

  group('findIn', () {
    test('finds a call nobody answered yet', () {
      final page = [callMessage(4), message(bob, 5)];

      expect(CallInvite.findIn(page, 4, me: alice)?.seq, 4);
    });

    test('a call answered or ended in the same page is stale', () {
      for (final state in [CallState.accepted, CallState.missed]) {
        final page = [
          callMessage(4),
          callMessage(5, state: state, replaces: 4),
        ];

        expect(CallInvite.findIn(page, 4, me: alice), isNull, reason: '$state');
      }
    });

    test('a page without the call has none', () {
      expect(CallInvite.findIn([message(bob, 5)], 4, me: alice), isNull);
    });
  });
}
