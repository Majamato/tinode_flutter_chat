import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/sliding_segments.dart';

void main() {
  const pill = Color(0xFF000002);
  const label = Color(0xFF000003);
  const selectedLabel = Color(0xFF000004);

  Future<List<int>> pump(WidgetTester tester, int selected) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SlidingSegments(
                segments: const [(0, 'Light'), (1, 'Dark'), (2, 'System')],
                selected: selected,
                onChanged: taps.add,
                height: 46,
                radius: 16,
                trackColor: const Color(0xFF000001),
                pillColor: pill,
                labelColor: label,
                selectedLabelColor: selectedLabel,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return taps;
  }

  Rect pillRect(WidgetTester tester) => tester.getRect(
    find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == pill,
    ),
  );

  Color colorOf(WidgetTester tester, String text) => tester
      .widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text(text),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      )
      .style
      .color!;

  testWidgets('the pill sits under the selected segment', (tester) async {
    await pump(tester, 1);

    final pillBox = pillRect(tester);
    expect(
      pillBox.center.dx,
      closeTo(tester.getCenter(find.text('Dark')).dx, 1),
    );
    expect(pillBox.width, closeTo((300 - 8) / 3, 0.5));
    expect(colorOf(tester, 'Dark'), selectedLabel);
    expect(colorOf(tester, 'Light'), label);

    await pump(tester, 2);

    expect(
      pillRect(tester).center.dx,
      closeTo(tester.getCenter(find.text('System')).dx, 1),
    );
  });

  testWidgets('a tap picks another segment, never the selected one', (
    tester,
  ) async {
    final taps = await pump(tester, 0);

    await tester.tap(find.text('Light'));
    await tester.tap(find.text('System'));

    expect(taps, [2]);
  });

  testWidgets('screen readers hear which segment is selected', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, 0);

    expect(
      tester.getSemantics(find.text('Light')),
      matchesSemantics(
        label: 'Light',
        isButton: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
        hasSelectedState: true,
      ),
    );
    semantics.dispose();
  });
}
