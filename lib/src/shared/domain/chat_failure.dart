import 'package:tinode_dart_client/tinode_dart_client.dart';

/// An open session ended without the user closing it.
final class ConnectionLostException implements Exception {
  const ConnectionLostException();

  @override
  String toString() => 'ConnectionLostException()';
}

/// What went wrong, in terms the UI can explain to the user.
enum ChatFailure {
  unreachable,
  connectionLost,
  badCredentials,
  timeout,
  rejected,
  unexpected;

  static ChatFailure of(Object error) => switch (error) {
    ServerUnreachableException() => unreachable,
    ConnectionLostException() || ConnectionClosedException() => connectionLost,
    ServerException(code: 401) => badCredentials,
    ServerException() => rejected,
    RequestTimeoutException() => timeout,
    _ => unexpected,
  };
}
