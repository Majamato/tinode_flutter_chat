// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_speed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How fast voice messages play: [VoiceSpeed.normal] until the saved
/// speed is read, which a pick made meanwhile wins over.

@ProviderFor(VoiceSpeedController)
final voiceSpeedControllerProvider = VoiceSpeedControllerProvider._();

/// How fast voice messages play: [VoiceSpeed.normal] until the saved
/// speed is read, which a pick made meanwhile wins over.
final class VoiceSpeedControllerProvider
    extends $NotifierProvider<VoiceSpeedController, VoiceSpeed> {
  /// How fast voice messages play: [VoiceSpeed.normal] until the saved
  /// speed is read, which a pick made meanwhile wins over.
  VoiceSpeedControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceSpeedControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceSpeedControllerHash();

  @$internal
  @override
  VoiceSpeedController create() => VoiceSpeedController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceSpeed value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceSpeed>(value),
    );
  }
}

String _$voiceSpeedControllerHash() =>
    r'1e6ab5cdbaa6969680b3c4419eda0883a434044d';

/// How fast voice messages play: [VoiceSpeed.normal] until the saved
/// speed is read, which a pick made meanwhile wins over.

abstract class _$VoiceSpeedController extends $Notifier<VoiceSpeed> {
  VoiceSpeed build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VoiceSpeed, VoiceSpeed>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VoiceSpeed, VoiceSpeed>,
              VoiceSpeed,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
