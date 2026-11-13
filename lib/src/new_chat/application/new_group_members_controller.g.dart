// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_group_members_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The people picked for a new group, shared by its two screens: picked on
/// the add members screen, and removable on both. Lives while the add
/// members screen does.

@ProviderFor(NewGroupMembersController)
final newGroupMembersControllerProvider = NewGroupMembersControllerProvider._();

/// The people picked for a new group, shared by its two screens: picked on
/// the add members screen, and removable on both. Lives while the add
/// members screen does.
final class NewGroupMembersControllerProvider
    extends $NotifierProvider<NewGroupMembersController, PickedMembers> {
  /// The people picked for a new group, shared by its two screens: picked on
  /// the add members screen, and removable on both. Lives while the add
  /// members screen does.
  NewGroupMembersControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newGroupMembersControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newGroupMembersControllerHash();

  @$internal
  @override
  NewGroupMembersController create() => NewGroupMembersController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PickedMembers value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PickedMembers>(value),
    );
  }
}

String _$newGroupMembersControllerHash() =>
    r'd287147197761fffa88bd502a04780c0d7dfd470';

/// The people picked for a new group, shared by its two screens: picked on
/// the add members screen, and removable on both. Lives while the add
/// members screen does.

abstract class _$NewGroupMembersController extends $Notifier<PickedMembers> {
  PickedMembers build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PickedMembers, PickedMembers>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PickedMembers, PickedMembers>,
              PickedMembers,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
