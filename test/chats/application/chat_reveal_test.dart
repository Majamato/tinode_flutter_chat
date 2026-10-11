import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_reveal.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;
  late ProviderContainer container;

  setUp(() async {
    session = FakeTinodeSession(
      chats: [chat(bob, name: 'Bob', lastSeq: 100, lastMessageAt: at(100))],
      histories: {
        bob: [for (var seq = 1; seq <= 100; seq++) message(bob, seq)],
      },
    );
    container = await loggedInContainer(session)
      ..listen(chatListControllerProvider, (_, _) {});
    await settle();
  });

  ChatController openChat() {
    container.listen(chatControllerProvider(bob), (_, _) {});
    return container.read(chatControllerProvider(bob).notifier);
  }

  ChatState chatState() => container.read(chatControllerProvider(bob));

  test('a loaded message shows at once', () async {
    final chat = openChat();
    await settle();

    await chat.reveal(90);

    expect(
      chatState().reveal,
      const MessageReveal(90, status: RevealStatus.shown),
    );
    expect(chatState().reveal!.highlights(90), isTrue);
    expect(chatState().reveal!.highlights(91), isFalse);
  });

  test('loads back to an older message, from the server', () async {
    final chat = openChat();
    await settle();
    expect(chatState().firstSeq, 100 - historyPageSize + 1);

    await chat.reveal(10);

    expect(chatState().reveal?.status, RevealStatus.shown);
    expect(chatState().bySeq, contains(10));
    // The page went back to the first message.
    expect(chatState().seqs.first, 1);
    expect(chatState().hasOlder, isFalse);
  });

  test('waits for the chat to load', () async {
    final hold = session.holdHistory = Completer();
    final chat = openChat();
    unawaited(chat.reveal(80));
    await settle();
    expect(chatState().reveal?.status, RevealStatus.loading);

    hold.complete();
    await settle();
    await settle();

    expect(chatState().reveal?.status, RevealStatus.shown);
  });

  test('offline, a message that is not cached is unavailable', () async {
    final chat = openChat();
    await settle();
    session.emitStatus(
      const Reconnecting(attempt: 1, retryIn: Duration(seconds: 1)),
    );

    await chat.reveal(10);

    expect(chatState().reveal?.status, RevealStatus.unavailable);
  });

  test('a deleted message is unavailable', () async {
    session.histories[bob]!.removeWhere((m) => m.seq == 95);
    final chat = openChat();
    await settle();

    await chat.reveal(95);

    expect(chatState().reveal?.status, RevealStatus.unavailable);
  });

  test('the highlight goes after a while', () async {
    final chat = openChat();
    await settle();
    await chat.reveal(99);

    await Future<void>.delayed(
      revealHighlight + const Duration(milliseconds: 50),
    );

    expect(chatState().reveal, isNull);
  });
}
