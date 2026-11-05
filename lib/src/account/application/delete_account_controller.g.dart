// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_account_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Deleting the user's account: loading while it runs, an error when it
/// failed. Success ends the session, which shows the login screen.

@ProviderFor(DeleteAccountController)
final deleteAccountControllerProvider = DeleteAccountControllerProvider._();

/// Deleting the user's account: loading while it runs, an error when it
/// failed. Success ends the session, which shows the login screen.
final class DeleteAccountControllerProvider
    extends $NotifierProvider<DeleteAccountController, AsyncValue<void>> {
  /// Deleting the user's account: loading while it runs, an error when it
  /// failed. Success ends the session, which shows the login screen.
  DeleteAccountControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteAccountControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteAccountControllerHash();

  @$internal
  @override
  DeleteAccountController create() => DeleteAccountController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$deleteAccountControllerHash() =>
    r'32826d50d9fdb1447ac93c9e71e0badcf365bb7f';

/// Deleting the user's account: loading while it runs, an error when it
/// failed. Success ends the session, which shows the login screen.

abstract class _$DeleteAccountController extends $Notifier<AsyncValue<void>> {
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

/// Why deleting the account failed, if it did.

@ProviderFor(deleteAccountFailure)
final deleteAccountFailureProvider = DeleteAccountFailureProvider._();

/// Why deleting the account failed, if it did.

final class DeleteAccountFailureProvider
    extends $FunctionalProvider<ChatFailure?, ChatFailure?, ChatFailure?>
    with $Provider<ChatFailure?> {
  /// Why deleting the account failed, if it did.
  DeleteAccountFailureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteAccountFailureProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteAccountFailureHash();

  @$internal
  @override
  $ProviderElement<ChatFailure?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatFailure? create(Ref ref) {
    return deleteAccountFailure(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatFailure? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatFailure?>(value),
    );
  }
}

String _$deleteAccountFailureHash() =>
    r'8e5aaabab8e162bfd5eded49a472e5bbf386384e';
