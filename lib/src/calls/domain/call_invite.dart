import 'package:collection/collection.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// A call to this user that is still waiting for an answer.
final class CallInvite with ValueObject {
  const CallInvite({
    required this.topic,
    required this.seq,
    required this.from,
    required this.audioOnly,
  });

  /// The call [message] starts, if it is a peer's call to [me] in a 1:1
  /// chat.
  static CallInvite? of(DataMessage message, {required String me}) {
    final head = message.head;
    final from = message.from;
    if (TopicKind.of(message.topic) != TopicKind.direct ||
        from == null ||
        from == me ||
        head?.callState != CallState.started ||
        head?.replacesSeq != null) {
      return null;
    }
    return CallInvite(
      topic: message.topic,
      seq: message.seq,
      from: from,
      audioOnly: head!.audioOnly,
    );
  }

  /// The call [seq] in [page], unless a later message in it shows the call
  /// was already answered or ended.
  static CallInvite? findIn(
    List<DataMessage> page,
    int seq, {
    required String me,
  }) {
    final message = page.firstWhereOrNull((m) => m.seq == seq);
    if (message == null ||
        page.any(
          (m) => m.head?.replacesSeq == seq && m.head?.callState != null,
        )) {
      return null;
    }
    return of(message, me: me);
  }

  final String topic;
  final int seq;

  /// The caller's user ID.
  final String from;
  final bool audioOnly;

  @override
  List<Object?> get props => [topic, seq, from, audioOnly];
}
