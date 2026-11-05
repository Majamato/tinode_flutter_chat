// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presence_visibility_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether others see when the user is online and was last seen: "Show my
/// online status". Saved in the user's profile (see `PresenceVisibility`),
/// so it follows them to every device. Loading while it saves, an error
/// when that failed.

@ProviderFor(PresenceVisibilityController)
final presenceVisibilityControllerProvider =
    PresenceVisibilityControllerProvider._();

/// Whether others see when the user is online and was last seen: "Show my
/// online status". Saved in the user's profile (see `PresenceVisibility`),
/// so it follows them to every device. Loading while it saves, an error
/// when that failed.
final class PresenceVisibilityControllerProvider
    extends $NotifierProvider<PresenceVisibilityController, AsyncValue<void>> {
  /// Whether others see when the user is online and was last seen: "Show my
  /// online status". Saved in the user's profile (see `PresenceVisibility`),
  /// so it follows them to every device. Loading while it saves, an error
  /// when that failed.
  PresenceVisibilityControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'presenceVisibilityControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$presenceVisibilityControllerHash();

  @$internal
  @override
  PresenceVisibilityController create() => PresenceVisibilityController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$presenceVisibilityControllerHash() =>
    r'2c1395fcb63f323b3fd095b66574f45e9e05c844';

/// Whether others see when the user is online and was last seen: "Show my
/// online status". Saved in the user's profile (see `PresenceVisibility`),
/// so it follows them to every device. Loading while it saves, an error
/// when that failed.

abstract class _$PresenceVisibilityController
    extends $Notifier<AsyncValue<void>> {
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

/// Whether others see the user's presence, from their profile; null while
/// it can't be read, e.g. offline.

@ProviderFor(myPresenceShown)
final myPresenceShownProvider = MyPresenceShownProvider._();

/// Whether others see the user's presence, from their profile; null while
/// it can't be read, e.g. offline.

final class MyPresenceShownProvider
    extends $FunctionalProvider<bool?, bool?, bool?>
    with $Provider<bool?> {
  /// Whether others see the user's presence, from their profile; null while
  /// it can't be read, e.g. offline.
  MyPresenceShownProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPresenceShownProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPresenceShownHash();

  @$internal
  @override
  $ProviderElement<bool?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool? create(Ref ref) {
    return myPresenceShown(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool?>(value),
    );
  }
}

String _$myPresenceShownHash() => r'81735f77eb3d361c37f363300b10cb2773f2b721';
