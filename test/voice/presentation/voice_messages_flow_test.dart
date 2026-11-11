import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_speed.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/live_voice_waveform.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/recording_panel.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/voice_bubble_content.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/voice_speed_button.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fake_voice_player.dart';
import '../../support/fake_voice_recorder.dart';
import '../../support/fixtures.dart';
import '../../support/memory_voice_speed_storage.dart';
import '../../support/pump_tinode_chat.dart';

const icons = TinodeChatIcons();

const voiceRef = '/v0/file/s/hello.m4a';

DataMessage voiceMessage(int seq) => DataMessage(
  topic: bob,
  seq: seq,
  from: bob,
  time: at(seq),
  head: const MessageHead(mime: MessageHead.draftyMime),
  content: DraftyContent(
    Drafty.audio(
      DraftyAudio(
        mimeType: 'audio/mp4',
        ref: voiceRef,
        duration: const Duration(seconds: 4),
        preview: Uint8List.fromList([for (var i = 0; i < 96; i++) i]),
      ),
    ),
  ),
);

void main() {
  late FakeTinodeSession session;
  late FakeVoiceRecorder recorder;
  late FakeVoicePlayer player;
  late MemoryVoiceSpeedStorage speeds;

  setUp(() {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 1, read: 1, lastMessageAt: at(1)),
      ],
      histories: {
        bob: [voiceMessage(1)],
      },
    );
    session.files[voiceRef] = Uint8List.fromList([1, 2, 3, 4]);
    recorder = FakeVoiceRecorder();
    player = FakeVoicePlayer();
    speeds = MemoryVoiceSpeedStorage();
  });

  Future<void> openBob(
    WidgetTester tester, {
    bool reduceMotion = true,
    TinodeBubbleBuilder? bubbleBuilder,
  }) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      voiceRecorder: () => recorder,
      voicePlayer: () => player,
      voiceSpeedStorage: speeds,
      reduceMotion: reduceMotion,
      bubbleBuilder: bubbleBuilder,
    );
    await tester.tap(find.text('Bob'));
    if (reduceMotion) {
      await tester.pumpAndSettle();
    } else {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  }

  /// Pumps a few frames: once a message plays, its dot moves every frame,
  /// so nothing settles.
  Future<void> playFor(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> record(WidgetTester tester, Duration length) async {
    await tester.tap(find.byTooltip('Record voice message'));
    await tester.pump();
    for (var i = 0; i < length.inMilliseconds ~/ 500; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('the mic records, the panel counts, and send queues an AU', (
    tester,
  ) async {
    await openBob(tester);
    await record(tester, const Duration(seconds: 3));
    expect(find.byType(RecordingPanel), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('0:03'), findsOneWidget);
    expect(find.byTooltip('Send voice message'), findsOneWidget);
    expect(recorder.recording, isTrue);

    await tester.tap(find.byTooltip('Send voice message'));
    await tester.pumpAndSettle();

    expect(find.byType(RecordingPanel), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    final sent = session.histories[bob]!.last;
    final audio =
        (sent.content as DraftyContent).drafty.files.single as DraftyAudio;
    expect(audio.duration!.inSeconds, 3);
    expect(session.calls, contains('upload voice-1.m4a'));
    // The received one and the one just sent.
    expect(find.byType(VoiceBubbleContent), findsNWidgets(2));
  });

  testWidgets('delete drops the recording', (tester) async {
    await openBob(tester);
    await record(tester, const Duration(seconds: 1));
    await tester.tap(find.byTooltip('Delete recording'));
    await tester.pumpAndSettle();
    expect(find.byType(RecordingPanel), findsNothing);
    expect(recorder.cancels, 1);
    // Only the received message: no recording.
    expect(session.histories[bob], hasLength(1));
  });

  testWidgets('the field keeps its text while recording', (tester) async {
    await openBob(tester);
    final field = tester.widget<TextField>(find.byType(TextField));
    await record(tester, const Duration(seconds: 1));
    expect(find.byType(TextField), findsNothing);
    field.controller!.text = 'kept';
    await tester.tap(find.byTooltip('Delete recording'));
    await tester.pumpAndSettle();
    expect(find.text('kept'), findsOneWidget);
  });

  testWidgets('pause stops the clock and shows Resume; resume carries on', (
    tester,
  ) async {
    await openBob(tester);
    await record(tester, const Duration(seconds: 2));
    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(recorder.paused, isTrue);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Pause'), findsNothing);
    expect(find.byIcon(icons.microphone), findsOneWidget);
    final waveform = tester.widget<LiveVoiceWaveform>(
      find.byType(LiveVoiceWaveform),
    );
    expect(waveform.running, isFalse);

    // Paused for five seconds: the clock stands.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('0:02'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pump();
    expect(recorder.paused, isFalse);
    expect(recorder.resumes, 1);
    expect(find.text('Pause'), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('0:03'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete recording'));
    await tester.pumpAndSettle();
  });

  testWidgets('send while paused sends the recorded time', (tester) async {
    await openBob(tester);
    await record(tester, const Duration(seconds: 3));
    await tester.tap(find.text('Pause'));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.tap(find.byTooltip('Send voice message'));
    await tester.pumpAndSettle();
    final audio =
        (session.histories[bob]!.last.content as DraftyContent)
                .drafty
                .files
                .single
            as DraftyAudio;
    expect(audio.duration!.inSeconds, 3);
  });

  testWidgets('a recording under two seconds is not sent, and says so', (
    tester,
  ) async {
    await openBob(tester);
    await record(tester, const Duration(seconds: 1));
    await tester.tap(find.byTooltip('Send voice message'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Too short to send. Tap the mic to record.'), findsOne);
    expect(session.histories[bob], hasLength(1));
  });

  testWidgets('without the microphone, nothing records, and it says so', (
    tester,
  ) async {
    recorder.permission = false;
    await openBob(tester);
    await tester.tap(find.byTooltip('Record voice message'));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Allow access to the microphone to record voice messages.'),
      findsOne,
    );
    expect(find.byType(RecordingPanel), findsNothing);
  });

  testWidgets('a received voice message plays and pauses in its bubble', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openBob(tester);
    expect(find.text('0:04'), findsOneWidget);
    // The bubble reads as one: its date, the button and its time, with
    // the duration as the value; a tap plays.
    final bubble = tester
        .getSemantics(find.bySemanticsLabel(RegExp('Play voice message')))
        .getSemanticsData();
    expect(bubble.value, '0:04');
    expect(bubble.hasAction(SemanticsAction.tap), isTrue);

    await tester.tap(find.byIcon(icons.play));
    await playFor(tester);
    expect(player.playing, isTrue);
    expect(find.bySemanticsLabel(RegExp('Pause voice message')), findsOne);

    player.moveTo(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();
    expect(find.text('0:02'), findsOneWidget);

    await tester.tap(find.byIcon(icons.pause));
    await tester.pump();
    expect(player.playing, isFalse);
    expect(find.bySemanticsLabel(RegExp('Play voice message')), findsOne);
    semantics.dispose();
  });

  /// Where the speed pill showing [label] is drawn.
  Rect speedPill(WidgetTester tester, String label) => tester.getRect(
    find.ancestor(of: find.text(label), matching: find.byType(Material)).first,
  );

  /// How much [pill] shrank to fit: the test font is wide.
  double pillScale(Rect pill) => pill.height / VoiceSpeedButton.height;

  testWidgets('a tap just beside the speed pill changes it too, and the '
      'bubble keeps its height as the pill shows', (tester) async {
    await openBob(tester);
    final before = tester.getSize(find.byType(VoiceBubbleContent)).height;
    await tester.tap(find.byIcon(icons.play));
    await playFor(tester);
    expect(tester.getSize(find.byType(VoiceBubbleContent)).height, before);

    var pill = speedPill(tester, '1×');
    await tester.tapAt(pill.centerRight + Offset(8 * pillScale(pill), 0));
    await tester.pump();
    expect(find.text('1.5×'), findsOneWidget);
    pill = speedPill(tester, '1.5×');
    await tester.tapAt(pill.topCenter - Offset(0, 2 * pillScale(pill)));
    await tester.pump();
    expect(find.text('2×'), findsOneWidget);
    expect(player.speed, 2);
  });

  testWidgets('while it plays or pauses, a tap on its speed goes 1.5×, 2× '
      'and back, for every message', (tester) async {
    final semantics = tester.ensureSemantics();
    await openBob(tester);
    expect(find.text('1×'), findsNothing);

    await tester.tap(find.byIcon(icons.play));
    await playFor(tester);
    expect(find.text('1×'), findsOneWidget);
    expect(player.speed, 1);

    await tester.tap(find.text('1×'));
    await tester.pump();
    expect(find.text('1.5×'), findsOneWidget);
    expect(player.speed, 1.5);
    expect(speeds.speed, VoiceSpeed.fast);
    final pill = tester
        .getSemantics(find.bySemanticsLabel('Playback speed'))
        .getSemanticsData();
    expect(pill.value, '1.5×');
    expect(pill.hasAction(SemanticsAction.tap), isTrue);

    await tester.tap(find.byIcon(icons.pause));
    await tester.pump();
    await tester.tap(find.text('1.5×'));
    await tester.pump();
    expect(find.text('2×'), findsOneWidget);
    expect(player.speed, 2);

    await tester.tap(find.text('2×'));
    await tester.pump();
    expect(find.text('1×'), findsOneWidget);
    expect(player.speed, 1);
    expect(speeds.speed, VoiceSpeed.normal);
    semantics.dispose();
  });

  SemanticsData playButton(WidgetTester tester) => tester
      .getSemantics(find.bySemanticsLabel(RegExp('voice message')))
      .getSemanticsData();

  Finder spinnerInBubble() => find.descendant(
    of: find.byType(VoiceBubbleContent),
    matching: find.byType(CircularProgressIndicator),
  );

  testWidgets('a received one plays once its file is here, never spinning', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final download = session.holdDownload = Completer<void>();
    await openBob(tester);
    // The bubble shows complete while the file downloads, but can't play.
    expect(find.text('0:04'), findsOneWidget);
    expect(playButton(tester).hasAction(SemanticsAction.tap), isFalse);
    await tester.tap(find.byIcon(icons.play));
    await tester.pump();
    expect(player.opened, isEmpty);
    expect(spinnerInBubble(), findsNothing);

    download.complete();
    await tester.pumpAndSettle();
    expect(playButton(tester).hasAction(SemanticsAction.tap), isTrue);

    final open = player.openGate = Completer<void>();
    await tester.tap(find.byIcon(icons.play));
    await tester.pump();
    // Pause shows at once, while the player opens the file.
    expect(find.byIcon(icons.pause), findsOneWidget);
    expect(spinnerInBubble(), findsNothing);
    open.complete();
    await playFor(tester);
    expect(player.playing, isTrue);
    expect(player.opened, hasLength(1));
    semantics.dispose();
  });

  testWidgets('one being sent plays once the server has it', (tester) async {
    final upload = session.holdUpload = Completer<void>();
    await openBob(tester);
    await record(tester, const Duration(seconds: 3));
    await tester.tap(find.byTooltip('Send voice message'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // The upload's progress in its button, and no playing meanwhile.
    final sending = find.byWidgetPredicate(
      (w) => w is VoiceBubbleContent && w.busy != null,
    );
    expect(sending, findsOneWidget);
    expect(
      find
          .descendant(of: sending, matching: find.byType(InkWell))
          .evaluate()
          .map((e) => (e.widget as InkWell).onTap),
      everyElement(isNull),
    );

    upload.complete();
    await tester.pumpAndSettle();
    // Only the received one downloads; the sent one plays from this device.
    expect(session.calls.where((c) => c.startsWith('download')), [
      'download $voiceRef',
    ]);
    await tester.tap(find.byIcon(icons.play).first);
    await playFor(tester);
    expect(player.playing, isTrue);
    expect(player.opened, hasLength(1));
  });

  testWidgets('a failed download is tried again with a tap', (tester) async {
    session.failDownload = ServerUnreachableException(Exception('offline'));
    await openBob(tester);
    await tester.tap(find.byIcon(icons.play));
    await tester.pumpAndSettle();
    expect(player.playing, isFalse);
    expect(session.calls.where((c) => c == 'download $voiceRef'), hasLength(2));

    await tester.tap(find.byIcon(icons.play));
    await playFor(tester);
    expect(player.playing, isTrue);
  });

  testWidgets('a bubble builder sees the voice kind', (tester) async {
    final kinds = <TinodeBubbleKind>[];
    await openBob(
      tester,
      bubbleBuilder: (context, bubble, defaultBubble) {
        kinds.add(bubble.kind);
        return defaultBubble;
      },
    );
    expect(kinds, contains(TinodeBubbleKind.voice));
  });

  testWidgets('the dot blinks while recording, and stops when paused', (
    tester,
  ) async {
    double dot() => tester
        .widget<FadeTransition>(
          find
              .descendant(
                of: find.byType(RecordingPanel),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    await openBob(tester, reduceMotion: false);
    await tester.tap(find.byTooltip('Record voice message'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 200));
    expect(dot(), lessThan(1));

    await tester.tap(find.text('Pause'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(dot(), 1);
    await tester.tap(find.byTooltip('Delete recording'));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('with Reduce motion, the dot stays still', (tester) async {
    await openBob(tester);
    await tester.tap(find.byTooltip('Record voice message'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final fade = tester.widget<FadeTransition>(
      find
          .descendant(
            of: find.byType(RecordingPanel),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
