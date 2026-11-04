import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/pump_tinode_chat.dart';

void main() {
  late FakeTinodeSession session;

  setUp(() => session = FakeTinodeSession());

  testWidgets('shows the texts of the app locale', (tester) async {
    await pumpTinodeChat(tester, session, locale: const Locale('fr'));

    const french = TinodeChatStrings.fr();
    expect(find.text(french.loginHeadline), findsOneWidget);
    expect(find.text(french.signUpTab), findsOneWidget);
    expect(find.text(const TinodeChatStrings().loginHeadline), findsNothing);
  });

  testWidgets('keeps English when the app locale is English', (tester) async {
    await pumpTinodeChat(tester, session, locale: const Locale('en'));

    expect(find.text(const TinodeChatStrings().loginHeadline), findsOneWidget);
  });

  testWidgets('switches language when the app locale changes', (tester) async {
    await pumpTinodeChat(tester, session, locale: const Locale('es'));
    expect(
      find.text(const TinodeChatStrings.es().loginHeadline),
      findsOneWidget,
    );

    await pumpTinodeChat(tester, session, locale: const Locale('fr'));
    expect(
      find.text(const TinodeChatStrings.fr().loginHeadline),
      findsOneWidget,
    );
  });
}
