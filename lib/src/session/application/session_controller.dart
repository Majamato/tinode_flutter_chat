import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/application/credentials_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'session_controller.g.dart';

/// Owns the connection: connects, logs in with the remembered credentials
/// and closes the session when rebuilt or disposed.
///
/// The client reconnects by itself after a drop, so the state stays
/// logged in meanwhile. Only a final disconnect ends it: a refused token
/// goes back to the login screen, anything else to a
/// [ConnectionLostException] error that [reconnect] starts over from.
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  @override
  Future<SessionState> build() async {
    final lifetime = BuildLifetime(ref);
    final config = ref.watch(tinodeConfigProvider);
    final connect = ref.watch(sessionConnectorProvider);

    final session = await connect(config);
    if (!lifetime.isActive) {
      await session.close();
      return SessionAwaitingLogin(session);
    }
    final statuses = session.statusChanges.listen((status) {
      if (lifetime.isActive) {
        _onStatus(session, status);
      }
    });
    ref.onDispose(() {
      unawaited(statuses.cancel());
      unawaited(session.close());
    });

    final credentials = ref.read(credentialsControllerProvider);
    if (credentials == null) {
      return SessionAwaitingLogin(session);
    }

    try {
      return SessionLoggedIn(session, await _login(session, credentials));
    } on ServerException catch (e) {
      if (e.code != 401) {
        rethrow;
      }
      if (lifetime.isActive) {
        ref.read(credentialsControllerProvider.notifier).forget();
      }
      return SessionAwaitingLogin(
        session,
        lastFailure: ChatFailure.badCredentials,
      );
    }
  }

  /// Logs in on a session that awaits login. Failures are rethrown for the
  /// login form and leave the state unchanged.
  Future<void> login(TinodeCredentials credentials) async {
    final current = state.value;
    if (current is! SessionAwaitingLogin) {
      throw StateError('No session is waiting for a login.');
    }
    final lifetime = BuildLifetime(ref);
    final result = await _login(current.session, credentials);
    if (lifetime.isActive) {
      state = AsyncData(SessionLoggedIn(current.session, result));
    }
  }

  /// Closes the current session, if any, and connects again.
  void reconnect() => ref.invalidateSelf();

  void _onStatus(TinodeSession session, ConnectionStatus status) {
    switch (status) {
      case Connected(login: final login?):
        // The client logged in again by itself, renewing the token.
        _remember(login);
        if (state.value is SessionLoggedIn) {
          state = AsyncData(SessionLoggedIn(session, login));
        }
      case Disconnected(cause: ServerException(code: 401 || 404)):
        // The token expired or the user is gone: back to the login screen.
        ref.read(credentialsControllerProvider.notifier).forget();
        ref.invalidateSelf();
      case Disconnected():
        state = const AsyncError(ConnectionLostException(), StackTrace.empty);
      case Connected() || Reconnecting() || Suspended():
        break;
    }
  }

  void _remember(LoginResult login) => ref
      .read(credentialsControllerProvider.notifier)
      .remember(TinodeCredentials.token(login.token));

  Future<LoginResult> _login(
    TinodeSession session,
    TinodeCredentials credentials,
  ) async {
    final result = await switch (credentials) {
      PasswordCredentials(:final login, :final password) => session.loginBasic(
        login,
        password,
      ),
      TokenCredentials(:final token) => session.loginToken(token),
    };
    if (ref.mounted) {
      _remember(result);
    }
    return result;
  }
}
