@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';

import 'call_test.dart' show User, eventually;

// Runs against ../tinode-tests, as call_test.dart does.
void main() {
  test('a fresh device finds the calls in its history', () async {
    final alice = await User.login('alice');
    final bob = await User.login('bob');
    await alice.calls.start(bob.id, audioOnly: true);
    final seq = alice.call!.seq!;
    await eventually('bob rings', () => bob.stage == CallStage.incoming);
    bob.calls.decline();
    await eventually('alice sees it', () => alice.stage == CallStage.ended);

    // Bob on another device: nothing cached, and alice's chat untouched.
    final elsewhere = await User.login('bob');
    final container = elsewhere.container
      ..listen(callHistoryControllerProvider, (_, _) {});
    CallHistoryController history() =>
        container.read(callHistoryControllerProvider.notifier);
    await eventually(
      'the history reads the cache',
      () => container.read(callHistoryControllerProvider).loaded,
    );

    await history().refresh();
    await eventually('the declined call shows', () {
      final entry = container.read(callHistoryEntryProvider(alice.id, seq));
      return entry?.call.state == CallState.declined;
    });
    final entry = container.read(callHistoryEntryProvider(alice.id, seq))!;
    expect(entry.outgoing, isFalse);
    expect(entry.call.audioOnly, isTrue);
    expect(container.read(callHistoryControllerProvider).ids.first, (
      topic: alice.id,
      seq: seq,
    ));
  });
}
