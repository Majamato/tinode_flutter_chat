// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The login form's submission: loading while a login runs, an error when
/// it failed. Only the submit button and the error text watch it.

@ProviderFor(LoginController)
final loginControllerProvider = LoginControllerProvider._();

/// The login form's submission: loading while a login runs, an error when
/// it failed. Only the submit button and the error text watch it.
final class LoginControllerProvider
    extends $NotifierProvider<LoginController, AsyncValue<void>> {
  /// The login form's submission: loading while a login runs, an error when
  /// it failed. Only the submit button and the error text watch it.
  LoginControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginControllerHash();

  @$internal
  @override
  LoginController create() => LoginController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$loginControllerHash() => r'ad0247c061feb493dd213acb3868adbe3420fb49';

/// The login form's submission: loading while a login runs, an error when
/// it failed. Only the submit button and the error text watch it.

abstract class _$LoginController extends $Notifier<AsyncValue<void>> {
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

/// The message under the login form: the last submission's error, or why
/// the host's credentials were rejected.

@ProviderFor(loginFailure)
final loginFailureProvider = LoginFailureProvider._();

/// The message under the login form: the last submission's error, or why
/// the host's credentials were rejected.

final class LoginFailureProvider
    extends $FunctionalProvider<ChatFailure?, ChatFailure?, ChatFailure?>
    with $Provider<ChatFailure?> {
  /// The message under the login form: the last submission's error, or why
  /// the host's credentials were rejected.
  LoginFailureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginFailureProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginFailureHash();

  @$internal
  @override
  $ProviderElement<ChatFailure?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatFailure? create(Ref ref) {
    return loginFailure(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatFailure? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatFailure?>(value),
    );
  }
}

String _$loginFailureHash() => r'65ed68acaa021e3d7702a3e96513eab50edb0ec0';
