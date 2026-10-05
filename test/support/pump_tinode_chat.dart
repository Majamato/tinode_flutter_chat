import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import 'fake_tinode_session.dart';
import 'test_container.dart';

/// Pumps a [TinodeChat] in a `MaterialApp`, connected to [session].
Future<void> pumpTinodeChat(
  WidgetTester tester,
  FakeTinodeSession session, {
  TinodeCredentials? credentials,
  ValueChanged<LoginResult>? onLoggedIn,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TinodeChat.withConnector(
        config: testConfig,
        connector: connectTo(session),
        credentials: credentials,
        onLoggedIn: onLoggedIn,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
