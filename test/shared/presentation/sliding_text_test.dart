import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/sliding_text.dart';

void main() {
  const long = 'a line of text far too long for a box this narrow';

  Future<void> pump(
    WidgetTester tester,
    String text, {
    bool still = false,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: still),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 100,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: onTap,
                        child: SlidingText(text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  double offset(WidgetTester tester) => tester
      .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
      .controller!
      .offset;

  double maxOffset(WidgetTester tester) => tester
      .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
      .controller!
      .position
      .maxScrollExtent;

  testWidgets('text that fits keeps its width and never moves', (tester) async {
    await pump(tester, 'short');

    expect(tester.getSize(find.byType(SlidingText)).width, lessThan(100));
    expect(maxOffset(tester), 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('text that does not fit rests, slides to its end and back', (
    tester,
  ) async {
    await pump(tester, long);
    final end = maxOffset(tester);
    expect(end, greaterThan(0));
    expect(tester.getSize(find.byType(SlidingText)).width, 100);

    await tester.pump(const Duration(seconds: 1));
    expect(offset(tester), 0);

    final slide = Duration(milliseconds: (end / 30 * 1000).round());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(slide ~/ 2);
    expect(offset(tester), inExclusiveRange(0, end));

    await tester.pump(slide ~/ 2 + const Duration(seconds: 1));
    expect(offset(tester), moreOrLessEquals(end, epsilon: 0.5));

    await tester.pump(const Duration(seconds: 1) + slide);
    expect(offset(tester), moreOrLessEquals(0, epsilon: 0.5));
  });

  testWidgets('it stops sliding once the new text fits', (tester) async {
    await pump(tester, long);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.hasRunningAnimations, isTrue);

    await pump(tester, 'short');
    await tester.pump();

    expect(offset(tester), 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('with Reduce motion it stands still, with an ellipsis', (
    tester,
  ) async {
    await pump(tester, long, still: true);

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
    expect(
      tester.widget<Text>(find.text(long)).overflow,
      TextOverflow.ellipsis,
    );
  });

  testWidgets('tapping it reaches what is under it', (tester) async {
    var taps = 0;
    await pump(tester, long, onTap: () => taps++);

    await tester.tapAt(tester.getCenter(find.byType(SlidingText)));
    await tester.pump(kPressTimeout);

    expect(taps, 1);
  });
}
