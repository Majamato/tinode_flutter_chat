import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

void main() {
  /// Shows [button] on a screen pushed over a first one.
  Future<void> pumpOnRoute(
    WidgetTester tester,
    TinodeBackButton button, {
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TinodeChatTheme.materialTheme(brightness: brightness),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: TinodeAppBar(leading: button),
                  body: const SizedBox.expand(),
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Finder chevron() => find.byIcon(const TinodeChatIcons().back);

  Color iconColor(WidgetTester tester) => tester.widget<Icon>(chevron()).color!;

  testWidgets('names the screen it goes back to, in the link colour', (
    tester,
  ) async {
    await pumpOnRoute(tester, const TinodeBackButton(label: Text('Settings')));

    expect(find.text('Settings'), findsOneWidget);
    expect(chevron(), findsOneWidget);
    final context = tester.element(find.text('Settings'));
    final link = TinodeChatTheme.of(context).linkColor;
    expect(iconColor(tester), link);
    expect(DefaultTextStyle.of(context).style.color, link);
    expect(tester.getSize(find.byType(TinodeBackButton)).height, 44);
  });

  testWidgets('without a label it is the chevron, as wide as it is tall', (
    tester,
  ) async {
    await pumpOnRoute(tester, const TinodeBackButton());

    expect(chevron(), findsOneWidget);
    expect(tester.getSize(find.byType(TinodeBackButton)), const Size(44, 44));
  });

  testWidgets('a badge follows the chevron', (tester) async {
    await pumpOnRoute(tester, const TinodeBackButton(badge: Text('3')));

    expect(
      tester.getTopLeft(find.text('3')).dx,
      greaterThanOrEqualTo(tester.getTopRight(chevron()).dx),
    );
  });

  testWidgets('a tap pops the route', (tester) async {
    await pumpOnRoute(tester, const TinodeBackButton(label: Text('Settings')));

    await tester.tap(find.byType(TinodeBackButton));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.byType(TinodeBackButton), findsNothing);
  });

  testWidgets('reads as a button called Back by default', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpOnRoute(tester, const TinodeBackButton(label: Text('Settings')));

    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.bySemanticsLabel('Settings'), findsNothing);
    semantics.dispose();
  });

  testWidgets('reads as its tooltip when it has one', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpOnRoute(tester, const TinodeBackButton(tooltip: 'Back to chats'));

    expect(find.bySemanticsLabel('Back to chats'), findsOneWidget);
    expect(find.byTooltip('Back to chats'), findsOneWidget);
    semantics.dispose();
  });

  for (final brightness in Brightness.values) {
    testWidgets('a long name stays within 45 % of a phone, '
        '${brightness.name} theme', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpOnRoute(
        tester,
        const TinodeBackButton(
          label: Text('A group whose name goes on for far too long'),
        ),
        brightness: brightness,
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(TinodeBackButton)).width,
        lessThanOrEqualTo(360 * 0.45),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, startsWith('A group'));
      final style = DefaultTextStyle.of(tester.element(find.byType(Text)));
      expect(style.maxLines, 1);
      expect(style.overflow, TextOverflow.ellipsis);
    });
  }
}
