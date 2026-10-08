import 'dart:async';
import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/application/offline_inputs.dart';
import 'package:tinode_flutter_chat/src/offline/data/cached_tinode_session.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/application/credentials_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'session_controller.g.dart';

/// Owns the connection: connects, logs in with the remembered credentials,
/// opens the user's cache and closes it all when rebuilt or disposed.
///
/// With a token for the user who last logged in to this server, it opens
/// that user's cache at once and lets the client connect in the background,
/// so the chats show even offline.
///
/// The client reconnects by itself after a drop, so the state stays
/// logged in meanwhile. Only a final disconnect ends it: a refused token
/// goes back to the login screen, anything else to a
/// [ConnectionLostException] error that [reconnect] starts over from.
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  /// What the current build opened, closed when it is disposed.
  late _OpenSession _open;

  @override
  Future<SessionState> build() async {
    final lifetime = BuildLifetime(ref);
    final config = ref.watch(tinodeConfigProvider);
    final connect = ref.watch(sessionConnectorProvider);
    final restore = ref.watch(sessionRestorerProvider);
    final opener = ref.watch(chatStoreOpenerProvider);
    final open = _open = _OpenSession();
    ref.onDispose(() => unawaited(open.close()));

    final credentials = ref.read(credentialsControllerProvider);
    if (credentials case TokenCredentials(:final token)) {
      if (await _lastUser(opener, config.server) case final userId?) {
        final store = await openOrFallBack(opener, config.server, userId);
        final session = CachedTinodeSession(
          await restore(config, token),
          store,
          userId: userId,
        );
        open.session = session;
        if (lifetime.isActive) {
          _follow(session, lifetime);
        } else {
          await open.close();
        }
        return SessionLoggedIn(session, userId: userId);
      }
    }

    final session = open.session = await connect(config);
    if (!lifetime.isActive) {
      await open.close();
      return SessionAwaitingLogin(session);
    }
    _follow(session, lifetime);
    if (credentials == null) {
      return SessionAwaitingLogin(session);
    }

    try {
      return await _loggedIn(session, await _login(session, credentials));
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
    if (!lifetime.isActive) {
      return;
    }
    final loggedIn = await _loggedIn(current.session, result);
    if (lifetime.isActive) {
      state = AsyncData(loggedIn);
    }
  }

  /// Closes the current session, if any, and connects again.
  void reconnect() => ref.invalidateSelf();

  /// Ends the session for good: deletes the user's cache, including what
  /// the outbox still held, forgets the credentials and goes back to the
  /// login screen.
  Future<void> logout() async {
    if (state.value case SessionLoggedIn(:final userId)) {
      await _endSession(userId);
    }
  }

  void _follow(TinodeSession session, BuildLifetime lifetime) {
    final statuses = session.statusChanges.listen((status) {
      if (lifetime.isActive) {
        _onStatus(status);
      }
    });
    ref.onDispose(() => unawaited(statuses.cancel()));
  }

  void _onStatus(ConnectionStatus status) {
    final current = state.value;
    switch (status) {
      case Connected(login: final login?):
        // The client logged in again by itself, renewing the token.
        _remember(login);
        if (current is! SessionLoggedIn) {
          return;
        }
        if (login.userId != current.userId) {
          // The token is another user's: open their cache instead.
          unawaited(_switchTo(login.userId));
          return;
        }
        state = AsyncData(
          SessionLoggedIn(
            current.session,
            userId: current.userId,
            login: login,
          ),
        );
      case Disconnected(cause: ServerException(code: 404))
          when current is SessionLoggedIn:
        // The user is gone, and so is what was cached for them.
        unawaited(_endSession(current.userId));
      case Disconnected(cause: ServerException(code: 401 || 404)):
        // The token expired: back to the login screen. The cache stays
        // for when the same user logs in again.
        ref.read(credentialsControllerProvider.notifier).forget();
        ref.invalidateSelf();
      case Disconnected():
        state = const AsyncError(ConnectionLostException(), StackTrace.empty);
      case Connected() || Reconnecting() || Suspended():
        break;
    }
  }

  /// Closes the session, deletes [userId]'s cache and forgets them.
  Future<void> _endSession(String userId) async {
    final server = ref.read(tinodeConfigProvider).server;
    final opener = ref.read(chatStoreOpenerProvider);
    ref.read(credentialsControllerProvider.notifier).forget();
    await _open.close();
    await _quietly(() => opener.delete(server, userId));
    await _quietly(() => opener.forgetUser(server));
    ref.invalidateSelf();
  }

  Future<void> _switchTo(String userId) async {
    final server = ref.read(tinodeConfigProvider).server;
    await _quietly(
      () => ref.read(chatStoreOpenerProvider).rememberUser(server, userId),
    );
    ref.invalidateSelf();
  }

  /// Wraps a logged-in [session] with the user's cache.
  Future<SessionLoggedIn> _loggedIn(
    TinodeSession session,
    LoginResult login,
  ) async {
    final server = ref.read(tinodeConfigProvider).server;
    final opener = ref.read(chatStoreOpenerProvider);
    final store = await openOrFallBack(opener, server, login.userId);
    await _quietly(() => opener.rememberUser(server, login.userId));
    final cached = CachedTinodeSession(session, store, userId: login.userId);
    _open.session = cached;
    return SessionLoggedIn(cached, userId: login.userId, login: login);
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

  static Future<String?> _lastUser(ChatStoreOpener opener, Uri server) async {
    try {
      return await opener.lastUser(server);
    } on Object catch (e, stackTrace) {
      _log('Could not read the last user', e, stackTrace);
      return null;
    }
  }

  /// The cache is a convenience: failing to keep it must not end the chat.
  static Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (e, stackTrace) {
      _log('A cache file operation failed', e, stackTrace);
    }
  }

  static void _log(String message, Object error, StackTrace stackTrace) => log(
    message,
    name: 'tinode_flutter_chat',
    error: error,
    stackTrace: stackTrace,
  );
}

/// The outermost session a build opened, so disposing closes it once.
final class _OpenSession {
  TinodeSession? session;

  Future<void> close() async {
    final session = this.session;
    this.session = null;
    await session?.close();
  }
}
