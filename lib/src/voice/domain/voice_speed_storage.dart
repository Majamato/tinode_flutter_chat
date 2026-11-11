import 'package:tinode_flutter_chat/src/voice/domain/voice_speed.dart';

/// Keeps the voice message speed the user picked on this device, for every
/// user of it.
abstract interface class VoiceSpeedStorage {
  /// What was saved last, or [VoiceSpeed.normal].
  Future<VoiceSpeed> read();

  /// Saves [speed]; writes land in the order they were made.
  Future<void> write(VoiceSpeed speed);
}
