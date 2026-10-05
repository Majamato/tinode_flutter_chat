import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// How `TinodeChat` logs in once connected.
sealed class TinodeCredentials with ValueObject {
  const TinodeCredentials();

  /// Logs in with a login name and password (Tinode's `basic` scheme).
  const factory TinodeCredentials.password(String login, String password) =
      PasswordCredentials;

  /// Logs in with a token from an earlier login, see `LoginResult.token`.
  const factory TinodeCredentials.token(String token) = TokenCredentials;
}

/// A login name and password.
final class PasswordCredentials extends TinodeCredentials {
  const PasswordCredentials(this.login, this.password);

  /// The user's login name, e.g. `alice`.
  final String login;

  /// The user's password.
  final String password;

  @override
  List<Object?> get props => [login, password];

  @override
  String toString() => 'PasswordCredentials($login, ***)';
}

/// A token returned by an earlier login.
final class TokenCredentials extends TinodeCredentials {
  /// Credentials for the `token` login scheme.
  const TokenCredentials(this.token);

  /// The token, valid until `LoginResult.expires`.
  final String token;

  @override
  List<Object?> get props => [token];

  @override
  String toString() => 'TokenCredentials(***)';
}
