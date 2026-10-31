import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_screen.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/palette_swatch.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/palette_swatch_grid.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/pump_tinode_chat.dart';
import '../../support/test_palettes.dart';

const strings = TinodeChatStrings();

void main() {
  late FakeTinodeSession session;
  late TinodeAppearance appearance;

  setUp(() {
    session = FakeTinodeSession();
    appearance = TinodeAppearance.inMemory(palettes: [slate, plum]);
  });

  /// Opens the appearance screen from the chat list's menu, as a host
  /// without the tab bar has it.
  Future<void> open(
    WidgetTester tester, {
    Widget? extra,
    bool reduceMotion = true,
  }) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      appearance: appearance,
      appearanceExtra: extra,
      reduceMotion: reduceMotion,
    );
    await tester.tap(find.byType(PopupMenuButton<void>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.appearance));
    await tester.pumpAndSettle();
    expect(find.byType(AppearanceScreen), findsOneWidget);
  }

  bool selected(WidgetTester tester, String label) => tester
      .widget<PaletteSwatch>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(PaletteSwatch),
        ),
      )
      .selected;

  testWidgets('a swatch picks its palette, and the preview names it', (
    tester,
  ) async {
    await open(tester);

    expect(find.text(strings.chatListTitle), findsWidgets);
    expect(selected(tester, 'Slate'), isTrue);
    expect(find.text(strings.appearancePreviewAnswer('Slate')), findsOneWidget);

    await tester.tap(find.text('Plum'));
    await tester.pumpAndSettle();

    expect(appearance.palette, plum);
    expect(selected(tester, 'Plum'), isTrue);
    expect(selected(tester, 'Slate'), isFalse);
    expect(find.text(strings.appearancePreviewAnswer('Plum')), findsOneWidget);
  });

  testWidgets('the theme switch picks light, dark or system', (tester) async {
    await open(tester);

    await tester.tap(find.text(strings.themeDark));
    await tester.pumpAndSettle();

    expect(appearance.themeMode, ThemeMode.dark);
  });

  testWidgets('reset brings back the default palette', (tester) async {
    await open(tester);
    final reset = find.widgetWithText(
      TextButton,
      strings.resetPalette('Slate'),
    );
    expect(tester.widget<TextButton>(reset).onPressed, isNull);

    appearance.selectPalette('plum');
    await tester.pumpAndSettle();
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();

    expect(appearance.palette, slate);
  });

  testWidgets("the host's own setting shows on the screen", (tester) async {
    await open(tester, extra: const Text('Text size'));

    expect(find.text('Text size'), findsOneWidget);
  });

  testWidgets('one palette leaves only the theme', (tester) async {
    appearance = TinodeAppearance.inMemory(palettes: [slate]);
    await open(tester);

    expect(find.byType(PaletteSwatchGrid), findsNothing);
    expect(find.text(strings.resetPalette('Slate')), findsNothing);
    expect(find.text(strings.themeSystem), findsOneWidget);
  });

  testWidgets('the answer pops in again from its tail', (tester) async {
    await open(tester, reduceMotion: false);
    final answer = find.text(strings.appearancePreviewAnswer('Plum'));

    await tester.tap(find.text('Plum'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final transition = tester.widget<ScaleTransition>(
      find.ancestor(of: answer, matching: find.byType(ScaleTransition)).first,
    );
    expect(transition.scale.value, lessThan(1));

    await tester.pump(const Duration(milliseconds: 400));
    expect(transition.scale.value, 1);
  });
}
