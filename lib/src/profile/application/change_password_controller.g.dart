// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_password_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Changing the password, and maybe the login: loading while it runs, an
/// error when it failed, data once done. Tokens already handed out stay
/// valid, so the session goes on.

@ProviderFor(ChangePasswordController)
final changePasswordControllerProvider = ChangePasswordControllerProvider._();

/// Changing the password, and maybe the login: loading while it runs, an
/// error when it failed, data once done. Tokens already handed out stay
/// valid, so the session goes on.
final class ChangePasswordControllerProvider
    extends $NotifierProvider<ChangePasswordController, AsyncValue<bool>> {
  /// Changing the password, and maybe the login: loading while it runs, an
  /// error when it failed, data once done. Tokens already handed out stay
  /// valid, so the session goes on.
  ChangePasswordControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'changePasswordControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$changePasswordControllerHash();

  @$internal
  @override
  ChangePasswordController create() => ChangePasswordController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<bool>>(value),
    );
  }
}

String _$changePasswordControllerHash() =>
    r'569482bed907549e5e199ae2cfa72b9fe98ade93';

/// Changing the password, and maybe the login: loading while it runs, an
/// error when it failed, data once done. Tokens already handed out stay
/// valid, so the session goes on.

abstract class _$ChangePasswordController extends $Notifier<AsyncValue<bool>> {
  AsyncValue<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, AsyncValue<bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, AsyncValue<bool>>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Why the last change failed, if it did.

@ProviderFor(changePasswordFailure)
final changePasswordFailureProvider = ChangePasswordFailureProvider._();

/// Why the last change failed, if it did.

final class ChangePasswordFailureProvider
    extends $FunctionalProvider<ChatFailure?, ChatFailure?, ChatFailure?>
    with $Provider<ChatFailure?> {
  /// Why the last change failed, if it did.
  ChangePasswordFailureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'changePasswordFailureProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$changePasswordFailureHash();

  @$internal
  @override
  $ProviderElement<ChatFailure?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatFailure? create(Ref ref) {
    return changePasswordFailure(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatFailure? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatFailure?>(value),
    );
  }
}

String _$changePasswordFailureHash() =>
    r'cfbfc26ef03952c729c9bdd846ddb906c1aae064';
