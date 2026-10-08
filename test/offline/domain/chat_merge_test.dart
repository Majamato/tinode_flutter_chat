import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/domain/chat_merge.dart';

void main() {
  final stored = Subscription(
    topic: 'usrBob',
    updated: DateTime.utc(2026, 10),
    lastMessageAt: DateTime.utc(2026, 10, 2),
    lastSeq: 10,
    read: 8,
    received: 9,
    public: const Profile(name: 'Bob'),
    private: const PrivateSettings(comment: 'friend'),
  );

  test('a patch without public or private keeps them', () {
    final merged = mergeChat(
      stored,
      Subscription(
        topic: 'usrBob',
        lastSeq: 12,
        read: 9,
        lastMessageAt: DateTime.utc(2026, 10, 3),
      ),
    );
    expect(merged.public?.name, 'Bob');
    expect(merged.private?.comment, 'friend');
    expect(merged.lastSeq, 12);
    expect(merged.read, 9);
    expect(merged.received, 9);
    expect(merged.lastMessageAt, DateTime.utc(2026, 10, 3));
  });

  test('counters never move back', () {
    final merged = mergeChat(
      stored,
      const Subscription(topic: 'usrBob', lastSeq: 3, read: 1),
    );
    expect(merged.lastSeq, 10);
    expect(merged.read, 8);
  });

  test('a new public replaces the old', () {
    final merged = mergeChat(
      stored,
      const Subscription(
        topic: 'usrBob',
        public: Profile(name: 'Robert'),
      ),
    );
    expect(merged.public?.name, 'Robert');
  });

  test('advanceChat raises only what it is given', () {
    final advanced = advanceChat(stored, read: 10);
    expect(advanced.read, 10);
    expect(advanced.lastSeq, 10);
    expect(advanced.public, stored.public);
    expect(advanceChat(stored, read: 2), stored);
  });

  test('the watermark is the newest change, less a millisecond', () {
    expect(chatListWatermark(const []), isNull);
    expect(
      chatListWatermark([
        stored,
        Subscription(topic: 'grpX', updated: DateTime.utc(2026, 10, 5)),
      ]),
      DateTime.utc(2026, 10, 4, 23, 59, 59, 999),
    );
  });
}
