import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/video_trim.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/video_trim_bar.dart';

import '../../support/fake_attachment_picker.dart';

void main() {
  Duration s(int seconds) => Duration(seconds: seconds);

  late ValueNotifier<VideoTrim?> clip;

  Future<void> pumpBar(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: VideoTrimBar(
                  clip: clip,
                  total: s(100),
                  maxLength: s(40),
                  frames: Stream.fromIterable([pngBytes, null]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  setUp(() => clip = ValueNotifier(VideoTrim(s(0), s(40))));
  tearDown(() => clip.dispose());

  final startHandle = find.byKey(const ValueKey('trimStart'));
  final endHandle = find.byKey(const ValueKey('trimEnd'));

  testWidgets('a frame shows as it arrives, a missing one stays grey', (
    tester,
  ) async {
    await pumpBar(tester);

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('the end handle shortens it', (tester) async {
    await pumpBar(tester);

    await tester.drag(endHandle, const Offset(-80, 0));
    await tester.pump();

    expect(clip.value!.start, s(0));
    expect(clip.value!.end, lessThan(s(40)));
  });

  testWidgets("the end handle can't make it longer than the maximum", (
    tester,
  ) async {
    clip.value = VideoTrim(s(10), s(30));
    await pumpBar(tester);

    await tester.drag(endHandle, const Offset(250, 0));
    await tester.pump();

    expect(clip.value, VideoTrim(s(10), s(50)));
  });

  testWidgets('the start handle moves its start only', (tester) async {
    await pumpBar(tester);

    await tester.drag(startHandle, const Offset(60, 0));
    await tester.pump();

    expect(clip.value!.start, greaterThan(s(0)));
    expect(clip.value!.end, s(40));
  });

  testWidgets('dragging the middle moves it, keeping its length', (
    tester,
  ) async {
    await pumpBar(tester);

    final middle = tester.getCenter(startHandle) + const Offset(50, 0);
    await tester.dragFrom(middle, const Offset(100, 0));
    await tester.pump();

    expect(clip.value!.start, greaterThan(s(0)));
    expect(clip.value!.length, s(40));
  });

  testWidgets('the middle stops at the end of the video', (tester) async {
    clip.value = VideoTrim(s(0), s(40));
    await pumpBar(tester);

    final middle = tester.getCenter(startHandle) + const Offset(50, 0);
    await tester.dragFrom(middle, const Offset(800, 0));
    await tester.pump();

    expect(clip.value, VideoTrim(s(60), s(100)));
  });

  testWidgets('runs left to right in a right-to-left language', (tester) async {
    await pumpBar(tester, direction: TextDirection.rtl);

    expect(
      tester.getCenter(startHandle).dx,
      lessThan(tester.getCenter(endHandle).dx),
    );
  });

  testWidgets('the handles can be adjusted by a screen reader', (tester) async {
    clip.value = VideoTrim(s(10), s(30));
    await pumpBar(tester);

    Semantics handle(String label) => tester.widget<Semantics>(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == label,
      ),
    );

    handle('Start of the part to send').properties.onDecrease!();
    expect(clip.value, VideoTrim(s(9), s(30)));

    handle('End of the part to send').properties.onIncrease!();
    expect(clip.value, VideoTrim(s(9), s(31)));
  });
}
