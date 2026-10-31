// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_file.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The recording [source] holds, on this device: a received one is
/// downloaded among the kept files once, when its bubble shows; one of the
/// user's is there since it was recorded. Playback only ever opens this
/// file, never the server's. Null when a staged copy is gone; an error
/// when the download failed, until the next connect.

@ProviderFor(voiceFile)
final voiceFileProvider = VoiceFileFamily._();

/// The recording [source] holds, on this device: a received one is
/// downloaded among the kept files once, when its bubble shows; one of the
/// user's is there since it was recorded. Playback only ever opens this
/// file, never the server's. Null when a staged copy is gone; an error
/// when the download failed, until the next connect.

final class VoiceFileProvider
    extends
        $FunctionalProvider<
          AsyncValue<LocalFile?>,
          LocalFile?,
          FutureOr<LocalFile?>
        >
    with $FutureModifier<LocalFile?>, $FutureProvider<LocalFile?> {
  /// The recording [source] holds, on this device: a received one is
  /// downloaded among the kept files once, when its bubble shows; one of the
  /// user's is there since it was recorded. Playback only ever opens this
  /// file, never the server's. Null when a staged copy is gone; an error
  /// when the download failed, until the next connect.
  VoiceFileProvider._({
    required VoiceFileFamily super.from,
    required VoiceSource super.argument,
  }) : super(
         retry: null,
         name: r'voiceFileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$voiceFileHash();

  @override
  String toString() {
    return r'voiceFileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LocalFile?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LocalFile?> create(Ref ref) {
    final argument = this.argument as VoiceSource;
    return voiceFile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VoiceFileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$voiceFileHash() => r'7193c77f79f63fb61e8b303033046e7b4a59f9d1';

/// The recording [source] holds, on this device: a received one is
/// downloaded among the kept files once, when its bubble shows; one of the
/// user's is there since it was recorded. Playback only ever opens this
/// file, never the server's. Null when a staged copy is gone; an error
/// when the download failed, until the next connect.

final class VoiceFileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LocalFile?>, VoiceSource> {
  VoiceFileFamily._()
    : super(
        retry: null,
        name: r'voiceFileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The recording [source] holds, on this device: a received one is
  /// downloaded among the kept files once, when its bubble shows; one of the
  /// user's is there since it was recorded. Playback only ever opens this
  /// file, never the server's. Null when a staged copy is gone; an error
  /// when the download failed, until the next connect.

  VoiceFileProvider call(VoiceSource source) =>
      VoiceFileProvider._(argument: source, from: this);

  @override
  String toString() => r'voiceFileProvider';
}
