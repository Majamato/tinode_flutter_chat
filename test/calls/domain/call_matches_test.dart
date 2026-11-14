import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_matches.dart';

import '../../support/fixtures.dart';

void main() {
  const calls = <CallId>[
    (topic: carol, seq: 9),
    (topic: bob, seq: 7),
    (topic: carol, seq: 5),
    (topic: 'usrDave', seq: 3),
  ];
  const titles = {bob: 'Bob Núñez', carol: 'Carol'};

  List<CallId> matching(String input) =>
      CallMatches.matching(calls, titles, input).ids;

  test('blank input keeps every call, in order', () {
    expect(matching(''), calls);
    expect(matching('  '), calls);
  });

  test('every typed word starts a word of the chat name', () {
    expect(matching('carol'), [calls[0], calls[2]]);
    expect(matching('bob nu'), [calls[1]]);
    expect(matching('nunez'), [calls[1]]);
    expect(matching('rol'), isEmpty);
  });

  test('a letter off still matches, after the exact matches', () {
    const mixed = <CallId>[(topic: bob, seq: 4), (topic: carol, seq: 2)];
    final matches = CallMatches.matching(mixed, const {
      bob: 'Carl',
      carol: 'Carol',
    }, 'caro');
    expect(matches.ids, [mixed[1], mixed[0]]);
  });

  test('a chat without a name matches by its topic', () {
    expect(matching('usrdave'), [calls[3]]);
  });

  test('the same calls compare equal', () {
    expect(
      CallMatches.matching(calls, titles, 'carol'),
      CallMatches.matching(List.of(calls), titles, 'car'),
    );
  });
}
