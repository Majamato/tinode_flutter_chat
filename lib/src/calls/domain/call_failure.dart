import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

/// Why a call failed, in terms the UI can explain to the user.
enum CallFailure {
  permissionDenied,

  /// The chat already has a call (486).
  busy,

  /// The server has no ICE servers (501) or the chat takes no calls (403).
  unavailable,

  /// This device lost the chat server; the server ends its calls then.
  connectionLost,

  /// The WebRTC link failed before the call connected, or the media
  /// could not be opened.
  mediaFailed,

  /// The link of a connected call dropped and didn't come back.
  callLost,
  unexpected;

  static CallFailure of(Object error) => switch (error) {
    CallMediaException(permissionDenied: true) => permissionDenied,
    CallMediaException() => mediaFailed,
    ServerException(code: 486) => busy,
    ServerException(code: 403 || 501) => unavailable,
    ConnectionClosedException() ||
    ConnectionLostException() ||
    ServerUnreachableException() => connectionLost,
    _ => unexpected,
  };
}
