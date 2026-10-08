import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// Where a message the user wrote stands before the server numbers it.
enum OutgoingStatus {
  /// Waiting in the outbox, e.g. for the connection.
  queued,

  /// On its way to the server.
  sending,

  /// The server refused it, or it kept failing; the user can retry or
  /// discard it.
  failed,
}

/// A message in the outbox. Once the server accepts it, it becomes an
/// ordinary message with a seq.
final class OutgoingMessage with ValueObject {
  const OutgoingMessage({
    required this.clientId,
    required this.topic,
    required this.content,
    required this.createdAt,
    this.status = OutgoingStatus.queued,
    this.failure,
  });

  final String clientId;
  final String topic;
  final MessageContent content;
  final DateTime createdAt;
  final OutgoingStatus status;

  /// Why it failed; set when [status] is [OutgoingStatus.failed].
  final ChatFailure? failure;

  OutgoingMessage withStatus(OutgoingStatus status, {ChatFailure? failure}) =>
      OutgoingMessage(
        clientId: clientId,
        topic: topic,
        content: content,
        createdAt: createdAt,
        status: status,
        failure: status == OutgoingStatus.failed ? failure : null,
      );

  @override
  List<Object?> get props => [
    clientId,
    topic,
    content,
    createdAt,
    status,
    failure,
  ];
}
