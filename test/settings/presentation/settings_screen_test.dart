import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/presentation/home/home_tab_bar.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_screen.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/profile_screen.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/screen_header.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_section.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/pump_tinode_chat.dart';
import '../../support/test_palettes.dart';

const strings = TinodeChatStrings();

void main() {
  late FakeTinodeSession session;

  setUp(() {
    session = FakeTinodeSession()..profile = const Profile(name: 'Alice');
  });

  Future<void> openSettings(
    WidgetTester tester, {
    TinodeAppearance? appearance,
    VoidCallback? onLoggedOut,
  }) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      tabBar: true,
      appearance: appearance,
      onLoggedOut: onLoggedOut,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(HomeTabBar),
        matching: find.text(strings.settingsTitle),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the profile heads the settings and opens it', (tester) async {
    await openSettings(tester);

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text(strings.profileSubtitle), findsOneWidget);
    expect(find.text(strings.appearance), findsNothing);

    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('logging out shows the login screen and tells the host', (
    tester,
  ) async {
    var loggedOut = 0;
    await openSettings(tester, onLoggedOut: () => loggedOut++);

    await tester.tap(find.text(strings.logOut));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(loggedOut, 1);
  });

  testWidgets('the appearance names the palette in use and opens', (
    tester,
  ) async {
    final appearance = TinodeAppearance.inMemory(
      palettes: [slate, plum],
      paletteId: 'plum',
    );
    await openSettings(tester, appearance: appearance);

    expect(find.text(strings.appearance), findsOneWidget);
    expect(find.text('Plum'), findsOneWidget);

    await tester.tap(find.text(strings.appearance));
    await tester.pumpAndSettle();

    expect(find.byType(AppearanceScreen), findsOneWidget);
    expect(find.text(strings.settingsTitle), findsWidgets);
  });

  testWidgets('the cards start under the header from the first frame', (
    tester,
  ) async {
    // A 24 px status bar.
    tester.view.padding = FakeViewPadding(
      top: 24 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetPadding);
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      tabBar: true,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(HomeTabBar),
        matching: find.text(strings.settingsTitle),
      ),
    );
    await tester.pump();

    final header = find.byType(ScreenHeader);
    expect(
      tester.getSize(header).height,
      24 + tester.widget<ScreenHeader>(header).preferredSize.height,
    );
    expect(
      tester.getTopLeft(find.byType(SettingsSection).first).dy,
      tester.getBottomLeft(header).dy + 16,
    );
  });
}
