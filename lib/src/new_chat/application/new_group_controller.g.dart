// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_group_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Creating a group: loading while the server creates it and adds its
/// members, an error when the group could not be created. Only the new
/// group screen and its create button watch it.

@ProviderFor(NewGroupController)
final newGroupControllerProvider = NewGroupControllerProvider._();

/// Creating a group: loading while the server creates it and adds its
/// members, an error when the group could not be created. Only the new
/// group screen and its create button watch it.
final class NewGroupControllerProvider
    extends $NotifierProvider<NewGroupController, AsyncValue<void>> {
  /// Creating a group: loading while the server creates it and adds its
  /// members, an error when the group could not be created. Only the new
  /// group screen and its create button watch it.
  NewGroupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newGroupControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newGroupControllerHash();

  @$internal
  @override
  NewGroupController create() => NewGroupController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$newGroupControllerHash() =>
    r'a9c58a5261bffcec9ce6b4deef944e9cbf67533d';

/// Creating a group: loading while the server creates it and adds its
/// members, an error when the group could not be created. Only the new
/// group screen and its create button watch it.

abstract class _$NewGroupController extends $Notifier<AsyncValue<void>> {
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
