// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_inputs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How a composer records voice messages; tests override it with a fake.

@ProviderFor(voiceRecorderFactory)
final voiceRecorderFactoryProvider = VoiceRecorderFactoryProvider._();

/// How a composer records voice messages; tests override it with a fake.

final class VoiceRecorderFactoryProvider
    extends
        $FunctionalProvider<
          VoiceRecorderFactory,
          VoiceRecorderFactory,
          VoiceRecorderFactory
        >
    with $Provider<VoiceRecorderFactory> {
  /// How a composer records voice messages; tests override it with a fake.
  VoiceRecorderFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceRecorderFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceRecorderFactoryHash();

  @$internal
  @override
  $ProviderElement<VoiceRecorderFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VoiceRecorderFactory create(Ref ref) {
    return voiceRecorderFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceRecorderFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceRecorderFactory>(value),
    );
  }
}

String _$voiceRecorderFactoryHash() =>
    r'03a7e0ccbd562b340d6efb8400bcde337ee3049c';

/// How voice messages play; tests override it with a fake.

@ProviderFor(voicePlayerFactory)
final voicePlayerFactoryProvider = VoicePlayerFactoryProvider._();

/// How voice messages play; tests override it with a fake.

final class VoicePlayerFactoryProvider
    extends
        $FunctionalProvider<
          VoicePlayerFactory,
          VoicePlayerFactory,
          VoicePlayerFactory
        >
    with $Provider<VoicePlayerFactory> {
  /// How voice messages play; tests override it with a fake.
  VoicePlayerFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voicePlayerFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voicePlayerFactoryHash();

  @$internal
  @override
  $ProviderElement<VoicePlayerFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VoicePlayerFactory create(Ref ref) {
    return voicePlayerFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoicePlayerFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoicePlayerFactory>(value),
    );
  }
}

String _$voicePlayerFactoryHash() =>
    r'900a4cc61d0556a6aaa30aaa930677bc2d3843c1';
