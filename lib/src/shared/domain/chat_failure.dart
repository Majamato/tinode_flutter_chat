import 'package:tinode_dart_client/tinode_dart_client.dart';

/// An open session ended without the user closing it.
final class ConnectionLostException implements Exception {
  const ConnectionLostException();

  @override
  String toString() => 'ConnectionLostException()';
}

/// A file is over the server's size limit, [limit] bytes; it was not
/// queued.
final class FileTooLargeException implements Exception {
  const FileTooLargeException(this.limit);

  final int limit;

  @override
  String toString() => 'FileTooLargeException($limit)';
}

/// What went wrong, in terms the UI can explain to the user.
enum ChatFailure {
  unreachable,
  connectionLost,
  badCredentials,
  timeout,
  rejected,
  unexpected,

  /// A file over the server's size limit.
  tooLarge;

  static ChatFailure of(Object error) => switch (error) {
    ServerUnreachableException() => unreachable,
    ConnectionLostException() || ConnectionClosedException() => connectionLost,
    FileTooLargeException() || ServerException(code: 413) => tooLarge,
    ServerException(code: 401) => badCredentials,
    ServerException() => rejected,
    RequestTimeoutException() => timeout,
    _ => unexpected,
  };
}
