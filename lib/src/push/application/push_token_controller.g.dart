// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_token_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The host's push token for this device, e.g. from Firebase Cloud
/// Messaging; null while it has none. `PushRegistration` sends it to the
/// server.

@ProviderFor(PushTokenController)
final pushTokenControllerProvider = PushTokenControllerProvider._();

/// The host's push token for this device, e.g. from Firebase Cloud
/// Messaging; null while it has none. `PushRegistration` sends it to the
/// server.
final class PushTokenControllerProvider
    extends $NotifierProvider<PushTokenController, String?> {
  /// The host's push token for this device, e.g. from Firebase Cloud
  /// Messaging; null while it has none. `PushRegistration` sends it to the
  /// server.
  PushTokenControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushTokenControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushTokenControllerHash();

  @$internal
  @override
  PushTokenController create() => PushTokenController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$pushTokenControllerHash() =>
    r'6e985ba6c539dd5fa87127a0485de7351ddd13f9';

/// The host's push token for this device, e.g. from Firebase Cloud
/// Messaging; null while it has none. `PushRegistration` sends it to the
/// server.

abstract class _$PushTokenController extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
