import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:webrtc_interface/webrtc_interface.dart' show MediaStream;

/// Where the WebRTC link between the two devices stands.
enum CallLinkState { connecting, connected, disconnected, failed, closed }

/// The microphone or camera could not be opened.
final class CallMediaException implements Exception {
  const CallMediaException({required this.permissionDenied, this.cause});

  /// The user, or the OS, refused access.
  final bool permissionDenied;
  final Object? cause;

  @override
  String toString() =>
      'CallMediaException(permissionDenied: $permissionDenied, $cause)';
}

/// The audio, video and WebRTC link of one call. The call logic drives it
/// through this interface, so it runs in tests without devices.
///
/// The caller [open]s the media, then [createOffer]s once the callee
/// accepted; the callee [open]s and [answer]s the offer. Each side passes
/// the other's [candidates] to [addCandidate].
abstract interface class CallMedia {
  /// Opens the microphone, and the front camera when [video] is set. The OS
  /// asks the user for access here; a refusal throws [CallMediaException].
  Future<MediaStream> open({required bool video});

  /// Creates the link with the opened media and returns its offer.
  Future<CallDescription> createOffer();

  /// Creates the link with the opened media for the peer's [offer] and
  /// returns the answer.
  Future<CallDescription> answer(CallDescription offer);

  /// Completes the link the caller offered with the peer's [answer].
  Future<void> acceptAnswer(CallDescription answer);

  /// A network path the peer found. Only valid once both descriptions are
  /// set; the call logic holds earlier ones back.
  Future<void> addCandidate(IceCandidate candidate);

  /// Network paths this device found, to send to the peer.
  Stream<IceCandidate> get candidates;

  /// The peer's audio and video, once they arrive.
  Stream<MediaStream> get remoteStreams;

  Stream<CallLinkState> get linkStates;

  void setMicrophoneEnabled({required bool enabled});

  /// Stops or resumes sending video; the peer sees a still frame.
  void setCameraEnabled({required bool enabled});

  Future<void> switchCamera();

  /// Plays the call on the loudspeaker instead of the earpiece.
  Future<void> setSpeakerOn({required bool on});

  /// Ends the link and releases the microphone and camera.
  Future<void> close();
}

/// Creates the [CallMedia] of one call, with the server's ICE servers.
typedef CallMediaFactory = CallMedia Function(List<IceServer> iceServers);
