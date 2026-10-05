import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_list_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_summary.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import '../../support/fixtures.dart';

void main() {
  final list = const ChatListState.loading().loaded([
    ChatSummary.fromSubscription(
      chat(bob, name: 'Bob', lastSeq: 4, read: 2, lastMessageAt: at(10)),
    ),
    ChatSummary.fromSubscription(
      chat(
        friends,
        name: 'Friends',
        lastSeq: 9,
        read: 9,
        lastMessageAt: at(20),
      ),
    ),
    ChatSummary.fromSubscription(chat(carol, name: 'Carol')),
  ]);

  test('orders chats newest first, chats without messages last', () {
    expect(list.status, LoadStatus.ready);
    expect(list.order, [friends, bob, carol]);
  });

  test('a summary reads the subscription', () {
    final bobChat = list.byTopic[bob]!;
    expect(bobChat.title, 'Bob');
    expect(bobChat.kind, TopicKind.direct);
    expect(bobChat.unread, 2);
    expect(bobChat.initials, 'B');
    expect(bobChat.canWrite, isTrue);
  });

  test('a follower without W cannot write', () {
    final summary = ChatSummary.fromSubscription(chat(channel, mode: 'JRP'));
    expect(summary.canWrite, isFalse);
    expect(summary.kind, TopicKind.channel);
  });

  test('a new message moves the chat up and counts as unread', () {
    final updated = list.update(bob, (c) => c.withMessage(5, at(30)));

    expect(updated.order, [bob, friends, carol]);
    expect(updated.byTopic[bob]!.unread, 3);
  });

  test('a read marker keeps the order instance', () {
    final updated = list.update(bob, (c) => c.withRead(4));

    expect(updated.byTopic[bob]!.unread, 0);
    expect(updated.order, same(list.order));
  });

  test('nothing new returns the same state', () {
    expect(list.update(bob, (c) => c.withRead(1)), same(list));
    expect(list.update(bob, (c) => c.withMessage(3, at(40))), same(list));
    expect(list.update('usrNobody', (c) => c.withRead(9)), same(list));
  });

  test('a newer message in the top chat keeps the order instance', () {
    final updated = list.update(friends, (c) => c.withMessage(10, at(50)));

    expect(updated.order, same(list.order));
  });

  test('failed keeps the chats', () {
    final failed = list.failed(ChatFailure.timeout);
    expect(failed.status, LoadStatus.failed);
    expect(failed.order, same(list.order));
  });

  test('initials take the first two words', () {
    final summary = ChatSummary.fromSubscription(
      chat(friends, name: 'the book club'),
    );
    expect(summary.initials, 'TB');
  });
}
