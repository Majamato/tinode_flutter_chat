import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet_action.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
          ..physicalSize = const Size(400, 800)
          ..devicePixelRatio = 1;
    addTearDown(view.reset);
  });

  /// Opens [sheet] from a button; the future completes with what it pops.
  Future<Future<String?>> open(WidgetTester tester, Widget sheet) async {
    late Future<String?> result;
    await tester.pumpWidget(
      MaterialApp(
        theme: TinodeChatTheme.materialTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => result = showChatSheet<String>(
                context,
                builder: (_) => sheet,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  Widget action(String label, {Color? tint, bool destructive = false}) =>
      Builder(
        builder: (context) => ChatSheetAction(
          icon: Icons.star,
          label: label,
          tint: tint,
          destructive: destructive,
          onTap: () => Navigator.of(context).pop(label),
        ),
      );

  testWidgets('is a docked Material sheet with a drag handle', (tester) async {
    await open(tester, ChatSheet(children: [action('One')]));

    final screen = tester.getSize(find.byType(MaterialApp));
    final sheet = tester.getRect(find.byType(BottomSheet));
    expect(sheet.left, 0);
    expect(sheet.right, screen.width);
    expect(sheet.bottom, screen.height);
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle,
      isTrue,
    );
  });

  testWidgets('a tap on a row pops with its value', (tester) async {
    final result = await open(
      tester,
      ChatSheet(children: [action('One'), action('Two')]),
    );

    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();

    expect(await result, 'Two');
    expect(find.byType(ChatSheet), findsNothing);
  });

  testWidgets('a row takes its tint; a destructive one the error colour', (
    tester,
  ) async {
    await open(
      tester,
      ChatSheet(
        children: [
          action('Keep', tint: Colors.teal),
          action('Delete', destructive: true),
        ],
      ),
    );
    final error = Theme.of(
      tester.element(find.text('Delete')),
    ).colorScheme.error;
    final icons = tester.widgetList<Icon>(find.byIcon(Icons.star)).toList();

    expect(icons.first.color, Colors.teal);
    expect(icons.last.color, error);
    expect(tester.widget<Text>(find.text('Delete')).style?.color, error);
    expect(tester.widget<Text>(find.text('Keep')).style?.color, isNot(error));
  });

  testWidgets('shows a title over its rows', (tester) async {
    await open(tester, ChatSheet(title: 'Read by', children: [action('One')]));

    expect(
      tester.getTopLeft(find.text('Read by')).dy,
      lessThan(tester.getTopLeft(find.text('One')).dy),
    );
  });

  testWidgets('scrolls a list taller than the sheet may be', (tester) async {
    await open(
      tester,
      ChatSheet(
        title: 'Many',
        children: [for (var i = 0; i < 40; i++) action('Row $i')],
      ),
    );

    expect(find.text('Row 39').hitTestable(), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Row 39'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Row 39').hitTestable(), findsOneWidget);
  });
}
