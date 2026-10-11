import 'dart:async';
import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_inputs.dart';
import 'package:tinode_flutter_chat/src/attachments/data/io_file_store.dart';
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

/// How long logging out waits for the server to drop the push token.
const pushTokenClearTimeout = Duration(seconds: 3);

/// Owns the connection: connects, logs in with the remembered credentials,
/// opens the user's cache and files and closes it all when rebuilt or
/// disposed.
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
    final filesOpener = ref.watch(fileStoreOpenerProvider);
    final open = _open = _OpenSession();
    ref.onDispose(() => unawaited(open.close()));

    final credentials = ref.read(credentialsControllerProvider);
    if (credentials case TokenCredentials(:final token)) {
      if (await _lastUser(opener, config.server) case final userId?) {
        final store = await openOrFallBack(opener, config.server, userId);
        final files = await openFilesOrFallBack(
          filesOpener,
          config.server,
          userId,
        );
        final session = CachedTinodeSession(
          await restore(config, token),
          store,
          userId: userId,
          files: files,
          limits: ref.read(tinodeCacheLimitsProvider),
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
    } on TinodeException catch (e) {
      // A refused login, or an email still to confirm, which only a
      // password login can do: back to the login screen.
      final failure = switch (e) {
        ServerException(code: 401) => ChatFailure.badCredentials,
        CredentialsRequiredException() => ChatFailure.credentialsRequired,
        _ => null,
      };
      if (failure == null) {
        rethrow;
      }
      if (lifetime.isActive) {
        ref.read(credentialsControllerProvider.notifier).forget();
      }
      return SessionAwaitingLogin(session, lastFailure: failure);
    }
  }

  /// Logs in on a session that awaits login; [codes] confirm the user's
  /// email (password logins only). Failures, such as
  /// `CredentialsRequiredException` while the email waits for its code,
  /// are rethrown for the form and leave the state unchanged.
  Future<void> login(
    TinodeCredentials credentials, {
    Map<String, String> codes = const {},
  }) async {
    final current = state.value;
    if (current is! SessionAwaitingLogin) {
      throw StateError('No session is waiting for a login.');
    }
    final lifetime = BuildLifetime(ref);
    final result = await _login(current.session, credentials, codes: codes);
    if (!lifetime.isActive) {
      return;
    }
    final loggedIn = await _loggedIn(current.session, result);
    if (lifetime.isActive) {
      state = AsyncData(loggedIn);
    }
  }

  /// Signs up a new user on a session that awaits login and logs in as
  /// them. Failures are rethrown for the form and leave the state
  /// unchanged. With an [email] the server mails a code and this throws
  /// `CredentialsRequiredException`: [login] with that code finishes.
  Future<void> signUp({
    required String login,
    required String password,
    required String name,
    String? email,
  }) async {
    final current = state.value;
    if (current is! SessionAwaitingLogin) {
      throw StateError('No session is waiting for a login.');
    }
    final lifetime = BuildLifetime(ref);
    final result = await current.session.createAccount(
      login: login,
      password: password,
      public: Profile(name: name),
      email: email,
    );
    if (!lifetime.isActive) {
      return;
    }
    _remember(result);
    final loggedIn = await _loggedIn(current.session, result);
    if (lifetime.isActive) {
      state = AsyncData(loggedIn);
    }
  }

  /// Deletes the user's account on the server, then ends the session as
  /// [logout] does. A failure is rethrown and leaves the session as it was.
  Future<void> deleteAccount() async {
    final current = state.value;
    if (current is! SessionLoggedIn) {
      throw StateError('Nobody is logged in.');
    }
    final open = _open..ending = true;
    try {
      await current.session.deleteAccount();
    } on Object {
      open.ending = false;
      rethrow;
    }
    await _endSession(current.userId);
  }

  /// Closes the current session, if any, and connects again.
  void reconnect() => ref.invalidateSelf();

  /// Ends the session for good: removes the push token from the server,
  /// so the device stops getting the user's pushes, deletes the user's
  /// cache, including what the outbox still held, forgets the credentials
  /// and goes back to the login screen. The host's token stays, for the
  /// next user to log in.
  Future<void> logout() async {
    if (state.value case SessionLoggedIn(:final session, :final userId)) {
      await _clearPushToken(session);
      await _endSession(userId);
    }
  }

  /// Offline, or on a slow link, the logout goes ahead without it.
  static Future<void> _clearPushToken(TinodeSession session) async {
    try {
      await session.setDeviceToken(null).timeout(pushTokenClearTimeout);
    } on Object catch (e, stackTrace) {
      _log('Could not remove the push token', e, stackTrace);
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
    if (_open.ending) {
      // Closed on purpose, on the way back to the login screen.
      return;
    }
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
      case Disconnected(
        cause: ServerException(code: 401 || 404) ||
            CredentialsRequiredException(),
      ):
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

  /// Closes the session, deletes [userId]'s cache and files, and forgets
  /// them.
  Future<void> _endSession(String userId) async {
    final server = ref.read(tinodeConfigProvider).server;
    final opener = ref.read(chatStoreOpenerProvider);
    ref.read(credentialsControllerProvider.notifier).forget();
    _open.ending = true;
    await _open.close();
    await _quietly(() => opener.delete(server, userId));
    await _quietly(
      () => ref.read(fileStoreOpenerProvider).delete(server, userId),
    );
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
    final files = await openFilesOrFallBack(
      ref.read(fileStoreOpenerProvider),
      server,
      login.userId,
    );
    await _quietly(() => opener.rememberUser(server, login.userId));
    final cached = CachedTinodeSession(
      session,
      store,
      userId: login.userId,
      files: files,
      limits: ref.read(tinodeCacheLimitsProvider),
    );
    _open.session = cached;
    return SessionLoggedIn(cached, userId: login.userId, login: login);
  }

  void _remember(LoginResult login) => ref
      .read(credentialsControllerProvider.notifier)
      .remember(TinodeCredentials.token(login.token));

  Future<LoginResult> _login(
    TinodeSession session,
    TinodeCredentials credentials, {
    Map<String, String> codes = const {},
  }) async {
    final result = await switch (credentials) {
      PasswordCredentials(:final login, :final password) => session.loginBasic(
        login,
        password,
        codes: codes,
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

  /// The session is being ended on purpose: its disconnect is expected.
  bool ending = false;

  Future<void> close() async {
    final session = this.session;
    this.session = null;
    await session?.close();
  }
}
