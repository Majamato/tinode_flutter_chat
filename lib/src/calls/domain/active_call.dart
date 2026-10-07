import 'package:tinode_flutter_chat/src/calls/domain/call_failure.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';
import 'package:webrtc_interface/webrtc_interface.dart' show MediaStream;

enum CallDirection { outgoing, incoming }

/// Where this device's call stands. Not the server's call state, which
/// the call message records.
enum CallStage {
  /// Opening the microphone and camera before calling.
  preparing,

  /// Published; waiting for the peer's device.
  calling,

  /// The peer's device is ringing.
  ringing,

  /// A call to this user is ringing here.
  incoming,

  /// Accepted; WebRTC is setting up the link.
  connecting,
  connected,

  /// Over; shown briefly before the call screen goes away.
  ended,
}

/// The call this device is in, or is ringing for.
final class ActiveCall with ValueObject {
  const ActiveCall({
    required this.topic,
    required this.direction,
    required this.audioOnly,
    required this.stage,
    this.seq,
    this.micOn = true,
    this.cameraOn = true,
    this.frontCamera = true,
    this.speakerOn = false,
    this.connectedAt,
    this.failure,
    this.acceptedHere = false,
    this.localStream,
    this.remoteStream,
  });

  /// The 1:1 chat of the call.
  final String topic;
  final CallDirection direction;
  final bool audioOnly;
  final CallStage stage;

  /// The seq of the call message, which names the call; null until the
  /// call is published.
  final int? seq;
  final bool micOn;
  final bool cameraOn;
  final bool frontCamera;
  final bool speakerOn;
  final DateTime? connectedAt;

  /// Why the call ended, when it did not end normally.
  final CallFailure? failure;

  /// This device took the incoming call, rather than another of the
  /// user's devices.
  final bool acceptedHere;
  final MediaStream? localStream;
  final MediaStream? remoteStream;

  bool get isOver => stage == CallStage.ended;

  ActiveCall copyWith({
    CallStage? stage,
    int? seq,
    bool? micOn,
    bool? cameraOn,
    bool? frontCamera,
    bool? speakerOn,
    DateTime? connectedAt,
    CallFailure? failure,
    bool? acceptedHere,
    MediaStream? localStream,
    MediaStream? remoteStream,
  }) => ActiveCall(
    topic: topic,
    direction: direction,
    audioOnly: audioOnly,
    stage: stage ?? this.stage,
    seq: seq ?? this.seq,
    micOn: micOn ?? this.micOn,
    cameraOn: cameraOn ?? this.cameraOn,
    frontCamera: frontCamera ?? this.frontCamera,
    speakerOn: speakerOn ?? this.speakerOn,
    connectedAt: connectedAt ?? this.connectedAt,
    failure: failure ?? this.failure,
    acceptedHere: acceptedHere ?? this.acceptedHere,
    localStream: localStream ?? this.localStream,
    remoteStream: remoteStream ?? this.remoteStream,
  );

  @override
  List<Object?> get props => [
    topic,
    direction,
    audioOnly,
    stage,
    seq,
    micOn,
    cameraOn,
    frontCamera,
    speakerOn,
    connectedAt,
    failure,
    acceptedHere,
    localStream,
    remoteStream,
  ];
}
