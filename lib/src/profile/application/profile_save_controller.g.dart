// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_save_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Saving the profile's name and note: loading while it runs, an error
/// when it failed. Only the save button and the error text watch it.

@ProviderFor(ProfileSaveController)
final profileSaveControllerProvider = ProfileSaveControllerProvider._();

/// Saving the profile's name and note: loading while it runs, an error
/// when it failed. Only the save button and the error text watch it.
final class ProfileSaveControllerProvider
    extends $NotifierProvider<ProfileSaveController, AsyncValue<void>> {
  /// Saving the profile's name and note: loading while it runs, an error
  /// when it failed. Only the save button and the error text watch it.
  ProfileSaveControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileSaveControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileSaveControllerHash();

  @$internal
  @override
  ProfileSaveController create() => ProfileSaveController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$profileSaveControllerHash() =>
    r'b79b1b96964686174f22c1adccf18cbd17d0bb6c';

/// Saving the profile's name and note: loading while it runs, an error
/// when it failed. Only the save button and the error text watch it.

abstract class _$ProfileSaveController extends $Notifier<AsyncValue<void>> {
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

/// Why saving the profile or its photo failed, if it did.

@ProviderFor(profileSaveFailure)
final profileSaveFailureProvider = ProfileSaveFailureProvider._();

/// Why saving the profile or its photo failed, if it did.

final class ProfileSaveFailureProvider
    extends $FunctionalProvider<ChatFailure?, ChatFailure?, ChatFailure?>
    with $Provider<ChatFailure?> {
  /// Why saving the profile or its photo failed, if it did.
  ProfileSaveFailureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileSaveFailureProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileSaveFailureHash();

  @$internal
  @override
  $ProviderElement<ChatFailure?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatFailure? create(Ref ref) {
    return profileSaveFailure(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatFailure? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatFailure?>(value),
    );
  }
}

String _$profileSaveFailureHash() =>
    r'95df018647f95071200ef0a9473150e1cfbed687';
