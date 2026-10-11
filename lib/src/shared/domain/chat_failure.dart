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
  tooLarge,

  /// The login is someone else's already.
  loginTaken,

  /// The email belongs to another account already.
  emailTaken,

  /// The email isn't one.
  invalidEmail,

  /// The account's email waits to be confirmed with the mailed code; only
  /// a password login can send it.
  credentialsRequired,

  /// The server's rules refuse the login or password, e.g. too short.
  credentialsRefused,

  /// A password reset code that is wrong or expired.
  wrongCode,

  /// The chat was deleted, or the user is no longer in it.
  gone;

  static ChatFailure of(Object error) => switch (error) {
    ServerUnreachableException() => unreachable,
    ConnectionLostException() || ConnectionClosedException() => connectionLost,
    FileTooLargeException() || ServerException(code: 413) => tooLarge,
    ServerException(code: 401) => badCredentials,
    CredentialsRequiredException() => credentialsRequired,
    ServerException() => rejected,
    RequestTimeoutException() => timeout,
    _ => unexpected,
  };

  /// Like [of], for signing up or changing the login and password. A 409
  /// names the login unless [withEmail] was given too and the server
  /// doesn't say it was the login.
  static ChatFailure ofAccount(Object error, {bool withEmail = false}) =>
      switch (error) {
        ServerException(code: 409, :final params)
            when withEmail && params['what'] != 'auth' =>
          emailTaken,
        ServerException(code: 409) => loginTaken,
        ServerException(code: 400, :final params)
            when params['what'] == 'email' =>
          invalidEmail,
        ServerException(code: 422) => credentialsRefused,
        _ => of(error),
      };
}
