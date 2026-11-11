import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_playback_controller.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_speed_controller.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_failure.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_playback.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_speed.dart';

import '../../support/fake_call_media.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fake_voice_player.dart';
import '../../support/fixtures.dart';
import '../../support/memory_voice_speed_storage.dart';
import '../../support/test_container.dart';

void main() {
  const first = RefVoiceSource('/v0/file/s/one.m4a');
  const second = RefVoiceSource('/v0/file/s/two.m4a');

  late FakeTinodeSession session;
  late FakeVoicePlayer player;
  late ProviderContainer container;

  /// The files of [first] and [second], as the memory file store holds
  /// them.
  final firstFile = LocalFile.inMemory(Uint8List.fromList([1, 2, 3]));
  final secondFile = LocalFile.inMemory(Uint8List.fromList([4, 5]));

  VoicePlayback? playback() => container.read(voicePlaybackControllerProvider);
  VoicePlaybackController controller() =>
      container.read(voicePlaybackControllerProvider.notifier);

  setUp(() async {
    session = FakeTinodeSession(chats: [chat(bob, name: 'Bob')]);
    player = FakeVoicePlayer();
    container =
        await loggedInContainer(
            session,
            voicePlayer: () => player,
            voiceSpeedStorage: MemoryVoiceSpeedStorage(VoiceSpeed.fast),
            callMedia: FakeCallMediaFactory().call,
          )
          ..listen(voicePlaybackControllerProvider, (_, _) {});
  });

  test('plays a received message, pauses and resumes it', () async {
    expect(await controller().toggle(first, firstFile), isNull);
    expect(
      playback(),
      const VoicePlayback(
        key: 'ref:/v0/file/s/one.m4a',
        playing: true,
        duration: Duration(seconds: 3),
      ),
    );
    expect(player.opened, ['bytes:3']);
    expect(player.playing, isTrue);

    player.moveTo(const Duration(seconds: 1));
    await settle();
    expect(playback()!.position, const Duration(seconds: 1));
    expect(playback()!.progress, closeTo(1 / 3, 1e-9));

    await controller().toggle(first, firstFile);
    expect(playback()!.playing, isFalse);
    expect(player.playing, isFalse);
    await controller().toggle(first, firstFile);
    expect(playback()!.playing, isTrue);
    expect(playback()!.position, const Duration(seconds: 1));
    expect(player.opened, hasLength(1));
  });

  test('a file on disk opens by its path', () async {
    const file = LocalFile.atPath('/kept/one.m4a', length: 3);
    await controller().toggle(first, file);
    expect(player.opened, ['/kept/one.m4a']);
    expect(player.playing, isTrue);
  });

  test('shows as playing at once, while the player opens the file', () async {
    final gate = player.openGate = Completer<void>();
    final played = controller().toggle(first, firstFile);
    expect(
      playback(),
      const VoicePlayback(
        key: 'ref:/v0/file/s/one.m4a',
        playing: true,
        loading: true,
      ),
    );
    // Taps wait until the file is open.
    await controller().toggle(first, firstFile);
    expect(playback()!.loading, isTrue);

    gate.complete();
    await played;
    expect(playback()!.loading, isFalse);
    expect(playback()!.playing, isTrue);
    expect(player.playing, isTrue);
  });

  test('one message at a time: another stops the first', () async {
    await controller().toggle(first, firstFile);
    await controller().toggle(second, secondFile);
    expect(playback()!.key, second.key);
    expect(player.stops, 1);
    expect(player.opened, ['bytes:3', 'bytes:2']);
  });

  test('a message that ends rewinds, and seeking moves the playhead', () async {
    await controller().toggle(first, firstFile);
    await controller().seek(first.key, 0.5);
    expect(player.seekedTo, const Duration(milliseconds: 1500));
    expect(playback()!.progress, 0.5);
    await controller().seek(second.key, 0.9);
    expect(player.seekedTo, const Duration(milliseconds: 1500));

    player.finish();
    await settle();
    expect(playback(), isNull);
  });

  test('positions from before a seek are ignored until it is done', () async {
    await controller().toggle(first, firstFile);
    player.moveTo(const Duration(milliseconds: 500));
    await settle();

    final gate = player.seekGate = Completer<void>();
    final seeking = controller().seek(first.key, 0.5);
    expect(playback()!.position, const Duration(milliseconds: 1500));
    player.moveTo(const Duration(milliseconds: 600));
    await settle();
    expect(playback()!.position, const Duration(milliseconds: 1500));

    gate.complete();
    await seeking;
    player.moveTo(const Duration(milliseconds: 1600));
    await settle();
    expect(playback()!.position, const Duration(milliseconds: 1600));
  });

  test('quick seeks go one at a time and end at the last', () async {
    await controller().toggle(first, firstFile);
    final gate = player.seekGate = Completer<void>();
    for (final fraction in [0.2, 0.5, 0.8]) {
      await controller().seek(first.key, fraction);
    }
    expect(player.seeks, [const Duration(milliseconds: 600)]);
    expect(playback()!.position, const Duration(milliseconds: 2400));

    gate.complete();
    await settle();
    expect(player.seeks, const [
      Duration(milliseconds: 600),
      Duration(milliseconds: 2400),
    ]);
  });

  test('while playing, a position behind the one shown is ignored', () async {
    await controller().toggle(first, firstFile);
    player.moveTo(const Duration(milliseconds: 300));
    await settle();
    player.moveTo(const Duration(milliseconds: 120));
    await settle();
    expect(playback()!.position, const Duration(milliseconds: 300));

    player.moveTo(const Duration(milliseconds: 400));
    await settle();
    expect(playback()!.position, const Duration(milliseconds: 400));
  });

  test('a message started again shows from the start', () async {
    await controller().toggle(first, firstFile);
    player.moveTo(const Duration(seconds: 2));
    await settle();
    player.finish();
    await settle();

    await controller().toggle(first, firstFile);
    player.moveTo(const Duration(milliseconds: 100));
    await settle();
    expect(playback()!.position, const Duration(milliseconds: 100));
  });

  test('a recording that does not play says so', () async {
    player.failOpen = true;
    expect(
      await controller().toggle(first, firstFile),
      VoiceFailure.cannotPlay,
    );
    expect(playback(), isNull);
  });

  test('a call stops it', () async {
    await controller().toggle(first, firstFile);
    container.listen(callControllerProvider, (_, _) {});
    await container
        .read(callControllerProvider.notifier)
        .start(bob, audioOnly: true);
    await settle();
    expect(playback(), isNull);
    expect(player.playing, isFalse);
  });

  test('plays at the saved speed, and a new pick applies at once', () async {
    await controller().toggle(first, firstFile);
    await settle();
    expect(player.speed, 1.5);

    await container.read(voiceSpeedControllerProvider.notifier).cycle();
    expect(player.speed, 2);
    await controller().toggle(second, secondFile);
    expect(player.speed, 2);
  });
}
