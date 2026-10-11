// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's own profile, read from the server while the profile screen
/// is open. It needs the link: offline it fails with a lost connection.

@ProviderFor(ProfileController)
final profileControllerProvider = ProfileControllerProvider._();

/// The user's own profile, read from the server while the profile screen
/// is open. It needs the link: offline it fails with a lost connection.
final class ProfileControllerProvider
    extends $AsyncNotifierProvider<ProfileController, MyProfile> {
  /// The user's own profile, read from the server while the profile screen
  /// is open. It needs the link: offline it fails with a lost connection.
  ProfileControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileControllerHash();

  @$internal
  @override
  ProfileController create() => ProfileController();
}

String _$profileControllerHash() => r'6711b99906390d734e1a6e62df75d77cd5971742';

/// The user's own profile, read from the server while the profile screen
/// is open. It needs the link: offline it fails with a lost connection.

abstract class _$ProfileController extends $AsyncNotifier<MyProfile> {
  FutureOr<MyProfile> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MyProfile>, MyProfile>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MyProfile>, MyProfile>,
              AsyncValue<MyProfile>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
