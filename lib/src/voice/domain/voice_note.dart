import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// What a voice message says about its recording: how long it plays and
/// its [waveform], the loudness along it from 0 (silent) to 100 (its
/// loudest point).
final class VoiceNote with ValueObject {
  const VoiceNote({required this.duration, this.waveform = const []});

  /// Shorter recordings are not sent, as in TinodeWeb and Tindroid.
  static const minDuration = Duration(seconds: 2);

  /// A recording stops, and is sent, once it is this long.
  static const maxDuration = Duration(minutes: 10);

  final Duration duration;

  /// The loudness along the recording, each 0..100; empty when unknown.
  final List<int> waveform;

  @override
  List<Object?> get props => [duration, waveform];
}

/// [duration] as a clock, `m:ss`: `0:07`, `1:42`, `10:00`.
String voiceClock(Duration duration) {
  final seconds = duration.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
