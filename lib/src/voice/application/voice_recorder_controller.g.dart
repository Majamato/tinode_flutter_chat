// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_recorder_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Recording a voice message in one chat's composer: [start], maybe
/// [pause] and [resume], then [send] or [cancel]. Sending goes through the
/// chat's `SendController`, so its failures show where a file's would. The
/// recording is dropped when the composer goes and when a call starts; at
/// `VoiceNote.maxDuration` of recorded time it is sent. The time counts
/// only what was recorded, not the pauses.
///
/// The levels go to [liveLevels] as they come, outside the state, so only
/// the live waveform repaints for them.

@ProviderFor(VoiceRecorderController)
final voiceRecorderControllerProvider = VoiceRecorderControllerFamily._();

/// Recording a voice message in one chat's composer: [start], maybe
/// [pause] and [resume], then [send] or [cancel]. Sending goes through the
/// chat's `SendController`, so its failures show where a file's would. The
/// recording is dropped when the composer goes and when a call starts; at
/// `VoiceNote.maxDuration` of recorded time it is sent. The time counts
/// only what was recorded, not the pauses.
///
/// The levels go to [liveLevels] as they come, outside the state, so only
/// the live waveform repaints for them.
final class VoiceRecorderControllerProvider
    extends $NotifierProvider<VoiceRecorderController, VoiceRecorderState> {
  /// Recording a voice message in one chat's composer: [start], maybe
  /// [pause] and [resume], then [send] or [cancel]. Sending goes through the
  /// chat's `SendController`, so its failures show where a file's would. The
  /// recording is dropped when the composer goes and when a call starts; at
  /// `VoiceNote.maxDuration` of recorded time it is sent. The time counts
  /// only what was recorded, not the pauses.
  ///
  /// The levels go to [liveLevels] as they come, outside the state, so only
  /// the live waveform repaints for them.
  VoiceRecorderControllerProvider._({
    required VoiceRecorderControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'voiceRecorderControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$voiceRecorderControllerHash();

  @override
  String toString() {
    return r'voiceRecorderControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  VoiceRecorderController create() => VoiceRecorderController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceRecorderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceRecorderState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VoiceRecorderControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$voiceRecorderControllerHash() =>
    r'a9d46c35c135cde1f3f9ad279f9114e6d5da065f';

/// Recording a voice message in one chat's composer: [start], maybe
/// [pause] and [resume], then [send] or [cancel]. Sending goes through the
/// chat's `SendController`, so its failures show where a file's would. The
/// recording is dropped when the composer goes and when a call starts; at
/// `VoiceNote.maxDuration` of recorded time it is sent. The time counts
/// only what was recorded, not the pauses.
///
/// The levels go to [liveLevels] as they come, outside the state, so only
/// the live waveform repaints for them.

final class VoiceRecorderControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          VoiceRecorderController,
          VoiceRecorderState,
          VoiceRecorderState,
          VoiceRecorderState,
          String
        > {
  VoiceRecorderControllerFamily._()
    : super(
        retry: null,
        name: r'voiceRecorderControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Recording a voice message in one chat's composer: [start], maybe
  /// [pause] and [resume], then [send] or [cancel]. Sending goes through the
  /// chat's `SendController`, so its failures show where a file's would. The
  /// recording is dropped when the composer goes and when a call starts; at
  /// `VoiceNote.maxDuration` of recorded time it is sent. The time counts
  /// only what was recorded, not the pauses.
  ///
  /// The levels go to [liveLevels] as they come, outside the state, so only
  /// the live waveform repaints for them.

  VoiceRecorderControllerProvider call(String topic) =>
      VoiceRecorderControllerProvider._(argument: topic, from: this);

  @override
  String toString() => r'voiceRecorderControllerProvider';
}

/// Recording a voice message in one chat's composer: [start], maybe
/// [pause] and [resume], then [send] or [cancel]. Sending goes through the
/// chat's `SendController`, so its failures show where a file's would. The
/// recording is dropped when the composer goes and when a call starts; at
/// `VoiceNote.maxDuration` of recorded time it is sent. The time counts
/// only what was recorded, not the pauses.
///
/// The levels go to [liveLevels] as they come, outside the state, so only
/// the live waveform repaints for them.

abstract class _$VoiceRecorderController extends $Notifier<VoiceRecorderState> {
  late final _$args = ref.$arg as String;
  String get topic => _$args;

  VoiceRecorderState build(String topic);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VoiceRecorderState, VoiceRecorderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VoiceRecorderState, VoiceRecorderState>,
              VoiceRecorderState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
