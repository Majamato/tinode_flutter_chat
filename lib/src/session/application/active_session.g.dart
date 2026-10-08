// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The logged-in session; null while logged out or disconnected.
///
/// Chat screens can outlive the session for a frame or a route transition,
/// so dependents treat null as a lost connection instead of throwing.

@ProviderFor(activeSession)
final activeSessionProvider = ActiveSessionProvider._();

/// The logged-in session; null while logged out or disconnected.
///
/// Chat screens can outlive the session for a frame or a route transition,
/// so dependents treat null as a lost connection instead of throwing.

final class ActiveSessionProvider
    extends $FunctionalProvider<ChatSession?, ChatSession?, ChatSession?>
    with $Provider<ChatSession?> {
  /// The logged-in session; null while logged out or disconnected.
  ///
  /// Chat screens can outlive the session for a frame or a route transition,
  /// so dependents treat null as a lost connection instead of throwing.
  ActiveSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeSessionHash();

  @$internal
  @override
  $ProviderElement<ChatSession?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatSession? create(Ref ref) {
    return activeSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatSession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatSession?>(value),
    );
  }
}

String _$activeSessionHash() => r'1172cfa0981bcb3778940d3ed0735ad0f375139d';

/// The logged-in user's ID, e.g. `usrAbC123`; null while logged out.

@ProviderFor(currentUserId)
final currentUserIdProvider = CurrentUserIdProvider._();

/// The logged-in user's ID, e.g. `usrAbC123`; null while logged out.

final class CurrentUserIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The logged-in user's ID, e.g. `usrAbC123`; null while logged out.
  CurrentUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return currentUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentUserIdHash() => r'23d3b427973b1b9853b53eca8ed355edd6448f6b';

/// The latest login; null while logged out, and after an offline start
/// until the server answers.

@ProviderFor(currentLogin)
final currentLoginProvider = CurrentLoginProvider._();

/// The latest login; null while logged out, and after an offline start
/// until the server answers.

final class CurrentLoginProvider
    extends $FunctionalProvider<LoginResult?, LoginResult?, LoginResult?>
    with $Provider<LoginResult?> {
  /// The latest login; null while logged out, and after an offline start
  /// until the server answers.
  CurrentLoginProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentLoginProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentLoginHash();

  @$internal
  @override
  $ProviderElement<LoginResult?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoginResult? create(Ref ref) {
    return currentLogin(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoginResult? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoginResult?>(value),
    );
  }
}

String _$currentLoginHash() => r'2aed4a3ebdcc101a0bb6ba12b27cfe056339cfa5';

/// Why the session could not connect or stay connected, if it failed.

@ProviderFor(sessionFailure)
final sessionFailureProvider = SessionFailureProvider._();

/// Why the session could not connect or stay connected, if it failed.

final class SessionFailureProvider
    extends $FunctionalProvider<ChatFailure?, ChatFailure?, ChatFailure?>
    with $Provider<ChatFailure?> {
  /// Why the session could not connect or stay connected, if it failed.
  SessionFailureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionFailureProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionFailureHash();

  @$internal
  @override
  $ProviderElement<ChatFailure?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatFailure? create(Ref ref) {
    return sessionFailure(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatFailure? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatFailure?>(value),
    );
  }
}

String _$sessionFailureHash() => r'3c76c078a618db81d889e8a511ec5b333e050c29';
