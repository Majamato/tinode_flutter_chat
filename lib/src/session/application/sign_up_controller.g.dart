// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_up_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The sign-up form's submission: loading while it runs, an error when it
/// failed. Success logs the new user in, which leaves the login screens.

@ProviderFor(SignUpController)
final signUpControllerProvider = SignUpControllerProvider._();

/// The sign-up form's submission: loading while it runs, an error when it
/// failed. Success logs the new user in, which leaves the login screens.
final class SignUpControllerProvider
    extends $NotifierProvider<SignUpController, AsyncValue<void>> {
  /// The sign-up form's submission: loading while it runs, an error when it
  /// failed. Success logs the new user in, which leaves the login screens.
  SignUpControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpControllerHash();

  @$internal
  @override
  SignUpController create() => SignUpController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$signUpControllerHash() => r'34174a8386b064c4dc0f9568c77415c8ee779cf6';

/// The sign-up form's submission: loading while it runs, an error when it
/// failed. Success logs the new user in, which leaves the login screens.

abstract class _$SignUpController extends $Notifier<AsyncValue<void>> {
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

/// Why the last sign-up failed, if it did. The server marks a taken login
/// (`what: auth`), so another 409 is the email.

@ProviderFor(signUpFailure)
final signUpFailureProvider = SignUpFailureProvider._();

/// Why the last sign-up failed, if it did. The server marks a taken login
/// (`what: auth`), so another 409 is the email.

final class SignUpFailureProvider
    extends $FunctionalProvider<ChatFailure?, ChatFailure?, ChatFailure?>
    with $Provider<ChatFailure?> {
  /// Why the last sign-up failed, if it did. The server marks a taken login
  /// (`what: auth`), so another 409 is the email.
  SignUpFailureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpFailureProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpFailureHash();

  @$internal
  @override
  $ProviderElement<ChatFailure?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatFailure? create(Ref ref) {
    return signUpFailure(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatFailure? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatFailure?>(value),
    );
  }
}

String _$signUpFailureHash() => r'4434a8e9609dff13ffb5c401c7bcdcef1bdec3a5';

/// Whether the login screen offers to sign up, as the host chose.

@ProviderFor(signUpOffered)
final signUpOfferedProvider = SignUpOfferedProvider._();

/// Whether the login screen offers to sign up, as the host chose.

final class SignUpOfferedProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the login screen offers to sign up, as the host chose.
  SignUpOfferedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpOfferedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpOfferedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return signUpOffered(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$signUpOfferedHash() => r'600965131ab59738de7a780f278f79953a84efd8';

/// Whether the login screen offers to reset a forgotten password: as the
/// host chose, by default where the server requires an email, since it
/// then sends email.

@ProviderFor(passwordResetOffered)
final passwordResetOfferedProvider = PasswordResetOfferedProvider._();

/// Whether the login screen offers to reset a forgotten password: as the
/// host chose, by default where the server requires an email, since it
/// then sends email.

final class PasswordResetOfferedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the login screen offers to reset a forgotten password: as the
  /// host chose, by default where the server requires an email, since it
  /// then sends email.
  PasswordResetOfferedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordResetOfferedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordResetOfferedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return passwordResetOffered(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$passwordResetOfferedHash() =>
    r'0a16b95950661eae54a79f784babd6c1fedcbaf5';

/// Whether the server wants an email at sign-up, which it then has the
/// user confirm with a mailed code.

@ProviderFor(signUpNeedsEmail)
final signUpNeedsEmailProvider = SignUpNeedsEmailProvider._();

/// Whether the server wants an email at sign-up, which it then has the
/// user confirm with a mailed code.

final class SignUpNeedsEmailProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the server wants an email at sign-up, which it then has the
  /// user confirm with a mailed code.
  SignUpNeedsEmailProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpNeedsEmailProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpNeedsEmailHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return signUpNeedsEmail(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$signUpNeedsEmailHash() => r'e5ecd6bee6acb11739222a4341f7cdbf772b920e';
