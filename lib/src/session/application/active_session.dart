import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'active_session.g.dart';

/// The logged-in session; null while logged out or disconnected.
///
/// Chat screens can outlive the session for a frame or a route transition,
/// so dependents treat null as a lost connection instead of throwing.
@Riverpod(keepAlive: true)
TinodeSession? activeSession(Ref ref) =>
    ref.watch(sessionControllerProvider.select(_loggedIn))?.session;

/// The logged-in user's ID, e.g. `usrAbC123`; null while logged out.
@Riverpod(keepAlive: true)
String? currentUserId(Ref ref) =>
    ref.watch(sessionControllerProvider.select(_loggedIn))?.login.userId;

/// Why the session could not connect or stay connected, if it failed.
@Riverpod(keepAlive: true)
ChatFailure? sessionFailure(Ref ref) => ref.watch(
  sessionControllerProvider.select(
    (s) => s.hasError && !s.isLoading ? ChatFailure.of(s.error!) : null,
  ),
);

SessionLoggedIn? _loggedIn(AsyncValue<SessionState> session) =>
    switch (session) {
      AsyncData(value: final SessionLoggedIn loggedIn) => loggedIn,
      _ => null,
    };
