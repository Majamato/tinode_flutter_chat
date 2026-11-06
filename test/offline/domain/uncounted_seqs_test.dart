import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/domain/uncounted_seqs.dart';

void main() {
  MessageHead update(CallState? state) =>
      MessageHead(replaces: ':4', callState: state);

  test('a plain message keeps nothing out', () {
    expect(uncountedBy(5, null), isEmpty);
    expect(uncountedBy(5, const MessageHead()), isEmpty);
  });

  test('a call that starts keeps nothing out', () {
    expect(
      uncountedBy(4, const MessageHead(callState: CallState.started)),
      isEmpty,
    );
  });

  test('an edit keeps itself out', () {
    expect(uncountedBy(5, update(null)), {5});
  });

  for (final state in [
    CallState.accepted,
    CallState.finished,
    CallState.declined,
  ]) {
    test('a call that was ${state.name} keeps itself out too', () {
      expect(uncountedBy(5, update(state)), {4, 5});
    });
  }

  for (final state in [CallState.missed, CallState.disconnected]) {
    test('a call that was ${state.name} still counts', () {
      expect(uncountedBy(5, update(state)), {5});
    });
  }
}
