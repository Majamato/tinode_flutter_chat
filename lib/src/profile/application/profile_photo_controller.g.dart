// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_photo_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A new profile photo: picked from [AttachmentSource.gallery] or the
/// camera, uploaded, then set in the profile by ref. Loading while it runs,
/// an error when it failed. Only the photo button watches it.

@ProviderFor(ProfilePhotoController)
final profilePhotoControllerProvider = ProfilePhotoControllerProvider._();

/// A new profile photo: picked from [AttachmentSource.gallery] or the
/// camera, uploaded, then set in the profile by ref. Loading while it runs,
/// an error when it failed. Only the photo button watches it.
final class ProfilePhotoControllerProvider
    extends $NotifierProvider<ProfilePhotoController, AsyncValue<void>> {
  /// A new profile photo: picked from [AttachmentSource.gallery] or the
  /// camera, uploaded, then set in the profile by ref. Loading while it runs,
  /// an error when it failed. Only the photo button watches it.
  ProfilePhotoControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profilePhotoControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profilePhotoControllerHash();

  @$internal
  @override
  ProfilePhotoController create() => ProfilePhotoController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$profilePhotoControllerHash() =>
    r'4375d26bf6ad88656fa6ca612bee1bb939451231';

/// A new profile photo: picked from [AttachmentSource.gallery] or the
/// camera, uploaded, then set in the profile by ref. Loading while it runs,
/// an error when it failed. Only the photo button watches it.

abstract class _$ProfilePhotoController extends $Notifier<AsyncValue<void>> {
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

/// Why the last photo change failed, if it did.

@ProviderFor(profilePhotoFailure)
final profilePhotoFailureProvider = ProfilePhotoFailureProvider._();

/// Why the last photo change failed, if it did.

final class ProfilePhotoFailureProvider
    extends $FunctionalProvider<ChatFailure?, ChatFailure?, ChatFailure?>
    with $Provider<ChatFailure?> {
  /// Why the last photo change failed, if it did.
  ProfilePhotoFailureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profilePhotoFailureProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profilePhotoFailureHash();

  @$internal
  @override
  $ProviderElement<ChatFailure?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatFailure? create(Ref ref) {
    return profilePhotoFailure(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatFailure? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatFailure?>(value),
    );
  }
}

String _$profilePhotoFailureHash() =>
    r'52ccbc089462564073165629b2d80cd462530fb2';
