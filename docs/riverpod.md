# Riverpod in this package

We use [Riverpod 3](https://riverpod.dev) with code generation. This page sums up the official
guidance that applies to us, plus the rules this package adds. When in doubt, the official docs
win: [providers](https://riverpod.dev/docs/concepts2/providers),
[refs](https://riverpod.dev/docs/concepts2/refs),
[auto dispose](https://riverpod.dev/docs/concepts2/auto_dispose),
[do's and don'ts](https://riverpod.dev/docs/root/do_dont),
[testing](https://riverpod.dev/docs/how_to/testing),
[what's new in 3.0](https://riverpod.dev/docs/whats_new).

## Versions (read before upgrading)

| Package | Version | Why |
|---------|---------|-----|
| `flutter_riverpod`, `riverpod` | 3.1.0 | Pinned by `riverpod_annotation` 4.0.0. |
| `riverpod_annotation` | 4.0.0 | Generated code only compiles against the annotation version its generator targets. |
| `riverpod_generator` (dev) | 4.0.0+1 | The newest that resolves on Flutter 3.38.6: later ones need `analyzer` ≥ 9, which conflicts with the `meta`/`test_api` versions Flutter 3.38 pins. |
| `riverpod_lint` (analyzer plugin) | 3.1.4 | Newest for Dart 3.10. |

These are **exact pins, on purpose**. A caret range let a host app resolve a newer
`riverpod_annotation`, and our committed `.g.dart` files stopped compiling. When the Flutter version
in `.fvmrc` moves up, bump all four together, run `build_runner`, and commit the regenerated files.
(Riverpod 3.4 needs Dart 3.12; `riverpod_lint` 3.1.9 needs Dart 3.13.)

`riverpod_lint` is an analysis-server plugin (no `custom_lint` any more), enabled in
`analysis_options.yaml` under `plugins:`. Its rules are warnings, on by default. **Only
`dart analyze` and the IDE report them; `flutter analyze` does not**, so CI uses `dart analyze`.

## Declaring providers

Code generation only, and only in `application/` folders (`build.yaml` runs the generator nowhere
else; `test/architecture/` rejects `@riverpod` in `presentation/`). The same `build_runner` run
generates the drift tables of `lib/src/offline/data/chat_database.dart`; its output is committed
like the providers'.

```dart
part 'chat_controller.g.dart';

@riverpod                                   // autoDispose by default
class ChatController extends _$ChatController {
  @override
  ChatState build(String topic) { … }       // build parameters make it a family
  Future<void> loadOlder() async { … }      // public methods are the use cases
}

@riverpod                                   // a derived, read-only value
ChatMessage? chatMessage(Ref ref, String topic, int seq) =>
    ref.watch(chatControllerProvider(topic).select((chat) => chat.bySeq[seq]));
```

Application files import `package:riverpod_annotation/riverpod_annotation.dart`, plus
`package:riverpod/riverpod.dart` when they need `select` (the annotation package doesn't export
it). Never `flutter_riverpod` there: application code must not depend on Flutter.

After any change to a provider: `fvm dart run build_runner build --force-jit`, then
`fvm dart format .`. (`--force-jit` because `flutter_webrtc` pulls in `objective_c`, whose build
hook the default AOT compile of the builders refuses.)
Generated files are committed (hosts don't run our generator), and CI fails if they're stale.

### Choosing the kind

| Need | Use |
|------|-----|
| A value computed from other providers | functional `@riverpod` |
| State fed by streams that must not miss events (chat list, open chat) | `Notifier` with a sync `build` returning a state with `LoadStatus`. Subscribe in `build`, then start the async load with `unawaited(...)`. |
| One-shot async work with a result (connect + login) | `AsyncNotifier` |
| A button's progress and error (login, send) | autoDispose `Notifier<AsyncValue<void>>` with one method |
| Short-lived UI state (text in a field, scroll position, focus) | **Not a provider**: a `State` field or a controller |

Why not `AsyncNotifier` for live data: events that arrive while `build` is still awaiting have no
state to merge into. A sync `build` has a state from the first instant.

We don't use the experimental `Mutation` API. A host could resolve a Riverpod version where it
changed, and the package would break inside their app.

### Naming

- Notifiers: `XController` (`SessionController`, `ChatController`) → `xControllerProvider`.
- Derived values: a noun (`chatSummary`, `activeSession`, `loginFailure`).
- Inputs the container overrides: what they hold (`tinodeConfig`, `sessionConnector`).

### Lifetimes

- **autoDispose is the default.** Anything tied to a screen (a chat, a send button) is disposed one
  frame after its last listener goes away; `onDispose` cleans up (detach, cancel subscriptions).
- **`@Riverpod(keepAlive: true)` only for session-wide state**: the inputs, the session, the
  credentials, the chat list. A keepAlive provider may only watch keepAlive providers
  (`only_use_keep_alive_inside_keep_alive`).
- Families are keyed by `String topic` or `(topic, seq)`; arguments need value equality.

## Using providers

| Where | Call | Why |
|-------|------|-----|
| `build` of a widget or provider | `ref.watch(p)` or `ref.watch(p.select(...))` | Rebuild when it changes |
| Callbacks (`onPressed`, `onSubmitted`, notifier methods) | `ref.read(p)` / `ref.read(p.notifier)` | One-off, no subscription |
| Side effects (snack bar, navigation) | `ref.listen(p, …)` in `build` | Reacts without rebuilding |

- Never `ref.read` in `build` "to avoid rebuilds"; use `select` instead.
- **`select` the smallest value a widget shows.** `select` compares with `==`, so return scalars,
  records, value objects (`ValueObject`), or collections that keep their identity.
- **Stable identity rule:** states that widgets `select` collections from (`ChatListState.order`,
  `ChatState.seqs`) return `this` when nothing changed and keep the same list instance unless its
  content changed. That way, selecting a list costs one `identical` check. Keep this when adding
  fields.
- Riverpod filters updates with `==`. Value objects with `props` make no-op updates silent.
- Widgets never create providers or start work; providers start their own work in `build`.

## Async safety

After every `await` in a provider, check that the build that started the work is still current
before touching `state` or `ref`.

**Do not rely on `ref.mounted` for this in Riverpod 3.1.** It is tied to the provider, not to one
build, so it stays `true` after a rebuild, and a load started by the old build would overwrite the
new state. (3.2 fixed this.) Use `BuildLifetime`:

```dart
@override
ChatState build(String topic) {
  final lifetime = BuildLifetime(ref);       // turns inactive on rebuild or dispose
  unawaited(_load(lifetime));
  return const ChatState.loading();
}

Future<void> _load(BuildLifetime lifetime) async {
  final page = await _session.history(topic, limit: historyPageSize);
  if (!lifetime.isActive) return;
  state = state.withMessages(...);
}
```

`ref.mounted` is still the right check in short-lived controllers that never rebuild
(`LoginController`, `SendController`).

## Retry

Riverpod 3 retries failing providers automatically. `createTinodeContainer` turns that off
(`retry: (_, _) => null`): a rejected login or an unreachable server must reach the user, and every
retry is an explicit action (`reconnect()`, `reload()`).

## Visibility pauses

In Riverpod 3 a consumer whose `TickerMode` is off (for example, a route covered by another route)
stops receiving updates until it is visible again; providers listened only by paused consumers pause
too. That saves work for screens the user can't see, but it means **a widget on a covered route
can't react to events**. Anything that must react everywhere (like the session gate) belongs above
the navigator. keepAlive providers keep their state while paused and resume with the latest state.

## Testing

- **Providers:** `createTestContainer(connector: connectTo(fake))` (in `test/support/`) builds the
  real container with a fake session and disposes it after the test. `loggedInContainer(fake)`
  also logs in. Keep autoDispose providers alive with `container.listen(p, (_, _) {})` rather
  than `read`.
- **Widgets:** pump `TinodeChat.withConnector(...)` (see `pumpTinodeChat`); read the container with
  `tester.container()` from `flutter_riverpod` if a test needs it.
- Override inputs (`sessionConnectorProvider`), not internal providers.

See [testing.md](testing.md).
