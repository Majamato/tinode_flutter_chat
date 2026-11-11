import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/confirm_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

void main() {
  const strings = TinodeChatStrings();

  void phone(WidgetTester tester, {double width = 400}) {
    final view = tester.view
      ..physicalSize = Size(width, 800)
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
  }

  /// Opens a sheet asking [message] from a button; the future completes
  /// with the answer.
  Future<Future<bool>> ask(
    WidgetTester tester, {
    String message = 'Your chats go with it.',
    Brightness brightness = Brightness.light,
  }) async {
    late Future<bool> result;
    await tester.pumpWidget(
      MaterialApp(
        theme: TinodeChatTheme.materialTheme(brightness: brightness),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => result = ConfirmSheet.ask(
                context,
                icon: Icons.delete,
                title: 'Delete it?',
                message: message,
                action: 'Delete',
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

  testWidgets('the action answers true', (tester) async {
    phone(tester);
    final result = await ask(tester);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(find.byType(ConfirmSheet), findsNothing);
  });

  testWidgets('Cancel answers false', (tester) async {
    phone(tester);
    final result = await ask(tester);

    await tester.tap(find.text(strings.cancel));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
  });

  testWidgets('a tap outside answers false', (tester) async {
    phone(tester);
    final result = await ask(tester);

    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
    expect(find.byType(ConfirmSheet), findsNothing);
  });

  testWidgets('shows the icon, the title over the message, then buttons', (
    tester,
  ) async {
    phone(tester);
    await ask(tester);
    final error = Theme.of(
      tester.element(find.text('Delete')),
    ).colorScheme.error;

    expect(tester.widget<Icon>(find.byIcon(Icons.delete)).color, error);
    final y = [
      find.byIcon(Icons.delete),
      find.text('Delete it?'),
      find.text('Your chats go with it.'),
      find.text('Delete'),
      find.text(strings.cancel),
    ].map((f) => tester.getTopLeft(f).dy).toList();
    expect(y, orderedEquals([...y]..sort()));
    expect(
      tester.getSize(find.widgetWithText(FilledButton, 'Delete')).height,
      54,
    );
  });

  testWidgets('the title is a header', (tester) async {
    phone(tester);
    final handle = tester.ensureSemantics();
    await ask(tester);

    expect(
      tester.getSemantics(find.text('Delete it?')),
      matchesSemantics(label: 'Delete it?', isHeader: true),
    );
    handle.dispose();
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'a long message scrolls above the buttons in ${brightness.name}',
      (tester) async {
        phone(tester, width: 320);
        await ask(
          tester,
          message: 'Your chats and messages go with it. ' * 30,
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Delete').hitTestable(), findsOneWidget);
        expect(find.text(strings.cancel).hitTestable(), findsOneWidget);
        expect(find.text('Delete it?').hitTestable(), findsOneWidget);
      },
    );
  }
}
