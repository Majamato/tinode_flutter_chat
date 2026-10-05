import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

void main() {
  testWidgets('a message in the top chat rebuilds only its time and badge', (
    tester,
  ) async {
    final session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 2, read: 2, lastMessageAt: at(2)),
        chat(carol, name: 'Carol', lastSeq: 1, read: 1, lastMessageAt: at(1)),
      ],
    );
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );

    final rebuilt = <String>[];
    debugOnRebuildDirtyWidget = (element, _) =>
        rebuilt.add(element.widget.runtimeType.toString());
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    session.emitPresence(
      const PresMessage(
        topic: 'me',
        event: PresenceEvent.message,
        source: bob,
        seq: 3,
      ),
    );
    await tester.pump();

    expect(
      rebuilt.where((w) => w.startsWith('Chat')),
      unorderedEquals(['ChatLastMessageTime', 'ChatUnreadBadge']),
    );
    expect(find.text('1'), findsOneWidget);
  });
}
