# Testing

## Layout

`test/` mirrors `lib/src/`: the tests for `lib/src/chats/domain/chat_state.dart` live in
`test/chats/domain/chat_state_test.dart`. On top of that:

| Folder | Holds |
|--------|-------|
| `test/support/` | `FakeTinodeSession`, fixtures, container and widget helpers |
| `test/architecture/` | Rules on the code itself: layer imports, one widget per file, no providers in widgets |
| `test/integration/` | Tests against a real Tinode server, tagged `integration` |

## Kinds of tests

| Kind | Tests | Tools |
|------|-------|-------|
| Domain | Pure rules: merging, counters, ordering, identity of unchanged state | plain `test` |
| Application | Providers with a fake session: loading, live updates, errors, lifecycle | `createTestContainer`, `loggedInContainer` |
| Data | `ClientTinodeSession` over an in-memory WebSocket; `ChatStore` and `CachedTinodeSession` over an in-memory SQLite | `package:web_socket/testing.dart` `fakes()`, `NativeDatabase.memory()` |
| Widget | Screens and flows through `TinodeChat`, rebuild scope | `pumpTinodeChat`, `testWidgets` |
| Integration | The real client against a real server | `@Tags(['integration'])` |

## The fake session

`FakeTinodeSession` implements `TinodeSession` at model level, so tests read like the protocol
without JSON:

```dart
final session = FakeTinodeSession(
  chats: [chat(bob, name: 'Bob', lastSeq: 2, read: 1)],
  histories: {bob: [message(bob, 1), message(bob, 2)]},
);
final container = await loggedInContainer(session);

session.emitMessage(message(bob, 3));             // server traffic
session.emitPresence(const PresMessage(...));
session.dropConnection();                         // the socket goes away
session.holdHistory = Completer();                // hold a load to test races
session.failPublish = const ServerException(403, 'denied');
expect(session.calls, contains('markRead $bob 3'));   // what the app sent
```

- Passwords default to `alice` / `alice123`; the token is `token-<userId>`.
- `publish` assigns the next seq and echoes the message back like the server (`echo = false` to
  turn that off).
- `startCall` publishes a call message like `publish`; `sendCallEvent` logs `call <topic> <seq>
  <event>` (payloads in `callPayloads`) and throws while not connected. `emitInfo` pushes call
  events, `serverInfo` sets the ICE servers (one fake STUN server by default), and
  `attachCount(topic)` shows how many attaches hold a topic.
- `deleteMessages` deletes from the history and logs `delete <topic> <low>-<high>[ hard]`;
  `recordDeletion` does the same as another device would, and `deleteLog` answers from it.
  `failDelete` refuses the next one. `publishHeads` keeps each `publish` head; `loseNextAck`
  stores a message but throws instead of answering, like a drop before the ack.
- While not `Connected`, `attach`, `chatList`, `history`, `publish`, `deleteMessages` and
  `deleteLog` throw `ConnectionClosedException`, like the client.
- `restoreWith(token)` starts it like `TinodeClient.restore`: reconnecting, then logged in once
  `reachable` (the default) or when the test calls `comeOnline()`. `restoreTo(session)` makes a
  `SessionRestorer` of it.
- Its streams and `closed` deliver synchronously. A fake made in `setUp` lives outside a widget
  test's fake-async zone, where async callbacks would never run.

## Fake call media

Calls get `FakeCallMedia` instead of WebRTC: `createTestContainer`, `loggedInContainer` and
`pumpTinodeChat` pass `FakeCallMedia.new` unless you give them a `callMedia`. Use a
`FakeCallMediaFactory` to reach the media a call created:

```dart
final media = FakeCallMediaFactory();
final container = await loggedInContainer(session, callMedia: media.call);
await container.read(callControllerProvider.notifier).start(bob, audioOnly: true);

media.last.emitLink(CallLinkState.connected);    // what WebRTC would report
expect(media.last.log, contains('open audio'));  // what the call asked of it
```

Its offer and answer are the fixed strings `local offer` and `local answer`. `CallVideoView` draws
nothing in widget tests (the plugin isn't there), so call screens can be pumped like any other.

## The cache in tests

Every container gets its own `MemoryChatStoreOpener` (`createTestContainer`, `pumpTinodeChat`),
so tests run through `CachedTinodeSession` like the app. Share one opener between two containers
to test an offline start: remember the user with `rememberUser`, open a first container online to
fill the cache, then a second with `session.reachable = false` (see
`test/offline/cold_start_test.dart`). `test/flutter_test_config.dart` silences drift's warning about
several in-memory databases.

`drift_schemas/` holds the schema of each version (`dart run drift_dev schema dump
lib/src/offline/data/chat_database.dart drift_schemas/`). Dump it again when the schema version
goes up, and add a migration test for the step.

## Widget tests

```dart
await pumpTinodeChat(tester, session, credentials: TinodeCredentials.token(session.token));
await tester.tap(find.text('Bob'));
await tester.pumpAndSettle();
```

- After `enterText`, `pump()` once before tapping a button that enables on input.
- `pumpAndSettle` times out while a progress indicator spins. Make sure the fake answers (it does by
  default) or use `pump()`.
- Check rebuild scope with `debugOnRebuildDirtyWidget` (see `chat_list_rebuild_test.dart`) when you
  change what a widget watches.

## Integration tests

They run against the local server from `../tinode-tests` and are skipped by default
(`dart_test.yaml`).

```sh
(cd ../tinode-tests && docker compose up -d)    # web UI at http://localhost:6060/
fvm flutter test --tags integration --run-skipped --concurrency=1
```

- Users: `alice` / `alice123`, `bob` / `bob123`, … (password = name + `123`).
- API key: `AQEAAAABAAD_rAp4DJh05a1HAwFT3A6K`.
- From the Android emulator the host is `10.0.2.2`, not `localhost`.
- Use plain `test()`, not `testWidgets()`: widget tests block real network access.
- `call_test.dart` needs the server's ICE servers (`ICE_SERVERS_FILE` in `../tinode-tests`). It
  places real calls between alice and bob with fake media: the server only relays the WebRTC setup,
  so the whole call flow runs without audio.

## Manual check with the example app

```sh
cd example && fvm flutter run -d linux
# Android emulator: fvm flutter run --dart-define=TINODE_SERVER=ws://10.0.2.2:6060
```

1. Log in as `alice`; the chat list shows unread counts.
2. In the web UI (http://localhost:6060/) log in as `bob` and message alice: alice's badge goes up
   and the chat moves to the top.
3. Open the chat: the message is there, and the badge clears.
4. Reply from the app: bob sees it in the web UI.

Calls need two devices, or one device and the web UI (http://localhost:6060/ on the computer that
runs the server; browsers only give camera and microphone to `localhost` or https):

5. From the app, start a voice call to bob: the web UI rings. Accept it there and talk; hang up
   from either side. The chat shows the call with its duration.
6. Call alice from the web UI while the app shows the chat list: the app rings. Decline: the web
   UI shows the call as declined.
7. A video call on a phone on mobile data, to the web UI on Wi-Fi, goes through the TURN server;
   its traffic shows in the TURN provider's dashboard.
