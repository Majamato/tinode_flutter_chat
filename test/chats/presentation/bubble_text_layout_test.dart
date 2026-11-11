import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_text_layout.dart';

/// In the test font every glyph is a square of the font size: 10 px here,
/// so 20 glyphs fill the 200 px width.
void main() {
  const footer = SizedBox(key: Key('footer'), width: 40, height: 8);

  Future<Size> layOut(WidgetTester tester, String text) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200,
            child: Align(
              alignment: Alignment.topLeft,
              child: BubbleTextLayout(
                text: Text(text, style: const TextStyle(fontSize: 10)),
                footer: footer,
              ),
            ),
          ),
        ),
      ),
    );
    return tester.getSize(find.byType(BubbleTextLayout));
  }

  testWidgets('the footer follows a short last line, hanging below it', (
    tester,
  ) async {
    final size = await layOut(tester, 'hi');
    expect(size.height, 10 + RenderBubbleTextLayout.drop);
    expect(size.width, 20 + RenderBubbleTextLayout.gap + 40);
    expect(
      tester.getBottomRight(find.byKey(const Key('footer'))).dy,
      10 + RenderBubbleTextLayout.drop,
    );
  });

  testWidgets('the footer takes a line of its own after a full one', (
    tester,
  ) async {
    final size = await layOut(tester, 'x' * 20);
    expect(size.height, 10 + 8);
    expect(tester.getTopLeft(find.byKey(const Key('footer'))).dy, 10);
    expect(tester.getTopRight(find.byKey(const Key('footer'))).dx, 200);
  });
}
