// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_inputs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How a call gets its audio, video and WebRTC link; tests override it
/// with a fake.

@ProviderFor(callMediaFactory)
final callMediaFactoryProvider = CallMediaFactoryProvider._();

/// How a call gets its audio, video and WebRTC link; tests override it
/// with a fake.

final class CallMediaFactoryProvider
    extends
        $FunctionalProvider<
          CallMediaFactory,
          CallMediaFactory,
          CallMediaFactory
        >
    with $Provider<CallMediaFactory> {
  /// How a call gets its audio, video and WebRTC link; tests override it
  /// with a fake.
  CallMediaFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callMediaFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callMediaFactoryHash();

  @$internal
  @override
  $ProviderElement<CallMediaFactory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CallMediaFactory create(Ref ref) {
    return callMediaFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallMediaFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallMediaFactory>(value),
    );
  }
}

String _$callMediaFactoryHash() => r'9f3f6a1c2db8e474dad2d777011ef8648da0b8b7';
