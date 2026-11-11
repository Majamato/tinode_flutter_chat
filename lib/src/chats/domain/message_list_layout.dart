import 'package:collection/collection.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// What sits at each position of a chat's message list. The list is
/// reversed, so positions count up from the bottom: the typing slot, the
/// outbox newest first, the numbered messages newest first, and last the
/// indicator for older messages.
final class MessageListLayout {
  const MessageListLayout({required this.outbox, required this.seqs});

  /// Client IDs of the messages in the outbox, oldest first.
  final List<String> outbox;

  /// Seqs of the loaded messages, ascending.
  final List<int> seqs;

  /// The typing slot, at the bottom.
  static const typingSlot = 0;

  /// The newest message in the outbox, right above the typing slot.
  static const int _newestOutbox = typingSlot + 1;

  /// The newest numbered message, right above the oldest in the outbox.
  int get _newestNumbered => _newestOutbox + outbox.length;

  /// The indicator for older messages, right above the oldest numbered one.
  int get olderMessages => _newestNumbered + seqs.length;

  /// How many items the list has; the indicator is the last.
  int get itemCount => olderMessages + 1;

  /// What sits at [index].
  MessageListItem itemAt(int index) => switch (index) {
    typingSlot => const TypingSlotItem(),
    _ when index < _newestNumbered => OutboxItem(
      outbox[_fromOtherEnd(index - _newestOutbox, outbox.length)],
    ),
    _ when index < olderMessages => NumberedItem(
      seqs[_fromOtherEnd(index - _newestNumbered, seqs.length)],
    ),
    _ => const OlderMessagesItem(),
  };

  /// Where the outbox message [clientId] sits, or null once it has left the
  /// outbox.
  int? indexOfOutbox(String clientId) {
    final position = outbox.indexOf(clientId);
    return position < 0
        ? null
        : _newestOutbox + _fromOtherEnd(position, outbox.length);
  }

  /// Where the message [seq] sits, or null when it isn't loaded.
  int? indexOfSeq(int seq) {
    final position = binarySearch(seqs, seq);
    return position < 0
        ? null
        : _newestNumbered + _fromOtherEnd(position, seqs.length);
  }

  /// [index] counted from the other end of a list of [length]: newest first
  /// to oldest first, and back.
  static int _fromOtherEnd(int index, int length) => length - 1 - index;
}

/// One item of the message list.
sealed class MessageListItem with ValueObject {
  const MessageListItem();

  @override
  List<Object?> get props => const [];
}

/// The slot the typing bubble grows into.
final class TypingSlotItem extends MessageListItem {
  const TypingSlotItem();
}

/// A message still in the outbox.
final class OutboxItem extends MessageListItem {
  const OutboxItem(this.clientId);

  final String clientId;

  @override
  List<Object?> get props => [clientId];
}

/// A message the server has numbered.
final class NumberedItem extends MessageListItem {
  const NumberedItem(this.seq);

  final int seq;

  @override
  List<Object?> get props => [seq];
}

/// The indicator for older messages, at the top.
final class OlderMessagesItem extends MessageListItem {
  const OlderMessagesItem();
}
