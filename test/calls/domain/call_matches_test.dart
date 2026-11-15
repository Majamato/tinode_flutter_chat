import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_matches.dart';

import '../../support/fixtures.dart';

void main() {
  const dave = 'usrDave';
  const topics = [bob, carol, dave];
  const titles = {bob: 'Bob Núñez', carol: 'Carol'};

  CallMatches matching(String input) => CallMatches.of(topics, titles, input);

  test('blank input matches every chat', () {
    expect(matching(''), const CallMatches.everyChat());
    expect(matching('  '), const CallMatches.everyChat());
    expect(matching('').includes('usrAnyone'), isTrue);
  });

  test('every typed word starts a word of the chat name', () {
    expect(matching('carol').exact, {carol});
    expect(matching('bob nu').exact, {bob});
    expect(matching('nunez').exact, {bob});
    expect(matching('rol'), const CallMatches());
  });

  test('a letter off matches apart from the exact matches', () {
    final matches = CallMatches.of(
      [bob, carol],
      const {bob: 'Carl', carol: 'Carol'},
      'caro',
    );

    expect(matches.exact, {carol});
    expect(matches.typos, {bob});
    expect(matches.includes(bob), isTrue);
    expect(matches.includes(dave), isFalse);
  });

  test('a chat without a name matches by its topic', () {
    expect(matching('usrdave').exact, {dave});
  });

  test('the same chats compare equal', () {
    expect(matching('carol'), CallMatches.of(List.of(topics), titles, 'car'));
  });
}
