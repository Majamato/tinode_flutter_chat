import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/captioned_attachments.dart';

/// In the test font every glyph is a square of the font size, so a caption
/// is 16 px per glyph in `bodyLarge`.
void main() {
  const photo = Key('photo');
  const footer = Key('footer');

  Future<void> layOut(
    WidgetTester tester, {
    required String caption,
    bool media = true,
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: CaptionedAttachments(
              caption: caption,
              media: media,
              color: Colors.black,
              footer: const SizedBox(key: footer, width: 40, height: 8),
              attachments: const [
                SizedBox(key: photo, width: 248, height: 100),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Rect rectOf(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

  testWidgets('a short caption under a photo has its footer at the end edge', (
    tester,
  ) async {
    await layOut(tester, caption: 'Hi');
    expect(rectOf(tester, footer).right, rectOf(tester, photo).right - 8);
  });

  testWidgets('a short caption under a file has its footer at the end edge', (
    tester,
  ) async {
    await layOut(tester, caption: 'Hi', media: false);
    expect(rectOf(tester, footer).right, rectOf(tester, photo).right);
  });

  testWidgets('right to left, the footer sits at the left edge', (
    tester,
  ) async {
    await layOut(tester, caption: 'Hi', direction: TextDirection.rtl);
    expect(rectOf(tester, footer).left, rectOf(tester, photo).left + 8);
  });

  testWidgets('a caption wider than the photo widens the body', (tester) async {
    await layOut(tester, caption: 'x' * 20);
    final body = tester.getRect(find.byType(CaptionedAttachments));
    expect(body.width, greaterThan(248));
    expect(rectOf(tester, footer).right, body.right - 8);
  });
}
