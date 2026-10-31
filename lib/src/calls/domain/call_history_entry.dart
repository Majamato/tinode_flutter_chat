import 'package:tinode_flutter_chat/src/chats/domain/call_record.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_message.dart';
import 'package:tinode_flutter_chat/src/offline/domain/cached_call.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_chat_features.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// One call of the calls history: in which chat, when it started, who
/// called, and how it went.
final class CallHistoryEntry with ValueObject {
  const CallHistoryEntry({
    required this.topic,
    required this.seq,
    required this.time,
    required this.outgoing,
    required this.call,
  });

  /// [cached] with its updates applied; [me] tells the user's own calls
  /// apart. Null when the message isn't a call after all.
  static CallHistoryEntry? of(CachedCall cached, {required String me}) {
    var message = ChatMessage.fromData(cached.message, me: me);
    for (final update in cached.updates) {
      message = message.updatedBy(ChatMessage.fromData(update, me: me));
    }
    return switch (message.call) {
      final call? => CallHistoryEntry(
        topic: cached.message.topic,
        seq: message.seq,
        time: message.time,
        outgoing: message.isOwn,
        call: call,
      ),
      null => null,
    };
  }

  final String topic;

  /// The seq of the message that started the call.
  final int seq;
  final DateTime time;

  /// The user called.
  final bool outgoing;
  final CallRecord call;

  /// Someone called the user, who didn't talk with them.
  bool get missed => !outgoing && call.failed;

  /// Whether to call back without video: as this call was when [features]
  /// offer that kind, else the other kind; null when they offer no calls.
  bool? callBackAudioOnly(TinodeChatFeatures features) =>
      features.allowsCall(audioOnly: call.audioOnly)
      ? call.audioOnly
      : features.allowsCall(audioOnly: !call.audioOnly)
      ? !call.audioOnly
      : null;

  @override
  List<Object?> get props => [topic, seq, time, outgoing, call];
}
