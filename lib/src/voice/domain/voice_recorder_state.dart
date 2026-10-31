import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// Whether the composer is recording a voice message.
sealed class VoiceRecorderState with ValueObject {
  const VoiceRecorderState();
}

/// Not recording.
final class VoiceIdle extends VoiceRecorderState {
  const VoiceIdle();

  @override
  List<Object?> get props => const [];
}

/// Recording, for [elapsed] so far (whole seconds of recorded time, not
/// counting pauses), or [paused].
final class VoiceRecording extends VoiceRecorderState {
  const VoiceRecording(this.elapsed, {this.paused = false});

  final Duration elapsed;
  final bool paused;

  @override
  List<Object?> get props => [elapsed, paused];
}
