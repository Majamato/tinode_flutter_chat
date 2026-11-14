import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_list_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_summary.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/member_suggestions.dart';

import '../../support/fixtures.dart';

ChatSummary _summary(String topic, String title, int minute) => ChatSummary(
  topic: topic,
  kind: TopicKind.of(topic),
  title: title,
  lastMessageAt: at(minute),
);

void main() {
  final list = const ChatListState.loading().loaded([
    _summary(bob, 'Bob', 1),
    _summary(friends, 'Friends', 5),
    _summary(carol, 'Carol Núñez', 3),
    _summary(channel, 'News', 4),
  ]);

  test('suggests the direct chats only, most recent first', () {
    final suggestions = MemberSuggestions.fromChatList(list);
    expect(suggestions.people.map((p) => p.topic), [carol, bob]);
    expect(suggestions.people.first.title, 'Carol Núñez');
    expect(suggestions.has(bob), isTrue);
    expect(suggestions.has(friends), isFalse);
  });

  test('matches names by the start of their words, accents aside', () {
    final suggestions = MemberSuggestions.fromChatList(list);
    expect(suggestions.matching('nun').people.map((p) => p.topic), [carol]);
    expect(suggestions.matching('zed').isEmpty, isTrue);
    expect(suggestions.matching(''), same(suggestions));
  });

  test('a letter off still matches, after the exact matches', () {
    final suggestions = MemberSuggestions.fromChatList(
      const ChatListState.loading().loaded([
        _summary(bob, 'Alice', 5),
        _summary(carol, 'Alce', 3),
      ]),
    );
    expect(suggestions.matching('alce').people.map((p) => p.topic), [
      carol,
      bob,
    ]);
    expect(suggestions.matching('al'), same(suggestions));
  });

  test('a new message changes nothing', () {
    final before = MemberSuggestions.fromChatList(list);
    final after = MemberSuggestions.fromChatList(
      list.update(bob, (chat) => chat.withMessage(9, at(9))),
    );
    // Bob moved to the top: the order changed.
    expect(after, isNot(before));
    final read = MemberSuggestions.fromChatList(
      list.update(carol, (chat) => chat.withRead(1)),
    );
    expect(read, before);
  });
}
