import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_summary.dart';

import '../../support/fixtures.dart';

void main() {
  ChatSummary summary({required int lastSeq, required int read}) =>
      ChatSummary.fromSubscription(chat(bob, lastSeq: lastSeq, read: read));

  group('unread', () {
    test('is what came after the read marker', () {
      expect(summary(lastSeq: 5, read: 3).unread, 2);
    });

    test('leaves out the updates', () {
      final chat = summary(lastSeq: 5, read: 3).withUncounted({5});

      expect(chat.unread, 1);
    });

    test('takes no account of updates already read', () {
      final chat = summary(lastSeq: 5, read: 3).withUncounted({2, 3, 5});

      expect(chat.unread, 1);
      expect(chat.withRead(4).unread, 0);
    });

    test('takes no account of updates the list has not heard of', () {
      final chat = summary(lastSeq: 5, read: 3).withUncounted({6});

      expect(chat.unread, 2);
      expect(chat.withMessage(6, at(6)).unread, 2);
    });

    test('is zero with only updates past the marker', () {
      expect(summary(lastSeq: 5, read: 3).withUncounted({4, 5}).unread, 0);
    });

    test('is zero when the marker is past the last seq', () {
      expect(summary(lastSeq: 3, read: 5).withUncounted({4}).unread, 0);
    });
  });
}
