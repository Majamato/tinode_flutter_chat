import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_inputs.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_speed_controller.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_speed.dart';

import '../../support/memory_voice_speed_storage.dart';
import '../../support/test_container.dart';

void main() {
  late MemoryVoiceSpeedStorage storage;
  late ProviderContainer container;

  setUp(() {
    storage = MemoryVoiceSpeedStorage(VoiceSpeed.fastest);
    container = ProviderContainer(
      overrides: [voiceSpeedStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
  });

  VoiceSpeed speed() => container.read(voiceSpeedControllerProvider);
  VoiceSpeedController controller() =>
      container.read(voiceSpeedControllerProvider.notifier);

  test('starts normal, then plays at the saved speed', () async {
    expect(speed(), VoiceSpeed.normal);
    await settle();
    expect(speed(), VoiceSpeed.fastest);
  });

  test('a tap moves to the next speed and saves it', () async {
    speed();
    await settle();
    await controller().cycle();
    expect(speed(), VoiceSpeed.normal);
    expect(storage.speed, VoiceSpeed.normal);
    await controller().cycle();
    expect(speed(), VoiceSpeed.fast);
    expect(storage.speed, VoiceSpeed.fast);
    expect(storage.writes, 2);
  });

  test('a tap before the saved speed is read wins over it', () async {
    final gate = storage.readGate = Completer<void>();
    speed();
    await controller().cycle();
    expect(speed(), VoiceSpeed.fast);

    gate.complete();
    await settle();
    expect(speed(), VoiceSpeed.fast);
    expect(storage.speed, VoiceSpeed.fast);
  });
}
