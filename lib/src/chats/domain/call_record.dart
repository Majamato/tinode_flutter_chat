import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// The call a message stands for, as its bubble shows it.
final class CallRecord with ValueObject {
  const CallRecord({
    required this.state,
    this.audioOnly = false,
    this.duration,
  });

  /// Null for messages that are not about a call.
  static CallRecord? fromHead(MessageHead? head) => switch (head) {
    MessageHead(:final callState?) => CallRecord(
      state: callState,
      audioOnly: head.audioOnly,
      duration: head.callDuration,
    ),
    _ => null,
  };

  final CallState state;
  final bool audioOnly;

  /// How long a finished call lasted.
  final Duration? duration;

  /// The call ended without the two sides talking.
  bool get failed => state.isOver && state != CallState.finished;

  /// The record after the server's update [later]. The update leaves out
  /// whether the call is voice only, so that comes from this one.
  CallRecord updatedBy(CallRecord later) => CallRecord(
    state: later.state,
    audioOnly: audioOnly || later.audioOnly,
    duration: later.duration ?? duration,
  );

  @override
  List<Object?> get props => [state, audioOnly, duration];
}
