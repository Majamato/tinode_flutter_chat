// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_registration.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Hands the host's push token to each logged-in session, and every change
/// of it. The client sends it again after each reconnect, and after an
/// offline start once the server answers.
///
/// Logging out removes it from the server first: see
/// `SessionController.logout`.

@ProviderFor(PushRegistration)
final pushRegistrationProvider = PushRegistrationProvider._();

/// Hands the host's push token to each logged-in session, and every change
/// of it. The client sends it again after each reconnect, and after an
/// offline start once the server answers.
///
/// Logging out removes it from the server first: see
/// `SessionController.logout`.
final class PushRegistrationProvider
    extends $NotifierProvider<PushRegistration, void> {
  /// Hands the host's push token to each logged-in session, and every change
  /// of it. The client sends it again after each reconnect, and after an
  /// offline start once the server answers.
  ///
  /// Logging out removes it from the server first: see
  /// `SessionController.logout`.
  PushRegistrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushRegistrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushRegistrationHash();

  @$internal
  @override
  PushRegistration create() => PushRegistration();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$pushRegistrationHash() => r'52b6cfa9f3ed6bba06660293975af4c2321b4dfb';

/// Hands the host's push token to each logged-in session, and every change
/// of it. The client sends it again after each reconnect, and after an
/// offline start once the server answers.
///
/// Logging out removes it from the server first: see
/// `SessionController.logout`.

abstract class _$PushRegistration extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
