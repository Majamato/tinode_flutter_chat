import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_inputs.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_speed.dart';

part 'voice_speed_controller.g.dart';

/// How fast voice messages play: [VoiceSpeed.normal] until the saved
/// speed is read, which a pick made meanwhile wins over.
@Riverpod(keepAlive: true)
class VoiceSpeedController extends _$VoiceSpeedController {
  var _picked = false;

  @override
  VoiceSpeed build() {
    unawaited(_load());
    return VoiceSpeed.normal;
  }

  /// Moves to the next speed, see [VoiceSpeed.next], and saves it.
  Future<void> cycle() {
    _picked = true;
    final speed = state = state.next;
    return ref.read(voiceSpeedStorageProvider).write(speed);
  }

  Future<void> _load() async {
    final saved = await ref.read(voiceSpeedStorageProvider).read();
    if (!_picked && ref.mounted) {
      state = saved;
    }
  }
}
