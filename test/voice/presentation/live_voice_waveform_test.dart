import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/live_voice_waveform.dart';

void main() {
  late StreamController<double> levels;

  setUp(() => levels = StreamController<double>.broadcast());
  tearDown(() => levels.close());

  Future<void> pump(
    WidgetTester tester, {
    List<double> initial = const [],
    bool running = true,
    bool reduceMotion = false,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            child: LiveVoiceWaveform(
              initial: initial,
              levels: levels.stream,
              running: running,
              color: const Color(0xFF888888),
            ),
          ),
        ),
      ),
    ),
  );

  LiveVoiceWaveformState state(WidgetTester tester) =>
      tester.state(find.byType(LiveVoiceWaveform));

  testWidgets('starts from the levels so far, the newest last', (tester) async {
    await pump(tester, initial: [-50, -25, 0]);
    expect(state(tester).bars, [0, 0.5, 1]);
  });

  testWidgets('adds each level on a fixed scale: a loud one resizes none', (
    tester,
  ) async {
    await pump(tester);
    levels.add(-25);
    await tester.pump();
    levels.add(0);
    await tester.pump();
    levels.add(-40);
    await tester.pump();
    expect(state(tester).bars, [0.5, 1, closeTo(0.2, 1e-9)]);
  });

  testWidgets('keeps at most its capacity', (tester) async {
    await pump(
      tester,
      initial: List.filled(LiveVoiceWaveform.capacity + 10, -25),
    );
    expect(state(tester).bars, hasLength(LiveVoiceWaveform.capacity));
  });

  testWidgets('the newest bar glides in over one sample interval', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump(const Duration(milliseconds: 16));
    levels.add(-10);
    await tester.pump();
    expect(state(tester).slide, lessThan(0.5));
    await tester.pump(const Duration(milliseconds: 50));
    expect(state(tester).slide, closeTo(0.5, 0.2));
    await tester.pump(const Duration(milliseconds: 100));
    expect(state(tester).slide, 1);
  });

  testWidgets('stopped, the ticker stops and bars step', (tester) async {
    await pump(tester);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await pump(tester, running: false);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    levels.add(-10);
    await tester.pump();
    expect(state(tester).slide, 1);
    expect(state(tester).bars, hasLength(1));
  });

  testWidgets('with Reduce motion, no ticker', (tester) async {
    await pump(tester, reduceMotion: true);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    levels.add(-10);
    await tester.pump();
    expect(state(tester).slide, 1);
  });

  testWidgets('hidden from screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, initial: [-20]);
    expect(
      find.descendant(
        of: find.byType(LiveVoiceWaveform),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
