import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// A connected session, before or after login. While connecting, or after
/// the connection failed, `SessionController` is loading or in error.
///
/// It lives in the application layer because it carries the data-layer
/// [session]; widgets never touch that field.
sealed class SessionState with ValueObject {
  const SessionState(this.session);

  final TinodeSession session;
}

final class SessionAwaitingLogin extends SessionState {
  const SessionAwaitingLogin(super.session, {this.lastFailure});

  /// Why the automatic login with the host's credentials failed.
  final ChatFailure? lastFailure;

  @override
  List<Object?> get props => [session, lastFailure];
}

final class SessionLoggedIn extends SessionState {
  const SessionLoggedIn(super.session, this.login);

  final LoginResult login;

  @override
  List<Object?> get props => [session, login];
}

/// The screen the session gate shows.
enum SessionPhase {
  connecting,
  awaitingLogin,
  loggedIn,
  failed;

  /// Loading wins over a previous value or error, so a reconnect shows
  /// progress instead of the stale screen.
  static SessionPhase of(AsyncValue<SessionState> session) => switch (session) {
    AsyncValue(isLoading: true) => connecting,
    AsyncValue(hasError: true) => failed,
    AsyncValue(value: SessionLoggedIn()) => loggedIn,
    AsyncValue(value: SessionAwaitingLogin()) => awaitingLogin,
    AsyncValue() => connecting,
  };
}
