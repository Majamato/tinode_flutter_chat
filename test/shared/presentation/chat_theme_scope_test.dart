import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/chat_theme_scope.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

void main() {
  Future<void> pump(WidgetTester tester, ThemeData theme) => tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: ChatThemeScope(
        child: Scaffold(
          body: Column(
            children: [
              const Icon(Icons.star),
              IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
              const IconButton(onPressed: null, icon: Icon(Icons.close)),
            ],
          ),
        ),
      ),
    ),
  );

  TextStyle glyph(WidgetTester tester, IconData icon) => tester
      .widget<RichText>(
        find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
      )
      .text
      .style!;

  ThemeData themeBelow(WidgetTester tester) =>
      Theme.of(tester.element(find.byIcon(Icons.star)));

  final hostTheme = TinodeChatTheme.materialTheme();

  testWidgets('an icon defaults to the icon colour at 24', (tester) async {
    await pump(tester, hostTheme);

    final style = glyph(tester, Icons.star);
    expect(
      style.color,
      TinodeChatTheme.of(tester.element(find.byIcon(Icons.star))).iconColor,
    );
    expect(style.fontSize, 24);
  });

  testWidgets('an icon button defaults to the icon colour at 24', (
    tester,
  ) async {
    await pump(tester, hostTheme);

    final style = glyph(tester, Icons.add);
    expect(
      style.color,
      TinodeChatTheme.of(tester.element(find.byIcon(Icons.add))).iconColor,
    );
    expect(style.fontSize, 24);
  });

  testWidgets('a disabled icon button fades to 38 %', (tester) async {
    await pump(tester, hostTheme);

    expect(
      glyph(tester, Icons.close).color,
      themeBelow(tester).colorScheme.onSurface.withValues(alpha: 0.38),
    );
  });

  testWidgets('a host theme without the extension gets the fallback', (
    tester,
  ) async {
    final plain = ThemeData.light();
    await pump(tester, plain);

    final chat = themeBelow(tester).extension<TinodeChatTheme>();
    expect(chat, isNotNull);
    expect(glyph(tester, Icons.star).color, plain.colorScheme.onSurface);
  });

  testWidgets('a host theme keeps its own extension', (tester) async {
    await pump(tester, hostTheme);

    expect(
      themeBelow(tester).extension<TinodeChatTheme>(),
      hostTheme.extension<TinodeChatTheme>(),
    );
  });
}
