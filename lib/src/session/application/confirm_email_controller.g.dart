// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirm_email_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Confirming the user's email with the code the server mailed, by logging
/// in with it: loading while it runs, an error when it failed. Success
/// logs in, which leaves the login screens.

@ProviderFor(ConfirmEmailController)
final confirmEmailControllerProvider = ConfirmEmailControllerProvider._();

/// Confirming the user's email with the code the server mailed, by logging
/// in with it: loading while it runs, an error when it failed. Success
/// logs in, which leaves the login screens.
final class ConfirmEmailControllerProvider
    extends $NotifierProvider<ConfirmEmailController, AsyncValue<void>> {
  /// Confirming the user's email with the code the server mailed, by logging
  /// in with it: loading while it runs, an error when it failed. Success
  /// logs in, which leaves the login screens.
  ConfirmEmailControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'confirmEmailControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$confirmEmailControllerHash();

  @$internal
  @override
  ConfirmEmailController create() => ConfirmEmailController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$confirmEmailControllerHash() =>
    r'90733d962b2c584b7b640d87e46d7fb093223c03';

/// Confirming the user's email with the code the server mailed, by logging
/// in with it: loading while it runs, an error when it failed. Success
/// logs in, which leaves the login screens.

abstract class _$ConfirmEmailController extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Why the last confirmation failed, if it did; the server answers a wrong
/// code by asking for one again.

@ProviderFor(confirmEmailFailure)
final confirmEmailFailureProvider = ConfirmEmailFailureProvider._();

/// Why the last confirmation failed, if it did; the server answers a wrong
/// code by asking for one again.

final class ConfirmEmailFailureProvider
    extends $FunctionalProvider<ChatFailure?, ChatFailure?, ChatFailure?>
    with $Provider<ChatFailure?> {
  /// Why the last confirmation failed, if it did; the server answers a wrong
  /// code by asking for one again.
  ConfirmEmailFailureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'confirmEmailFailureProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$confirmEmailFailureHash();

  @$internal
  @override
  $ProviderElement<ChatFailure?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatFailure? create(Ref ref) {
    return confirmEmailFailure(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatFailure? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatFailure?>(value),
    );
  }
}

String _$confirmEmailFailureHash() =>
    r'd53dfcfc76de6c0dbf26c8a936efec2849fec20e';
