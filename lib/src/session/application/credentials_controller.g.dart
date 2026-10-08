// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credentials_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The credentials a (re)connect logs in with. After a successful login it
/// holds the session token, so a reconnect never needs the password again.

@ProviderFor(CredentialsController)
final credentialsControllerProvider = CredentialsControllerProvider._();

/// The credentials a (re)connect logs in with. After a successful login it
/// holds the session token, so a reconnect never needs the password again.
final class CredentialsControllerProvider
    extends $NotifierProvider<CredentialsController, TinodeCredentials?> {
  /// The credentials a (re)connect logs in with. After a successful login it
  /// holds the session token, so a reconnect never needs the password again.
  CredentialsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'credentialsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$credentialsControllerHash();

  @$internal
  @override
  CredentialsController create() => CredentialsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TinodeCredentials? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TinodeCredentials?>(value),
    );
  }
}

String _$credentialsControllerHash() =>
    r'a51b14c2f802cadb284354356a37cfa3cc9af575';

/// The credentials a (re)connect logs in with. After a successful login it
/// holds the session token, so a reconnect never needs the password again.

abstract class _$CredentialsController extends $Notifier<TinodeCredentials?> {
  TinodeCredentials? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TinodeCredentials?, TinodeCredentials?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TinodeCredentials?, TinodeCredentials?>,
              TinodeCredentials?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
