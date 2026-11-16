// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_inputs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where the app's session takes the pushes of the push service's
/// background isolate (`PushRelay`); `TinodeChat` overrides it with the
/// process's `IsolateNameServer`.

@ProviderFor(pushPortNames)
final pushPortNamesProvider = PushPortNamesProvider._();

/// Where the app's session takes the pushes of the push service's
/// background isolate (`PushRelay`); `TinodeChat` overrides it with the
/// process's `IsolateNameServer`.

final class PushPortNamesProvider
    extends $FunctionalProvider<PortNames, PortNames, PortNames>
    with $Provider<PortNames> {
  /// Where the app's session takes the pushes of the push service's
  /// background isolate (`PushRelay`); `TinodeChat` overrides it with the
  /// process's `IsolateNameServer`.
  PushPortNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushPortNamesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushPortNamesHash();

  @$internal
  @override
  $ProviderElement<PortNames> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PortNames create(Ref ref) {
    return pushPortNames(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PortNames value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PortNames>(value),
    );
  }
}

String _$pushPortNamesHash() => r'5bbd4062b325e22f8220aca8880665e3acccdae2';
