import 'dart:async';

import 'package:tinode_flutter_chat/src/voice/domain/voice_speed.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_speed_storage.dart';

/// A [VoiceSpeedStorage] in memory: it holds [speed] and counts [writes].
final class MemoryVoiceSpeedStorage implements VoiceSpeedStorage {
  MemoryVoiceSpeedStorage([this.speed = VoiceSpeed.normal]);

  VoiceSpeed speed;
  int writes = 0;

  /// When set, reading waits for it, as a slow disk would.
  Completer<void>? readGate;

  @override
  Future<VoiceSpeed> read() async {
    await readGate?.future;
    return speed;
  }

  @override
  Future<void> write(VoiceSpeed speed) async {
    this.speed = speed;
    writes++;
  }
}
