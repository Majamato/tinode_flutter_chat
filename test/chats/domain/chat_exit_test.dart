import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_exit.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_summary.dart';

import '../../support/fixtures.dart';

void main() {
  ChatExit exitOf(String topic, {String mode = 'JRWPS'}) =>
      ChatExit.of(ChatSummary.fromSubscription(chat(topic, mode: mode)));

  test('a 1:1 chat is deleted for the user', () {
    expect(exitOf(bob), ChatExit.deleteChat);
  });

  test('the owner deletes a group, anyone else leaves it', () {
    expect(exitOf(friends, mode: 'JRWPASDO'), ChatExit.deleteGroup);
    expect(exitOf(friends), ChatExit.leaveGroup);
    expect(exitOf(channel, mode: 'JRP'), ChatExit.leaveGroup);
  });
}
