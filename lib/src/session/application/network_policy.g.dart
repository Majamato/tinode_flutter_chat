// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_policy.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Turns the OS's network changes into checks of the link. Only a hint:
/// the socket's own status decides what the user sees.

@ProviderFor(NetworkPolicy)
final networkPolicyProvider = NetworkPolicyProvider._();

/// Turns the OS's network changes into checks of the link. Only a hint:
/// the socket's own status decides what the user sees.
final class NetworkPolicyProvider
    extends $NotifierProvider<NetworkPolicy, void> {
  /// Turns the OS's network changes into checks of the link. Only a hint:
  /// the socket's own status decides what the user sees.
  NetworkPolicyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkPolicyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkPolicyHash();

  @$internal
  @override
  NetworkPolicy create() => NetworkPolicy();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$networkPolicyHash() => r'b5d169f26847a48a257f516044b6e8d4f9007ed2';

/// Turns the OS's network changes into checks of the link. Only a hint:
/// the socket's own status decides what the user sees.

abstract class _$NetworkPolicy extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
