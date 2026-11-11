import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/voice_waveform.dart';

void main() {
  /// 42 bars of 2 px, 2 px apart (166 px), between 6 px insets.
  const width = 178.0;
  const length = Duration(seconds: 4);

  late List<double> seeks;

  setUp(() => seeks = []);

  Future<void> pumpWaveform(
    WidgetTester tester, {
    double progress = 0,
    bool playing = false,
    double speed = 1,
  }) => tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: VoiceWaveform(
            waveform: [for (var i = 0; i < 96; i++) i],
            progress: progress,
            duration: length,
            playing: playing,
            speed: speed,
            playedColor: Colors.white,
            unplayedColor: Colors.grey,
            onSeek: seeks.add,
          ),
        ),
      ),
    ),
  );

  VoiceWaveformState state(WidgetTester tester) =>
      tester.state<VoiceWaveformState>(find.byType(VoiceWaveform));

  double head(WidgetTester tester) => state(tester).head.value;

  test('as many bars as fit the width', () {
    expect(VoiceWaveform.barCountFor(width), 45);
    expect(VoiceWaveform.widthOf(45), width);
    expect(VoiceWaveform.barCountFor(1), 0);
  });

  testWidgets('a tap on the insets seeks to the ends', (tester) async {
    await pumpWaveform(tester);
    final start = tester.getTopLeft(find.byType(VoiceWaveform));
    await tester.tapAt(start + const Offset(2, 12));
    await tester.pump();
    await tester.tapAt(start + const Offset(width - 2, 12));
    await tester.pump();
    expect(seeks, [0, 1]);
  });

  testWidgets('the dot grows while playing and rests small', (tester) async {
    await pumpWaveform(tester);
    expect(state(tester).dotSize, VoiceWaveform.restingDotSize);

    await pumpWaveform(tester, playing: true);
    await tester.pump(const Duration(seconds: 1));
    expect(state(tester).dotSize, VoiceWaveform.dotSize);

    await pumpWaveform(tester, progress: 0.2);
    await tester.pump(const Duration(seconds: 1));
    expect(state(tester).dotSize, VoiceWaveform.restingDotSize);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a drag grows the resting dot', (tester) async {
    await pumpWaveform(tester);
    final start = tester.getTopLeft(find.byType(VoiceWaveform));
    final gesture = await tester.startGesture(start + const Offset(20, 12));
    await gesture.moveTo(start + const Offset(60, 12));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(state(tester).dotSize, VoiceWaveform.dotSize);

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(state(tester).dotSize, VoiceWaveform.restingDotSize);
  });

  testWidgets('while playing, the dot waits for the audio to move, then '
      'glides between reports', (tester) async {
    await pumpWaveform(tester, playing: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(head(tester), 0);

    // 200 ms in: the audio has started.
    await pumpWaveform(tester, progress: 0.05, playing: true);
    expect(head(tester), 0.05);
    await tester.pump(const Duration(milliseconds: 500));
    expect(head(tester), closeTo(0.175, 0.01));
    await tester.pump(const Duration(milliseconds: 16));
    expect(head(tester), greaterThan(0.175));
  });

  testWidgets('at twice the speed, the dot glides twice as fast', (
    tester,
  ) async {
    await pumpWaveform(tester, playing: true, speed: 2);
    await tester.pump();
    await pumpWaveform(tester, progress: 0.05, playing: true, speed: 2);
    await tester.pump(const Duration(milliseconds: 500));
    expect(head(tester), closeTo(0.3, 0.01));
  });

  testWidgets('a speed change while gliding goes on from where the dot is', (
    tester,
  ) async {
    await pumpWaveform(tester, playing: true);
    await tester.pump();
    await pumpWaveform(tester, progress: 0.05, playing: true);
    await tester.pump(const Duration(milliseconds: 500));
    expect(head(tester), closeTo(0.175, 0.01));

    await pumpWaveform(tester, progress: 0.05, playing: true, speed: 2);
    expect(head(tester), closeTo(0.175, 0.01));
    await tester.pump(const Duration(milliseconds: 500));
    expect(head(tester), closeTo(0.425, 0.01));
  });

  testWidgets('while playing, a report behind slows the dot down until '
      'the audio catches up, never stepping back', (tester) async {
    await pumpWaveform(tester, playing: true);
    await tester.pump();
    await pumpWaveform(tester, progress: 0.05, playing: true);
    await tester.pump(const Duration(seconds: 1));
    final before = head(tester);
    expect(before, closeTo(0.3, 0.01));

    // 200 ms behind the dot, half the catch-up: it goes at half speed.
    final behind = before - 0.05;
    await pumpWaveform(tester, progress: behind, playing: true);
    expect(head(tester), before);
    await tester.pump(const Duration(milliseconds: 100));
    expect(head(tester), closeTo(before + 0.0125, 0.001));

    // Frame by frame, it eases back onto the audio.
    var last = head(tester);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(head(tester), greaterThan(last));
      last = head(tester);
    }
    final audio = behind + (100 + 60 * 16) / 4000;
    expect(head(tester) - audio, inInclusiveRange(0, 0.004));

    // Ahead of it: it jumps there.
    await pumpWaveform(tester, progress: 0.75, playing: true);
    expect(head(tester), 0.75);
  });

  testWidgets('while playing, a report far behind makes the dot wait', (
    tester,
  ) async {
    await pumpWaveform(tester, playing: true);
    await tester.pump();
    await pumpWaveform(tester, progress: 0.05, playing: true);
    await tester.pump(const Duration(seconds: 1));
    final before = head(tester);

    // 600 ms behind, past the catch-up: it stands while the audio is 400 ms
    // or more behind, then moves on as it nears.
    await pumpWaveform(tester, progress: before - 0.15, playing: true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(head(tester), before);
    await tester.pump(const Duration(milliseconds: 100));
    expect(head(tester), before);
    await tester.pump(const Duration(milliseconds: 100));
    expect(head(tester), before);
    await tester.pump(const Duration(milliseconds: 100));
    expect(head(tester), greaterThan(before));
  });

  testWidgets('a tap back while playing moves the dot there at once, and it '
      'waits for the audio', (tester) async {
    await pumpWaveform(tester, playing: true);
    await tester.pump();
    await pumpWaveform(tester, progress: 0.05, playing: true);
    await tester.pump(const Duration(seconds: 1));
    expect(head(tester), closeTo(0.3, 0.01));

    await tester.tapAt(
      tester.getTopLeft(find.byType(VoiceWaveform)) + const Offset(47.5, 12),
    );
    await tester.pump();
    expect(seeks, [closeTo(0.25, 0.001)]);
    expect(head(tester), closeTo(0.25, 0.001));

    // The controller shows the target until the seek lands.
    await pumpWaveform(tester, progress: seeks.single, playing: true);
    await tester.pump(const Duration(milliseconds: 500));
    expect(head(tester), closeTo(0.25, 0.001));

    await pumpWaveform(tester, progress: 0.26, playing: true);
    await tester.pump(const Duration(milliseconds: 400));
    expect(head(tester), closeTo(0.36, 0.01));
  });

  testWidgets('paused, the dot stays put and nothing ticks', (tester) async {
    await pumpWaveform(tester, playing: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await pumpWaveform(tester, progress: 0.12);
    final paused = head(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(head(tester), paused);
    expect(tester.hasRunningAnimations, isFalse);

    // Stopped: back to the start.
    await pumpWaveform(tester);
    expect(head(tester), 0);
  });

  testWidgets('a drag moves the dot and seeks once, when it ends', (
    tester,
  ) async {
    await pumpWaveform(tester, playing: true);
    final start = tester.getTopLeft(find.byType(VoiceWaveform));
    final gesture = await tester.startGesture(start + const Offset(20, 12));
    for (var x = 30.0; x <= 89; x += 10) {
      await gesture.moveTo(start + Offset(x, 12));
      await tester.pump();
    }
    await gesture.moveTo(start + const Offset(89, 12));
    await tester.pump();
    expect(head(tester), closeTo(0.5, 0.001));
    expect(seeks, isEmpty);

    await gesture.up();
    await tester.pump();
    expect(seeks, [closeTo(0.5, 0.001)]);
  });

  testWidgets('a tap seeks once', (tester) async {
    await pumpWaveform(tester);
    await tester.tapAt(
      tester.getTopLeft(find.byType(VoiceWaveform)) + const Offset(47.5, 12),
    );
    await tester.pump();
    expect(seeks, [closeTo(0.25, 0.001)]);
    expect(head(tester), closeTo(0.25, 0.001));
  });
}
