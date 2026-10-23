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

/// The texts of the system's call screens; `createTinodeContainer`
/// overrides it with the host's.

@ProviderFor(systemCallTexts)
final systemCallTextsProvider = SystemCallTextsProvider._();

/// The texts of the system's call screens; `createTinodeContainer`
/// overrides it with the host's.

final class SystemCallTextsProvider
    extends
        $FunctionalProvider<SystemCallTexts, SystemCallTexts, SystemCallTexts>
    with $Provider<SystemCallTexts> {
  /// The texts of the system's call screens; `createTinodeContainer`
  /// overrides it with the host's.
  SystemCallTextsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'systemCallTextsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$systemCallTextsHash();

  @$internal
  @override
  $ProviderElement<SystemCallTexts> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SystemCallTexts create(Ref ref) {
    return systemCallTexts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SystemCallTexts value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SystemCallTexts>(value),
    );
  }
}

String _$systemCallTextsHash() => r'363d27c337673655bcee81e3b79c2426dd1b93bb';

/// The phone's own call screens, unless the host turned them off; tests
/// override it with a fake.

@ProviderFor(systemCalls)
final systemCallsProvider = SystemCallsProvider._();

/// The phone's own call screens, unless the host turned them off; tests
/// override it with a fake.

final class SystemCallsProvider
    extends $FunctionalProvider<SystemCalls, SystemCalls, SystemCalls>
    with $Provider<SystemCalls> {
  /// The phone's own call screens, unless the host turned them off; tests
  /// override it with a fake.
  SystemCallsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'systemCallsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$systemCallsHash();

  @$internal
  @override
  $ProviderElement<SystemCalls> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SystemCalls create(Ref ref) {
    return systemCalls(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SystemCalls value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SystemCalls>(value),
    );
  }
}

String _$systemCallsHash() => r'b316bd53937016c911c0ab82fd4895c3114f4a09';
