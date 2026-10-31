import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';

/// The recorder could not start or save.
final class VoiceRecorderException implements Exception {
  const VoiceRecorderException(this.cause);

  final Object? cause;

  @override
  String toString() => 'VoiceRecorderException($cause)';
}

/// The microphone, for one voice message at a time. The recorder logic
/// drives it through this interface, so it runs in tests without devices.
abstract interface class VoiceRecorder {
  /// Whether the app may use the microphone; the OS asks the user the
  /// first time.
  Future<bool> hasPermission();

  /// Starts recording into a new temporary file. Throws
  /// [VoiceRecorderException].
  Future<void> start();

  /// Pauses the recording, which [resume] carries on in the same file.
  /// Throws [VoiceRecorderException].
  Future<void> pause();

  /// Carries on a recording [pause] paused. Throws
  /// [VoiceRecorderException].
  Future<void> resume();

  /// The level in dBFS, every `voiceSampleInterval` while recording; quiet
  /// while paused.
  Stream<double> get levels;

  /// Stops and returns the recording; null when nothing was saved.
  Future<PickedFile?> stop();

  /// Stops and deletes the recording.
  Future<void> cancel();

  /// Deletes a recording [stop] returned, once it was staged.
  Future<void> delete(PickedFile recording);

  /// Releases the microphone.
  Future<void> dispose();
}

/// Makes the recorder of one composer.
typedef VoiceRecorderFactory = VoiceRecorder Function();
