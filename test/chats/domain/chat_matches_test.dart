import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_list_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_matches.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_summary.dart';

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
    _summary(friends, 'Friends of José', 5),
    _summary(carol, 'Mario Martínez', 3),
    _summary(channel, 'News', 4),
  ]);

  test('has every chat, groups too, most recent first', () {
    final matches = ChatMatches.fromChatList(list);
    expect(matches.chats.map((c) => c.topic), [friends, channel, carol, bob]);
    expect(matches.matching(''), same(matches));
  });

  test('matches names by the start of their words, accents aside', () {
    final matches = ChatMatches.fromChatList(list);
    expect(matches.matching('jose').chats.map((c) => c.topic), [friends]);
    expect(matches.matching('ma mar').chats.map((c) => c.topic), [carol]);
    expect(matches.matching('artinez').isEmpty, isTrue);
  });

  test('a read marker changes nothing', () {
    final before = ChatMatches.fromChatList(list);
    final read = ChatMatches.fromChatList(
      list.update(carol, (chat) => chat.withRead(1)),
    );
    expect(read, before);
    final moved = ChatMatches.fromChatList(
      list.update(bob, (chat) => chat.withMessage(9, at(9))),
    );
    expect(moved, isNot(before));
  });
}
