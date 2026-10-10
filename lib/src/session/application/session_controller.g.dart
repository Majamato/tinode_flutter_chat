// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(SessionController)
final sessionControllerProvider = SessionControllerProvider._();

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
final class SessionControllerProvider
    extends $AsyncNotifierProvider<SessionController, SessionState> {
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
  SessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionControllerHash();

  @$internal
  @override
  SessionController create() => SessionController();
}

String _$sessionControllerHash() => r'e1f6594e3e4b45ae8bee8335bf0b2fbab1b5e405';

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

abstract class _$SessionController extends $AsyncNotifier<SessionState> {
  FutureOr<SessionState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SessionState>, SessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SessionState>, SessionState>,
              AsyncValue<SessionState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
