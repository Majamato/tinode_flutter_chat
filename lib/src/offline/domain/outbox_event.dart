import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// A change in the outbox, for the chat that shows it.
sealed class OutboxEvent with ValueObject {
  const OutboxEvent();

  String get topic;
}

/// A message was queued, or its status changed.
final class OutgoingChanged extends OutboxEvent {
  const OutgoingChanged(this.message);

  final OutgoingMessage message;

  @override
  String get topic => message.topic;

  @override
  List<Object?> get props => [message];
}

/// The server took the message [clientId]: it is now [message].
final class OutgoingSent extends OutboxEvent {
  const OutgoingSent(this.clientId, this.message);

  final String clientId;
  final DataMessage message;

  @override
  String get topic => message.topic;

  @override
  List<Object?> get props => [clientId, message];
}

/// The user discarded the message [clientId] before it was sent.
final class OutgoingDiscarded extends OutboxEvent {
  const OutgoingDiscarded(this.topic, this.clientId);

  @override
  final String topic;
  final String clientId;

  @override
  List<Object?> get props => [topic, clientId];
}

/// [sent] of [total] bytes of the attachment of message [clientId] have
/// gone to the server. Reported a few times a second at most, never
/// stored.
final class UploadProgress extends OutboxEvent {
  const UploadProgress(this.topic, this.clientId, this.sent, this.total);

  @override
  final String topic;
  final String clientId;
  final int sent;
  final int total;

  /// From 0 to 1.
  double get fraction => total <= 0 ? 0 : (sent / total).clamp(0, 1);

  @override
  List<Object?> get props => [topic, clientId, sent, total];
}

/// Messages of [topic] were deleted, here or elsewhere. When [restored],
/// a deletion of this user's failed and the messages are back: reload.
final class TopicDeletion with ValueObject {
  const TopicDeletion(this.topic, this.ranges, {this.restored = false});

  final String topic;
  final List<SeqRange> ranges;
  final bool restored;

  @override
  List<Object?> get props => [topic, ranges, restored];
}
