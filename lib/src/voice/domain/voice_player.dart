import 'dart:typed_data';

/// A recording could not be opened, e.g. in a format this device can't
/// play.
final class VoicePlayerException implements Exception {
  const VoicePlayerException(this.cause);

  final Object? cause;

  @override
  String toString() => 'VoicePlayerException($cause)';
}

/// Plays one voice message at a time. The playback logic drives it through
/// this interface, so it runs in tests without devices.
abstract interface class VoicePlayer {
  /// Loads the recording at [path] and returns its duration, when the file
  /// tells. Throws [VoicePlayerException].
  Future<Duration?> openFile(String path);

  /// Loads a recording held in memory, like [openFile].
  Future<Duration?> openBytes(Uint8List bytes, {String? mimeType});

  /// Plays the loaded recording from where it stands.
  void play();

  Future<void> pause();

  Future<void> seek(Duration position);

  /// Plays at [rate] times normal speed, keeping the pitch, from now on.
  Future<void> setSpeed(double rate);

  /// Stops and unloads the recording.
  Future<void> stop();

  /// Where playback stands, often enough to move a playhead.
  Stream<Duration> get positions;

  /// Fires when a recording played to its end.
  Stream<void> get completions;

  Future<void> dispose();
}

/// Makes the player of a chat.
typedef VoicePlayerFactory = VoicePlayer Function();
