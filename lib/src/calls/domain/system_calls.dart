import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// The phone's own call screens: CallKit on iOS, a self-managed Telecom
/// connection on Android. They ring over the lock screen, keep the
/// microphone and camera while the app is in the background, and let the
/// user act on a call from outside the app. The call logic reports each
/// call here and follows [actions], so it runs in tests without a phone.
///
/// A call is named by its chat and the seq of its call message, so a call
/// rung from a push and the same call rung by the app are one call.
abstract interface class SystemCalls {
  /// What the user did on the system's screens.
  Stream<SystemCallAction> get actions;

  /// Rings for an incoming [call] for at most [ringFor]. A call that rings
  /// already is left alone.
  Future<void> ring(SystemCall call, {required Duration ringFor});

  /// An outgoing [call] was placed: the system holds the microphone and
  /// camera from now on.
  Future<void> placed(SystemCall call);

  /// The user accepted the incoming [call] in the app rather than on the
  /// system's screen: the ringing stops, and the system holds the
  /// microphone and camera from now on.
  Future<void> acceptedInApp(SystemCall call);

  /// The call's media link is up.
  Future<void> connected(String topic, int seq);

  /// The call is over, or another device took it. A [missed] call leaves a
  /// missed call notification.
  Future<void> end(String topic, int seq, {bool missed = false});

  /// Stops the ringing of a call this device hasn't accepted; one it
  /// accepted goes on. A [missed] call leaves a missed call notification.
  Future<void> stopRinging(String topic, int seq, {bool missed = false});

  /// Shows the microphone as [muted] on the system's call screen.
  Future<void> setMuted(String topic, int seq, {required bool muted});

  /// Calls the user accepted on the system's screen, e.g. before the app
  /// started, that are still going on.
  Future<List<SystemCall>> accepted();
}

/// A call as the system's screens know it.
final class SystemCall with ValueObject {
  const SystemCall({
    required this.topic,
    required this.seq,
    required this.direction,
    required this.audioOnly,
    this.callerName,
    this.hangUpWith,
  });

  /// The 1:1 chat of the call.
  final String topic;

  /// The seq of the call message, which names the call.
  final int seq;
  final CallDirection direction;
  final bool audioOnly;

  /// The peer's name; null when it isn't known, e.g. not in the cache.
  final String? callerName;

  /// How a decline reaches the caller while the app is closed; null to
  /// leave the call to time out on the server.
  final HangUpCredentials? hangUpWith;

  @override
  List<Object?> get props => [
    topic,
    seq,
    direction,
    audioOnly,
    callerName,
    hangUpWith,
  ];
}

/// The server and the user's token, with which a call declined on the
/// system's screen while the app is closed is hung up.
final class HangUpCredentials with ValueObject {
  const HangUpCredentials({
    required this.server,
    required this.apiKey,
    required this.userAgent,
    required this.token,
  });

  final Uri server;
  final String apiKey;
  final String userAgent;
  final String token;

  @override
  List<Object?> get props => [server, apiKey, userAgent, token];
}

/// What the user did with a call on the system's screens.
sealed class SystemCallAction with ValueObject {
  const SystemCallAction({required this.topic, required this.seq});

  final String topic;
  final int seq;
}

/// The user accepted the incoming call.
final class SystemCallAccepted extends SystemCallAction {
  const SystemCallAccepted({
    required super.topic,
    required super.seq,
    required this.audioOnly,
  });

  final bool audioOnly;

  @override
  List<Object?> get props => [topic, seq, audioOnly];
}

/// The user declined the call, or hung up.
final class SystemCallEnded extends SystemCallAction {
  const SystemCallEnded({required super.topic, required super.seq});

  @override
  List<Object?> get props => [topic, seq];
}

/// The user muted or unmuted the microphone, e.g. on CallKit's screen.
final class SystemCallMuted extends SystemCallAction {
  const SystemCallMuted({
    required super.topic,
    required super.seq,
    required this.muted,
  });

  final bool muted;

  @override
  List<Object?> get props => [topic, seq, muted];
}
