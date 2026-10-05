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
| Data | `ClientTinodeSession` over an in-memory WebSocket | `package:web_socket/testing.dart` `fakes()` |
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
- Its streams and `closed` deliver synchronously. A fake made in `setUp` lives outside a widget
  test's fake-async zone, where async callbacks would never run.

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
fvm flutter test --tags integration --run-skipped
```

- Users: `alice` / `alice123`, `bob` / `bob123`, … (password = name + `123`).
- API key: `AQEAAAABAAD_rAp4DJh05a1HAwFT3A6K`.
- From the Android emulator the host is `10.0.2.2`, not `localhost`.
- Use plain `test()`, not `testWidgets()`: widget tests block real network access.

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
