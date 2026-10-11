import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// Where a reveal stands.
enum RevealStatus {
  /// The message is being loaded, or the chat itself.
  loading,

  /// The message is loaded: the list scrolls to it and highlights it.
  shown,

  /// The message can't be shown: deleted, or offline and not cached.
  unavailable,
}

/// A message the user asked to see in an open chat, e.g. one that message
/// search found.
final class MessageReveal with ValueObject {
  const MessageReveal(this.seq, {this.status = RevealStatus.loading});

  final int seq;
  final RevealStatus status;

  /// The bubble of [seq] is highlighted.
  bool highlights(int seq) => status == RevealStatus.shown && seq == this.seq;

  @override
  List<Object?> get props => [seq, status];
}
