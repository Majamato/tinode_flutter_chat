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
      domain/                     ChatSummary, ChatListState, ChatMessage, ChatState, CallRecord
      application/                providers: chat list, chat, send
      presentation/chat_list/     list screen and its tile parts
      presentation/chat/          chat screen, message list, bubbles, composer
    calls/                        1:1 voice and video calls
      domain/                     ActiveCall, CallInvite, CallFailure, the CallMedia interface
      data/                       WebRtcCallMedia (flutter_webrtc)
      application/                CallController, CallResources, callsAvailable, callMediaFactory
      presentation/               call layer, ringing and call screens, call buttons
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
| `domain` | Immutable models and pure rules (merging, counters) | Dart, `collection`, `meta`, `tinode_dart_client` models, `webrtc_interface` types | Flutter, Riverpod, other layers |
| `data` | Talking to the outside world: the server, the OS's network reports, WebRTC; a local store later | `domain`, `tinode_dart_client`, `web_socket`, platform plugins behind an interface (`connectivity_plus`, `flutter_webrtc`) | Flutter itself, Riverpod, `application`, `presentation` |
| `application` | Riverpod providers: state, use cases, the glue between data and UI | `domain`, `data`, `riverpod`, `riverpod_annotation` | Flutter, `flutter_riverpod`, `presentation` |
| `presentation` | Widgets only | `domain`, `application`, Flutter, `flutter_riverpod` | `data` (except the composition root in `app/`) |

Two of these are deliberate stretches. A plugin is Flutter code, but `data` may wrap one behind a
Dart interface (`NetworkMonitor`, `CallMedia`) as long as the file imports no `package:flutter/`;
tests swap in a fake through a provider. And `domain` may use `webrtc_interface`, which is pure
Dart with no dependencies, so a call's `MediaStream` can travel from `data` to the widgets without
casts; only `presentation` draws it.

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
  in tests, `sessionConnectorProvider`, `networkMonitorProvider` and `callMediaFactoryProvider`.
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
          ├ ChatScreen(topic)   pushed per chat; CallButtons in its app bar
          ├ CallLayer           over the routes: IncomingCallView or CallView
          └ ReconnectingBanner  below the routes, while the link is restored
```

`SessionGate` sits **above** the nested navigator on purpose. Riverpod 3 pauses consumers on routes
covered by another route (via `TickerMode`), so a gate inside the navigator would not notice a lost
connection while a chat is open. Placed above, losing the session removes the navigator and every
chat route with it. `CallLayer` sits beside the routes in a `Stack` for the same reason: an
incoming call must show whichever chat is open, and system back does nothing during a call.

## Session lifecycle

```
connecting ── no credentials ─────────► awaitingLogin ── login() ──► loggedIn
connecting ── credentials accepted ───► loggedIn
connecting ── token rejected (401) ───► awaitingLogin(lastFailure)
connecting ── unreachable ────────────► failed
loggedIn   ── socket drops ───────────► loggedIn        the client reconnects; banner meanwhile
loggedIn   ── Disconnected(401/404) ──► awaitingLogin   token forgotten, controller rebuilt
loggedIn   ── Disconnected(other) ────► failed
failed     ── reconnect() ────────────► connecting      old session closed, token login
```

- `SessionController` (keepAlive `AsyncNotifier<SessionState>`) holds it. `SessionState` is sealed:
  `SessionAwaitingLogin(session, lastFailure)` or `SessionLoggedIn(session, login)`. Loading means
  connecting, an error means failed. `SessionPhase.of` turns that into the gate's four screens.
- `CredentialsController` remembers what to log in with. After any login it holds the session
  token, so a reconnect never needs the password.
- A dropped socket is the client's business: it reconnects with backoff, logs in with the token
  and re-attaches topics. `SessionController` follows `TinodeSession.statusChanges` and acts only
  on two cases: `Connected(login:)` (the client logged in again, so the renewed token replaces the
  remembered one and `onLoggedIn` fires) and `Disconnected`, which is final. `ReconnectingController`
  drives the banner.
- **Background:** `TinodeChat` forwards `AppLifecycleListener` hide/show to `BackgroundPolicy`.
  After `backgroundGrace` (15 s) hidden it suspends the session; push notifications cover the time
  after that. During a call it doesn't: `CallController` tells it a call is running
  (`keepOpen`), and the grace starts when the call ends. Showing the app cancels the timer and resumes, which also probes a socket that
  stayed open but may have died while the phone slept.
- **Network hints:** `NetworkMonitor` (data, over `connectivity_plus`: OS callbacks, no polling)
  reports network changes to `NetworkPolicy`. After 1 s of quiet (`networkSettle`) it probes a
  connected socket with a 4 s deadline, or retries at once while reconnecting with a network up.
  A suspended or closed session is left alone. The hint never changes what the UI shows; only the
  socket's status does.

## Data flow

`TinodeSession` (in `session/data`) is the only gateway to the server. It wraps `TinodeClient`
(a `final` class that can't be faked), splits its events into typed streams, drops malformed
packets. Retrying an attach the server answers with `503 locked` (both sides of a P2P chat
attaching at once) is the client's job. A cached or offline session will implement the same
interface.

**Chat list** (`ChatListController`, keepAlive, sync `Notifier<ChatListState>`):

1. Subscribes to `presence` on `me` and to `messages`, **then** attaches `me` and loads the list,
   so nothing that arrives during the load is lost.
2. `pres msg` raises a chat's `lastSeq`; an unknown topic reloads the list (a new chat).
   `pres read` (another device read it) raises `read`. A `data` message in an attached chat raises
   `lastSeq`, and also `read` when the user sent it.
3. After a reconnect the list reloads: presence sent while the link was down is never replayed.
4. `unread = lastSeq − read`. Order is by `lastMessageAt`, newest first.

**Chat** (`ChatController(topic)`, autoDispose, sync `Notifier<ChatState>`):

1. Subscribes to the topic's live messages, attaches, loads the newest page of history.
2. History pages, live messages and the sender's publish ack all merge through
   `ChatState.withMessages`, keyed by seq: the ack and the server's echo of the same message dedup.
3. What the user sees is marked read on the server and in the chat list.
4. Scrolling to the top calls `loadOlder()`. Closing the screen disposes the provider, which
   detaches from the topic.
5. After a reconnect it fetches `since: lastSeq + 1`. A full page may hide a bigger gap, and a
   failed fetch leaves one, so both reload the chat instead.
6. A message that replaces another (`head.replace`, as the server does to record a call's progress)
   is no bubble of its own: it updates its target, or waits in `ChatState.pending` until an older
   page brings the target. `firstSeq` and `lastSeq` count every seq seen, updates included, so
   catching up and marking read don't stall on them.

**Attaches are counted** (`ClientTinodeSession`): a chat screen and a call can hold the same
topic, and it stays attached until every attach has been matched by a detach. Closing the chat
during a call doesn't end the call.

**Calls** (`CallController`, keepAlive, sync `Notifier<ActiveCall?>`):

1. *Outgoing:* open the microphone (and camera; the OS asks here, and a refusal ends it before
   anything is sent), attach the chat, publish the call message (`startCall`); its seq names the
   call. The peer's `ringing` and `accept` arrive as `info`. On `accept` the caller creates the
   WebRTC offer and sends it; the callee's `answer` completes the link.
2. *Incoming:* a call message (`head.webrtc: started`) arrives live in an attached chat, or, for
   any other chat, `pres msg` on `me` starts an **invite check**: attach the chat, read from that
   seq, and ring if the call isn't already answered or over (`CallInvite.findIn`). The check's
   attach becomes the call's. Ringing sends `ringing`; Accept opens the media, sends `accept`, and
   answers the caller's offer.
3. Each side holds the peer's ICE candidates back until the peer's description is set.
4. The call ends on a hang-up (ours or the server's `info`), on the server's update saying it's
   over, on a failed WebRTC link, when the connection drops (the server ends it anyway), or when
   nothing connects within the server's `callTimeout` plus `callSetupMargin`. The ended call
   shows for `callEndedLinger` (2 s), then the state goes back to null.
5. When another device of the user accepts (`info` on `me`, or the `accepted` update), the ringing
   stops. A call to the user while in another call is declined at once.
6. `CallMedia` (domain interface, `WebRtcCallMedia` in data) owns the peer connection and the
   streams, so all of the above is tested with `FakeCallMedia`.
7. `CallResources` holds what one call owns: the attach of its topic, its `CallMedia` and their
   events, the held-back candidates and the setup timer. Ending the call releases it in one step,
   and work started for the call checks `isReleased` after every `await`.

**Sending** (`SendController(topic)`): publishes plain text, then adds the message from the ack
right away. On failure the composer keeps the text and shows a snack bar.

## Errors

`ChatFailure.of(error)` maps any error to a small enum the UI can explain
(`unreachable`, `connectionLost`, `badCredentials`, `timeout`, `rejected`, `unexpected`), and
`failureMessage` turns it into the host's `TinodeChatStrings`.

| Where | Shown as |
|-------|----------|
| Connect fails, or the link ends for good | `SessionErrorView` with Reconnect |
| The socket drops and the client is reconnecting | `ReconnectingBanner`; sends fail meanwhile |
| Login fails | Text under the login form; the session keeps waiting for a login |
| Chat list or history fails to load | `ErrorRetryView` in place of the list |
| Send fails | Snack bar; the text stays in the field |
| A call fails (permission, busy, link) | Snack bar from `CallLayer`; the call screen says why for 2 s |

Providers report failures in their state (`LoadStatus.failed`, `AsyncError`); widgets never catch.

## Public API

Only what `lib/tinode_flutter_chat.dart` exports is public: `TinodeChat`, `TinodeCredentials`
(`PasswordCredentials`, `TokenCredentials`), `TinodeChatTheme`, `TinodeChatStrings`, and the
client's `TinodeConfig` and `LoginResult`. Everything else may change freely. Every exported symbol
carries dartdoc. Adding an export is an API decision: keep the list short.
