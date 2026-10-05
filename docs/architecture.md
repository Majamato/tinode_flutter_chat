# Architecture

## Goals

- A chat UI any Flutter app can drop in: `TinodeChat(config: …)` below a `MaterialApp`, nothing else.
- Business logic fully separate from widgets, so it can be tested without Flutter and later moved
  into its own package (as Stream and Flyer do with their `*_core` packages).
- Small, cheap rebuilds: a state change rebuilds only the widgets that show it.

## Layout

One package, organised **by feature first, then by layer** (see Andrea Bizzotto's
[feature-first layout](https://codewithandrea.com/articles/flutter-project-structure/)), following
the [Dart package layout](https://dart.dev/tools/pub/package-layout): everything lives in `lib/src/`,
and `lib/tinode_flutter_chat.dart` exports the small public API with `show` lists.

```
lib/
  tinode_flutter_chat.dart        public API (barrel), `export … show` only
  src/
    app/                          composition root
      application/                createTinodeContainer()
      presentation/               TinodeChat (public), SessionGate, ChatNavigator
    session/                      connecting and logging in
      data/                       TinodeSession interface + ClientTinodeSession
      domain/                     TinodeCredentials (public)
      application/                providers: session, credentials, login
      presentation/               login screen, connecting and error views
    chats/                        chat list and open chats
      domain/                     ChatSummary, ChatListState, ChatMessage, ChatState
      application/                providers: chat list, chat, send
      presentation/chat_list/     list screen and its tile parts
      presentation/chat/          chat screen, message list, bubbles, composer
    shared/                       used by several features
      domain/                     ValueObject, ChatFailure
      application/                BuildLifetime
      presentation/               theme, strings, time format, error view
```

A feature is something the user *does* (connect, chat), not a screen. New work goes into an
existing feature when it shares its state, otherwise into a new folder with the same four layers.
Expected next features: `search` (local FTS and `fnd`), `profile`, `attachments`.

## Layers

| Layer | Holds | May import | Must not import |
|-------|-------|------------|-----------------|
| `domain` | Immutable models and pure rules (merging, counters) | Dart, `collection`, `meta`, `tinode_dart_client` models | Flutter, Riverpod, other layers |
| `data` | Talking to the outside world: the server today, a local store later | `domain`, `tinode_dart_client`, `web_socket` | Flutter, Riverpod, `application`, `presentation` |
| `application` | Riverpod providers: state, use cases, the glue between data and UI | `domain`, `data`, `riverpod`, `riverpod_annotation` | Flutter, `flutter_riverpod`, `presentation` |
| `presentation` | Widgets only | `domain`, `application`, Flutter, `flutter_riverpod` | `data` (except the composition root in `app/`) |

`test/architecture/layer_imports_test.dart` fails the build when a file breaks these rules, and
`build.yaml` only runs the provider generator on `application/` folders. Business logic in a widget
file is a review blocker: if a widget needs a computed value, add it to a domain model or a
provider.

## The container

`TinodeChat` owns its own `ProviderContainer` (built by `createTinodeContainer`) and exposes it with
`UncontrolledProviderScope`:

- The host app needs no `ProviderScope`. If it has one, our providers don't mix with its own.
- The session lives exactly as long as the widget: removing `TinodeChat` disposes the container,
  which closes the connection.
- The container overrides the inputs: `tinodeConfigProvider`, `initialCredentialsProvider` and,
  in tests, `sessionConnectorProvider`.
- Automatic retry is off for the whole container. Retrying a rejected login or a failed connect
  would hide errors the user has to act on, so every retry is a button.
- `config` and `credentials` are read once. To switch server or user, give `TinodeChat` a new `Key`.

Trade-off: host-provided builders (future customisation hooks) won't see the host's providers.
Revisit when those hooks arrive.

## Widget tree

```
TinodeChat                      owns the container
└ UncontrolledProviderScope
  └ TinodeChatStringsScope      host strings
    └ ChatThemeScope            adds TinodeChatTheme.fallback when the host has none
      └ SessionGate             watches the session phase only
        ├ ConnectingView
        ├ LoginScreen
        ├ SessionErrorView      "Reconnect"
        └ ChatNavigator         nested Navigator, only while logged in
          ├ ChatListScreen      first route
          └ ChatScreen(topic)   pushed per chat
```

`SessionGate` sits **above** the nested navigator on purpose. Riverpod 3 pauses consumers on routes
covered by another route (via `TickerMode`), so a gate inside the navigator would not notice a lost
connection while a chat is open. Placed above, losing the session removes the navigator and every
chat route with it.

## Session lifecycle

```
             connect ok, no credentials          login()
connecting ───────────────────────────► awaitingLogin ───────► loggedIn
    │   connect ok + credentials ok ───────────────────────────────▲
    │   token rejected (401) ─► awaitingLogin(lastFailure)          │
    ▼                                                               │ socket drops
  failed ◄──────────────────────────────────────────────────────────┘
    │ reconnect()  (closes the old session, connects, logs in with the remembered token)
    └──────────► connecting
```

- `SessionController` (keepAlive `AsyncNotifier<SessionState>`) holds it. `SessionState` is sealed:
  `SessionAwaitingLogin(session, lastFailure)` or `SessionLoggedIn(session, login)`. Loading means
  connecting, an error means failed. `SessionPhase.of` turns that into the gate's four screens.
- `CredentialsController` remembers what to log in with. After any login it holds the session
  token, so a reconnect never needs the password.
- The client has no reconnection yet, so a drop goes to the error view. Automatic reconnect is the
  first follow-up.

## Data flow

`TinodeSession` (in `session/data`) is the only gateway to the server. It wraps `TinodeClient`
(a `final` class that can't be faked), splits its events into typed streams, drops malformed
packets, and retries an attach the server answers with `503 locked` (both sides of a P2P chat
attaching at once). A cached or offline session will implement the same interface.

**Chat list** (`ChatListController`, keepAlive, sync `Notifier<ChatListState>`):

1. Subscribes to `presence` on `me` and to `messages`, **then** attaches `me` and loads the list,
   so nothing that arrives during the load is lost.
2. `pres msg` raises a chat's `lastSeq`; an unknown topic reloads the list (a new chat).
   `pres read` (another device read it) raises `read`. A `data` message in an attached chat raises
   `lastSeq`, and also `read` when the user sent it.
3. `unread = lastSeq − read`. Order is by `lastMessageAt`, newest first.

**Chat** (`ChatController(topic)`, autoDispose, sync `Notifier<ChatState>`):

1. Subscribes to the topic's live messages, attaches, loads the newest page of history.
2. History pages, live messages and the sender's publish ack all merge through
   `ChatState.withMessages`, keyed by seq: the ack and the server's echo of the same message dedup.
3. What the user sees is marked read on the server and in the chat list.
4. Scrolling to the top calls `loadOlder()`. Closing the screen disposes the provider, which
   detaches from the topic.

**Sending** (`SendController(topic)`): publishes plain text, then adds the message from the ack
right away. On failure the composer keeps the text and shows a snack bar.

## Errors

`ChatFailure.of(error)` maps any error to a small enum the UI can explain
(`unreachable`, `connectionLost`, `badCredentials`, `timeout`, `rejected`, `unexpected`), and
`failureMessage` turns it into the host's `TinodeChatStrings`.

| Where | Shown as |
|-------|----------|
| Connect fails or the socket drops | `SessionErrorView` with Reconnect |
| Login fails | Text under the login form; the session keeps waiting for a login |
| Chat list or history fails to load | `ErrorRetryView` in place of the list |
| Send fails | Snack bar; the text stays in the field |

Providers report failures in their state (`LoadStatus.failed`, `AsyncError`); widgets never catch.

## Public API

Only what `lib/tinode_flutter_chat.dart` exports is public: `TinodeChat`, `TinodeCredentials`
(`PasswordCredentials`, `TokenCredentials`), `TinodeChatTheme`, `TinodeChatStrings`, and the
client's `TinodeConfig` and `LoginResult`. Everything else may change freely. Every exported symbol
carries dartdoc. Adding an export is an API decision: keep the list short.
