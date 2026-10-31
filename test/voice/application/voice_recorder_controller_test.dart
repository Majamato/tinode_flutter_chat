import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_playback_controller.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_recorder_controller.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_failure.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_playback.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_recorder_state.dart';

import '../../support/fake_call_media.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fake_voice_player.dart';
import '../../support/fake_voice_recorder.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;
  late FakeVoiceRecorder recorder;
  late FakeVoicePlayer player;
  late ProviderContainer container;

  VoiceRecorderState state() =>
      container.read(voiceRecorderControllerProvider(bob));
  VoiceRecorderController controller() =>
      container.read(voiceRecorderControllerProvider(bob).notifier);

  /// Runs [body] in fake time, logged in, with the recorder of Bob's chat
  /// alive.
  void run(void Function(FakeAsync async) body) => fakeAsync((async) {
    session = FakeTinodeSession(chats: [chat(bob, name: 'Bob')]);
    recorder = FakeVoiceRecorder();
    player = FakeVoicePlayer();
    unawaited(
      loggedInContainer(
        session,
        voiceRecorder: () => recorder,
        voicePlayer: () => player,
        callMedia: FakeCallMediaFactory().call,
      ).then((c) => container = c),
    );
    async.flushMicrotasks();
    container.listen(voiceRecorderControllerProvider(bob), (_, _) {});
    body(async);
  });

  /// Waits for [future] in fake time.
  T wait<T>(FakeAsync async, Future<T> future) {
    late T result;
    unawaited(future.then((value) => result = value));
    async
      ..flushMicrotasks()
      ..elapse(const Duration(milliseconds: 10));
    return result;
  }

  List<DataMessage> sent() => session.histories[bob] ?? const [];

  test('records, ticks each second, and sends an AU with its preview', () {
    run((async) {
      expect(wait(async, controller().start()), isNull);
      expect(state(), const VoiceRecording(Duration.zero));
      expect(recorder.recording, isTrue);

      for (final dbfs in [-40.0, 0.0, -6.0]) {
        recorder.level(dbfs);
        async.elapse(const Duration(milliseconds: 100));
      }
      async.elapse(const Duration(seconds: 3));
      expect(state(), const VoiceRecording(Duration(seconds: 3)));

      expect(wait(async, controller().send()), isNull);
      async.elapse(const Duration(seconds: 1));
      expect(state(), const VoiceIdle());

      final audio =
          (sent().single.content as DraftyContent).drafty.files.single
              as DraftyAudio;
      expect(audio.mimeType, 'audio/mp4');
      expect(audio.duration!.inMilliseconds, closeTo(3310, 20));
      expect(audio.preview, [1, 100, 50]);
      expect(audio.ref, startsWith('/v0/file/s/'));
      expect(recorder.deleted, hasLength(1));
    });
  });

  test('a recording under two seconds is dropped as too short', () {
    run((async) {
      wait(async, controller().start());
      async.elapse(const Duration(milliseconds: 1500));
      expect(wait(async, controller().send()), VoiceFailure.tooShort);
      async.elapse(const Duration(seconds: 1));
      expect(state(), const VoiceIdle());
      expect(sent(), isEmpty);
      expect(recorder.deleted, hasLength(1));
    });
  });

  test('cancel stops and drops the recording', () {
    run((async) {
      wait(async, controller().start());
      async.elapse(const Duration(seconds: 5));
      wait(async, controller().cancel());
      expect(state(), const VoiceIdle());
      expect(recorder.cancels, 1);
      async.elapse(const Duration(seconds: 2));
      expect(sent(), isEmpty);
      expect(state(), const VoiceIdle());
    });
  });

  test('without the microphone, or when the recorder fails, nothing '
      'starts', () {
    run((async) {
      recorder.permission = false;
      expect(wait(async, controller().start()), VoiceFailure.microphoneDenied);
      expect(state(), const VoiceIdle());

      recorder
        ..permission = true
        ..failStart = true;
      expect(wait(async, controller().start()), VoiceFailure.recorderFailed);
      expect(state(), const VoiceIdle());
    });
  });

  test('ten minutes in, the recording sends itself', () {
    run((async) {
      wait(async, controller().start());
      async.elapse(const Duration(minutes: 10, seconds: 1));
      expect(state(), const VoiceIdle());
      async.elapse(const Duration(seconds: 1));
      final audio =
          (sent().single.content as DraftyContent).drafty.files.single
              as DraftyAudio;
      expect(audio.duration, const Duration(minutes: 10));
    });
  });

  group('pause and resume', () {
    test('pausing stops the clock; resuming carries it on; the note has '
        'the recorded time only', () {
      run((async) {
        wait(async, controller().start());
        async.elapse(const Duration(seconds: 3));
        expect(wait(async, controller().pause()), isNull);
        expect(recorder.paused, isTrue);
        expect(
          state(),
          const VoiceRecording(Duration(seconds: 3), paused: true),
        );

        async.elapse(const Duration(seconds: 5));
        expect(
          state(),
          const VoiceRecording(Duration(seconds: 3), paused: true),
        );

        expect(wait(async, controller().resume()), isNull);
        expect(recorder.paused, isFalse);
        expect(state(), const VoiceRecording(Duration(seconds: 3)));
        // The clock is read every 250 ms, so a second shows within one.
        async.elapse(const Duration(seconds: 2, milliseconds: 250));
        expect(state(), const VoiceRecording(Duration(seconds: 5)));

        expect(wait(async, controller().send()), isNull);
        async.elapse(const Duration(seconds: 1));
        final audio =
            (sent().single.content as DraftyContent).drafty.files.single
                as DraftyAudio;
        expect(audio.duration!.inMilliseconds, closeTo(5270, 30));
      });
    });

    test('ten minutes counts recorded time only', () {
      run((async) {
        wait(async, controller().start());
        async.elapse(const Duration(minutes: 9));
        wait(async, controller().pause());
        async.elapse(const Duration(minutes: 5));
        expect(state(), isA<VoiceRecording>());
        wait(async, controller().resume());
        async.elapse(const Duration(seconds: 59));
        expect(state(), isA<VoiceRecording>());
        async.elapse(const Duration(seconds: 2));
        expect(state(), const VoiceIdle());
        async.elapse(const Duration(seconds: 1));
        final audio =
            (sent().single.content as DraftyContent).drafty.files.single
                as DraftyAudio;
        expect(audio.duration, const Duration(minutes: 10));
      });
    });

    test('do nothing when idle, or already paused or running', () {
      run((async) {
        expect(wait(async, controller().pause()), isNull);
        expect(wait(async, controller().resume()), isNull);
        expect(recorder.pauses + recorder.resumes, 0);

        wait(async, controller().start());
        expect(wait(async, controller().resume()), isNull);
        expect(recorder.resumes, 0);
        wait(async, controller().pause());
        expect(wait(async, controller().pause()), isNull);
        expect(recorder.pauses, 1);
      });
    });

    test('a recorder that fails to pause leaves the recording running', () {
      run((async) {
        wait(async, controller().start());
        async.elapse(const Duration(seconds: 2));
        recorder.failPause = true;
        expect(wait(async, controller().pause()), VoiceFailure.recorderFailed);
        expect(state(), const VoiceRecording(Duration(seconds: 2)));
        async.elapse(const Duration(seconds: 1));
        expect(state(), const VoiceRecording(Duration(seconds: 3)));

        recorder.failPause = false;
        wait(async, controller().pause());
        recorder.failPause = true;
        expect(wait(async, controller().resume()), VoiceFailure.recorderFailed);
        expect(
          state(),
          const VoiceRecording(Duration(seconds: 3), paused: true),
        );
      });
    });

    test('a paused recording can be cancelled', () {
      run((async) {
        wait(async, controller().start());
        async.elapse(const Duration(seconds: 3));
        wait(async, controller().pause());
        wait(async, controller().cancel());
        expect(state(), const VoiceIdle());
        expect(recorder.cancels, 1);
        expect(sent(), isEmpty);
      });
    });
  });

  test('levels go out live and are kept; a new recording starts afresh', () {
    run((async) {
      final live = <double>[];
      controller().liveLevels.listen(live.add);
      wait(async, controller().start());
      recorder
        ..level(-30)
        ..level(-10);
      async.flushMicrotasks();
      expect(live, [-30, -10]);
      expect(controller().levelsSoFar, [-30, -10]);

      wait(async, controller().cancel());
      wait(async, controller().start());
      expect(controller().levelsSoFar, isEmpty);
    });
  });

  test('no recording during a call; a call that starts drops one', () {
    run((async) {
      wait(async, controller().start());
      expect(state(), isA<VoiceRecording>());

      container.listen(callControllerProvider, (_, _) {});
      wait(
        async,
        container
            .read(callControllerProvider.notifier)
            .start(bob, audioOnly: true),
      );
      expect(state(), const VoiceIdle());
      expect(recorder.cancels, 1);

      expect(wait(async, controller().start()), VoiceFailure.duringCall);
      expect(recorder.starts, 1);
    });
  });

  test('starting stops the voice message playing', () {
    run((async) {
      container.listen(voicePlaybackControllerProvider, (_, _) {});
      wait(
        async,
        container
            .read(voicePlaybackControllerProvider.notifier)
            .toggle(
              const RefVoiceSource('/v0/file/s/a.m4a'),
              LocalFile.inMemory(recorder.bytes),
            ),
      );
      expect(player.playing, isTrue);

      wait(async, controller().start());
      expect(container.read(voicePlaybackControllerProvider), isNull);
      expect(player.playing, isFalse);
    });
  });

  test('closing the chat drops the recording and frees the microphone', () {
    run((async) {
      final sub = container.listen(
        voiceRecorderControllerProvider(bob),
        (_, _) {},
      );
      wait(async, controller().start());
      container.dispose();
      async.flushMicrotasks();
      sub.close();
      expect(recorder.cancels, 1);
      expect(recorder.disposed, isTrue);
    });
  });
}
