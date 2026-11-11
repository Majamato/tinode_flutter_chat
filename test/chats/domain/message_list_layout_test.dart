import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_list_layout.dart';

void main() {
  const layout = MessageListLayout(outbox: ['a', 'b'], seqs: [3, 5, 8]);

  List<MessageListItem> itemsOf(MessageListLayout layout) => [
    for (var index = 0; index < layout.itemCount; index++) layout.itemAt(index),
  ];

  test('an empty chat has only the typing slot and the indicator', () {
    const empty = MessageListLayout(outbox: [], seqs: []);

    expect(itemsOf(empty), const [TypingSlotItem(), OlderMessagesItem()]);
  });

  test('from the bottom: typing, the outbox, the numbered, older', () {
    expect(itemsOf(layout), const [
      TypingSlotItem(),
      OutboxItem('b'),
      OutboxItem('a'),
      NumberedItem(8),
      NumberedItem(5),
      NumberedItem(3),
      OlderMessagesItem(),
    ]);
  });

  test('finds every message where it sits', () {
    for (var index = 0; index < layout.itemCount; index++) {
      final found = switch (layout.itemAt(index)) {
        TypingSlotItem() => MessageListLayout.typingSlot,
        OutboxItem(:final clientId) => layout.indexOfOutbox(clientId),
        NumberedItem(:final seq) => layout.indexOfSeq(seq),
        OlderMessagesItem() => layout.olderMessages,
      };
      expect(found, index);
    }
  });

  test('a message that is gone or not loaded is nowhere', () {
    expect(layout.indexOfOutbox('c'), isNull);
    expect(layout.indexOfSeq(4), isNull);
  });
}
