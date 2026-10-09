import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_members.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_receipt.dart';

import '../../support/fixtures.dart';

void main() {
  final three = const ChatMembers().withMembers([
    member(alice, name: 'Alice', read: 9, received: 9),
    member(bob, name: 'Bob', read: 3, received: 5),
    member(carol, name: 'Carol', read: 4, received: 4),
  ]);

  MessageReceipt receipt(ChatMembers members, int seq) =>
      members.receiptOf(seq, me: alice, kind: TopicKind.group);

  group('receipts', () {
    test('read once every other member read it', () {
      expect(receipt(three, 3), MessageReceipt.read);
      expect(receipt(three, 4), MessageReceipt.delivered);
    });

    test('delivered once every other member received or read it', () {
      // Carol read 4 without a received marker: reading implies receiving.
      expect(receipt(three, 4), MessageReceipt.delivered);
      expect(receipt(three, 5), MessageReceipt.sent);
    });

    test("the user's own counters never count", () {
      final alone = const ChatMembers().withMembers([member(alice, read: 9)]);
      expect(receipt(alone, 1), MessageReceipt.sent);
    });

    test('members who may not read are left out', () {
      final members = three.withMember(member(bob, mode: 'JW'));
      expect(receipt(members, 4), MessageReceipt.read);
    });

    test('a direct chat counts the peer', () {
      final direct = const ChatMembers().withMembers([
        member(alice, read: 7),
        member(bob, read: 2, received: 7),
      ]);
      expect(
        direct.receiptOf(2, me: alice, kind: TopicKind.direct),
        MessageReceipt.read,
      );
      expect(
        direct.receiptOf(7, me: alice, kind: TopicKind.direct),
        MessageReceipt.delivered,
      );
    });

    test('a channel and an unknown chat stay sent', () {
      expect(
        three.receiptOf(1, me: alice, kind: TopicKind.channel),
        MessageReceipt.sent,
      );
      expect(receipt(const ChatMembers(), 1), MessageReceipt.sent);
    });
  });

  group('updates', () {
    test('counters never move back', () {
      final members = three.advanced(bob, read: 2, received: 6).withMembers([
        member(bob, name: 'Bob', read: 1),
      ]);
      expect((members[bob]!.read, members[bob]!.received), (3, 6));
    });

    test('a full list drops whoever it leaves out', () {
      final members = three.withMembers([member(alice), member(bob)]);
      expect(members.byId.keys, unorderedEquals([alice, bob]));
    });

    test('an entry without a profile keeps the known name and photo', () {
      final members = three.withMember(member(bob, read: 8));
      expect(members[bob]!.name, 'Bob');
      expect(members[bob]!.read, 8);
    });

    test('nothing changed returns the same members', () {
      expect(identical(three.advanced(bob, read: 1), three), isTrue);
      expect(identical(three.advanced('usrNobody', read: 9), three), isTrue);
      expect(identical(three.without('usrNobody'), three), isTrue);
      expect(
        identical(
          three.withMembers([
            member(alice, name: 'Alice', read: 9, received: 9),
            member(bob, name: 'Bob', read: 3, received: 5),
            member(carol, name: 'Carol', read: 4, received: 4),
          ]),
          three,
        ),
        isTrue,
      );
    });

    test('someone who left is gone', () {
      expect(three.without(carol)[carol], isNull);
    });
  });

  test('read by lists the others who read, then those who only received', () {
    final (:read, :delivered) = three.readBy(4, me: alice);
    expect(read.map((m) => m.name), ['Carol']);
    expect(delivered.map((m) => m.name), ['Bob']);
  });

  test('a member without a name has no initials; colours are stable', () {
    final members = const ChatMembers().withMembers([member(bob)]);
    expect(members[bob]!.initials, '');
    expect(members[bob]!.colorIndex, three[bob]!.colorIndex);
    expect(three[bob]!.colorIndex, isNot(three[carol]!.colorIndex));
  });
}
