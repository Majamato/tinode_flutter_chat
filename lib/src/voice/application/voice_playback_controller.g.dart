// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_playback_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The voice message playing, one at a time; null when none is. Starting
/// another stops the first; a call or a recording stops it too, and one
/// that plays to its end rewinds. It plays at the speed the user picked
/// (see [VoiceSpeedController]), which applies at once. Each bubble
/// selects its own key, so only the playing one rebuilds.

@ProviderFor(VoicePlaybackController)
final voicePlaybackControllerProvider = VoicePlaybackControllerProvider._();

/// The voice message playing, one at a time; null when none is. Starting
/// another stops the first; a call or a recording stops it too, and one
/// that plays to its end rewinds. It plays at the speed the user picked
/// (see [VoiceSpeedController]), which applies at once. Each bubble
/// selects its own key, so only the playing one rebuilds.
final class VoicePlaybackControllerProvider
    extends $NotifierProvider<VoicePlaybackController, VoicePlayback?> {
  /// The voice message playing, one at a time; null when none is. Starting
  /// another stops the first; a call or a recording stops it too, and one
  /// that plays to its end rewinds. It plays at the speed the user picked
  /// (see [VoiceSpeedController]), which applies at once. Each bubble
  /// selects its own key, so only the playing one rebuilds.
  VoicePlaybackControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voicePlaybackControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voicePlaybackControllerHash();

  @$internal
  @override
  VoicePlaybackController create() => VoicePlaybackController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoicePlayback? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoicePlayback?>(value),
    );
  }
}

String _$voicePlaybackControllerHash() =>
    r'e55a309960c78d0dd5dc96d4fe270c09aa11f4b6';

/// The voice message playing, one at a time; null when none is. Starting
/// another stops the first; a call or a recording stops it too, and one
/// that plays to its end rewinds. It plays at the speed the user picked
/// (see [VoiceSpeedController]), which applies at once. Each bubble
/// selects its own key, so only the playing one rebuilds.

abstract class _$VoicePlaybackController extends $Notifier<VoicePlayback?> {
  VoicePlayback? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VoicePlayback?, VoicePlayback?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VoicePlayback?, VoicePlayback?>,
              VoicePlayback?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
