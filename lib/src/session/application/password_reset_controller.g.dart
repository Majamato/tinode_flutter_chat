// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_reset_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A forgotten password, reset from the login screens: [request] emails a
/// code, [reset] sets the new password with it. Neither logs in.

@ProviderFor(PasswordResetController)
final passwordResetControllerProvider = PasswordResetControllerProvider._();

/// A forgotten password, reset from the login screens: [request] emails a
/// code, [reset] sets the new password with it. Neither logs in.
final class PasswordResetControllerProvider
    extends $NotifierProvider<PasswordResetController, PasswordResetState> {
  /// A forgotten password, reset from the login screens: [request] emails a
  /// code, [reset] sets the new password with it. Neither logs in.
  PasswordResetControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordResetControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordResetControllerHash();

  @$internal
  @override
  PasswordResetController create() => PasswordResetController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PasswordResetState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PasswordResetState>(value),
    );
  }
}

String _$passwordResetControllerHash() =>
    r'118b255a350964d576c122ef14ef70c3334c3ae9';

/// A forgotten password, reset from the login screens: [request] emails a
/// code, [reset] sets the new password with it. Neither logs in.

abstract class _$PasswordResetController extends $Notifier<PasswordResetState> {
  PasswordResetState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PasswordResetState, PasswordResetState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PasswordResetState, PasswordResetState>,
              PasswordResetState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
