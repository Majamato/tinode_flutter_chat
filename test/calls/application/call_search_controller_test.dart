import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_search.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_search_state.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/stored_calls.dart';
import '../../support/test_container.dart';

const dave = 'usrDave';
const erin = 'usrErin';
const caroline = 'usrCaroline';

void main() {
  late FakeTinodeSession session;
  late ProviderContainer container;

  Future<void> later() async {
    for (var i = 0; i < 8; i++) {
      await settle();
    }
  }

  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 200 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(done(), isTrue, reason: 'timed out');
  }

  /// 60 calls with Carol, 5 newer ones with Dave (named "Carl") and 5
  /// with Bob, newest of all.
  setUp(() async {
    final stores = await storesWithCalls([
      for (var seq = 1; seq <= 60; seq++) callMessage(carol, seq),
      for (var seq = 1; seq <= 5; seq++)
        callMessage(dave, seq, time: at(100 + seq)),
      for (var seq = 1; seq <= 5; seq++)
        callMessage(bob, seq, time: at(200 + seq)),
    ]);
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob Núñez', lastSeq: 5, lastMessageAt: at(205)),
        chat(carol, name: 'Carol', lastSeq: 60, lastMessageAt: at(60)),
        chat(dave, name: 'Carl', lastSeq: 5, lastMessageAt: at(105)),
        // No calls yet.
        chat(erin, name: 'Erin'),
        chat(caroline, name: 'Caroline'),
      ],
    );
    container = (await loggedInContainer(session, storeOpener: stores))
      ..listen(chatListControllerProvider, (_, _) {})
      ..listen(callSearchControllerProvider, (_, _) {});
    await later();
  });

  CallSearchState search() => container.read(callSearchControllerProvider);

  CallSearchController notifier() =>
      container.read(callSearchControllerProvider.notifier);

  List<String> topics() => [for (final id in search().ids) id.topic];

  test('opens on every call, newest first, a page at a time', () async {
    await until(() => search().loaded);

    expect(search().ids, hasLength(callPageSize));
    expect(search().ids.first, (topic: bob, seq: 5));
    expect(search().hasMore, isTrue);

    await notifier().loadMore();
    expect(search().ids, hasLength(70));
    expect(search().hasMore, isFalse);
  });

  test('shows the exact matches across pages, then a letter off', () async {
    await until(() => search().loaded);
    notifier().search('carol');
    await until(() => search().matches.exact?.length == 1);

    expect(search().matches.exact, {carol});
    expect(search().matches.typos, {dave});
    expect(topics(), List.filled(callPageSize, carol));
    expect(search().ids.first, (topic: carol, seq: 60));

    await notifier().loadMore();
    expect(search().ids, hasLength(65));
    expect(search().ids[59], (topic: carol, seq: 1));
    expect(topics().skip(60), List.filled(5, dave));
    expect(search().hasMore, isFalse);
  });

  test('answers only the latest input', () async {
    await until(() => search().loaded);
    notifier()
      ..search('bob')
      ..search('carl');
    await later();

    expect(search().matches.exact, {dave});
    expect(search().matches.typos, {carol});
    expect(topics().first, dave);
  });

  test('a found call that changes shows the change', () async {
    await until(() => search().loaded);
    notifier().search('carol');
    await until(() => search().matches.exact?.length == 1);

    session.emitMessage(callUpdate(carol, 61, 55, CallState.missed));
    await later();

    expect(search()[(topic: carol, seq: 55)]?.call.state, CallState.missed);
    expect(search().ids, hasLength(callPageSize));
  });

  group('a chat with no calls yet', () {
    Future<void> searchCarolToTheEnd() async {
      await until(() => search().loaded);
      notifier().search('carol');
      await until(() => search().matches.exact?.length == 1);
      await notifier().loadMore();
      expect(search().ids, hasLength(65));
    }

    test('that gets a message keeps the pages read', () async {
      await searchCarolToTheEnd();

      session.emitMessage(message(erin, 1, from: erin));
      await later();

      expect(search().ids, hasLength(65));
    });

    test('that gets a call it matches searches again', () async {
      await searchCarolToTheEnd();

      session.emitMessage(callMessage(caroline, 1, time: at(300)));
      await later();

      expect(search().matches.exact, {carol, caroline});
      expect(search().ids.first, (topic: caroline, seq: 1));
      expect(search().ids, hasLength(callPageSize));
    });
  });

  test('never asks the server', () async {
    await until(() => search().loaded);
    notifier().search('nunez');
    await later();

    expect(topics(), List.filled(5, bob));
    expect(session.calls.where((c) => c.startsWith('find ')), isEmpty);
  });
}
