// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_group_photo_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The photo picked for a new group, from [AttachmentSource.gallery] or
/// the camera: loading while it is read, an error when picking failed.
/// Nothing is uploaded until the group is created.

@ProviderFor(NewGroupPhotoController)
final newGroupPhotoControllerProvider = NewGroupPhotoControllerProvider._();

/// The photo picked for a new group, from [AttachmentSource.gallery] or
/// the camera: loading while it is read, an error when picking failed.
/// Nothing is uploaded until the group is created.
final class NewGroupPhotoControllerProvider
    extends
        $NotifierProvider<NewGroupPhotoController, AsyncValue<GroupPhoto?>> {
  /// The photo picked for a new group, from [AttachmentSource.gallery] or
  /// the camera: loading while it is read, an error when picking failed.
  /// Nothing is uploaded until the group is created.
  NewGroupPhotoControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newGroupPhotoControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newGroupPhotoControllerHash();

  @$internal
  @override
  NewGroupPhotoController create() => NewGroupPhotoController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<GroupPhoto?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<GroupPhoto?>>(value),
    );
  }
}

String _$newGroupPhotoControllerHash() =>
    r'5c5007fa8fd58f1a60f325cae3fc61773aedb8f1';

/// The photo picked for a new group, from [AttachmentSource.gallery] or
/// the camera: loading while it is read, an error when picking failed.
/// Nothing is uploaded until the group is created.

abstract class _$NewGroupPhotoController
    extends $Notifier<AsyncValue<GroupPhoto?>> {
  AsyncValue<GroupPhoto?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<GroupPhoto?>, AsyncValue<GroupPhoto?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GroupPhoto?>, AsyncValue<GroupPhoto?>>,
              AsyncValue<GroupPhoto?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
