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
    offline/                      the cache, catching up and the outbox
      domain/                     SeqRanges, OutgoingMessage, outbox events, merge and retry rules
      data/                       ChatDatabase (drift), ChatStore, ChatStoreOpener,
                                  ChatSession, CachedTinodeSession
      application/                chatStoreOpener
    new_chat/                     finding people and starting chats
      domain/                     findQuery, SearchResult, FindState, NewGroup
      application/                FindController(scope), NewGroupController
      presentation/               search and new group screens, the chat list's new chat button
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
Expected next features, in the README's roadmap order: group chat essentials (in `chats`),
`attachments`, `profile`, push, then `search` (local message search).

## Layers

| Layer | Holds | May import | Must not import |
|-------|-------|------------|-----------------|
| `domain` | Immutable models and pure rules (merging, counters) | Dart, `collection`, `meta`, `tinode_dart_client` models, `webrtc_interface` types | Flutter, Riverpod, other layers |
| `data` | Talking to the outside world: the server, the OS's network reports, WebRTC, the local cache | `domain`, `tinode_dart_client`, `web_socket`, `drift`, platform plugins behind an interface (`connectivity_plus`, `flutter_webrtc`, `drift_flutter`, `path_provider`) | Flutter itself, Riverpod, `application`, `presentation` |
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
  in tests, `sessionConnectorProvider`, `sessionRestorerProvider`, `chatStoreOpenerProvider`
  (`MemoryChatStoreOpener`), `networkMonitorProvider` and `callMediaFactoryProvider`.
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
          ├ ChatListScreen      first route; NewChatButton
          ├ FindPeopleScreen    pushed by NewChatButton
          ├ NewGroupScreen      pushed from the search
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
connecting ── token of the last user ─► loggedIn        offline start: cache now, login later
connecting ── no credentials ─────────► awaitingLogin ── login() ──► loggedIn
connecting ── credentials accepted ───► loggedIn
connecting ── token rejected (401) ───► awaitingLogin(lastFailure)
connecting ── unreachable ────────────► failed
loggedIn   ── socket drops ───────────► loggedIn        the client reconnects; banner meanwhile
loggedIn   ── Disconnected(401) ──────► awaitingLogin   token forgotten, cache kept
loggedIn   ── Disconnected(404) ──────► awaitingLogin   the user is gone: cache deleted
loggedIn   ── logout() ───────────────► awaitingLogin   cache deleted, credentials forgotten
loggedIn   ── Disconnected(other) ────► failed
failed     ── reconnect() ────────────► connecting      old session closed, token login
```

- `SessionController` (keepAlive `AsyncNotifier<SessionState>`) holds it. `SessionState` is sealed:
  `SessionAwaitingLogin(session, lastFailure)` or `SessionLoggedIn(session, login)`. Loading means
  connecting, an error means failed. `SessionPhase.of` turns that into the gate's four screens.
- `CredentialsController` remembers what to log in with. After any login it holds the session
  token, so a reconnect never needs the password.
- **Per-user cache.** After a login the controller opens that user's cache
  (`ChatStoreOpener.open(server, userId)`, one SQLite file each), remembers them as the server's
  last user and wraps the session in a `CachedTinodeSession`. A failed open falls back to a cache in
  memory, so the chat still works online.
- **Offline start.** With a token and a remembered user for the server, the controller opens their
  cache and starts the session with `TinodeClient.restore`, which connects and logs in in the
  background. The state is `SessionLoggedIn` at once, with `login` null until the server answers;
  a token of another user rebuilds on that user's cache, a refused one goes to the login screen.
  A password login always connects first.
- **Logout** (`logout()`, the chat list's menu, `TinodeChatController.logOut`) closes the session,
  deletes the cache and forgets the credentials; `onLoggedOut` tells the host, also after a 401.
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
attaching at once) is the client's job.

`ChatSession` (in `offline/data`) is what the logged-in app sees: a `TinodeSession` with the user's
cache. `CachedTinodeSession` decorates the server session:

- **Write-through.** Every `data` packet, `pres msg`/`read` on `me`, `pres del` and history page is
  written to the store in arrival order; reads wait for those writes. Controllers never watch the
  database: they read the cache once, then follow the session's streams, plus `outbox` and
  `deletions`.
- **Coverage.** A history page covers the seqs it answered for; a live message extends coverage
  only when it follows it. `olderPage` serves covered seqs from the cache and fetches only gaps;
  `catchUp` fetches after the newest covered seq, then the delete log since the last applied delete
  ID (`get what=del`).
- **Chat list sync.** `chatList()` asks `get sub` with "if modified since" the newest change the
  cache holds and merges the answer: counters never move back, a `public`/`private` left out is
  unchanged, a chat with `deleted` goes.
- **Outbox.** `send`, `delete` and offline read markers are rows in the `outbox` table, drained in
  order per topic whenever the link is up (at start, on `Connected`, after a change, after a
  backoff). A message carries its client ID in its head; one sent without a reply (`in_flight`) is
  looked up on the server before it is sent again. Errors: a closed link waits for the next
  connect; a timeout looks first; 5xx/408/409/429 back off (up to a minute, failed after 5 tries);
  other 4xx fail the message, which the user can retry or discard. A refused deletion brings its
  messages back.

**Chat list** (`ChatListController`, keepAlive, sync `Notifier<ChatListState>`):

1. Subscribes to `presence` on `me` and to `messages`, **then** shows the cached list, attaches
   `me` and syncs the list, so nothing that arrives during the load is lost. Offline, the cached
   list stays ready; the next `Connected` attaches and syncs.
2. `pres msg` raises a chat's `lastSeq`; an unknown topic reloads the list (a new chat).
   `pres read` (another device read it) raises `read`. A `data` message in an attached chat raises
   `lastSeq`, and also `read` when the user sent it.
3. After a reconnect the list syncs again: presence sent while the link was down is never
   replayed.
4. `unread = lastSeq − read`. Order is by `lastMessageAt`, newest first.

**Chat** (`ChatController(topic)`, autoDispose, sync `Notifier<ChatState>`):

1. Subscribes to the topic's live messages, the outbox and deletions; shows the cached messages and
   the outbox at once; then attaches and catches up (or loads the newest page when nothing is
   cached). Offline, a cached chat stays ready and syncs on the next `Connected`.
2. History pages, live messages and sent outbox messages all merge through
   `ChatState.withMessages`, keyed by seq; a numbered copy of an outgoing message (the outbox's ack
   or the server's echo, whichever comes first) replaces it by client ID.
3. What the user sees is marked read on the server and in the chat list.
4. Scrolling to the top calls `loadOlder()`. Closing the screen disposes the provider, which
   detaches from the topic.
5. After a reconnect it catches up. When a full page came back the gap is too wide to show:
   `ChatState.restartedWith` starts over from that page, keeping the outbox, and older pages fill
   in from the cache and the server. Deletions remove their bubbles (`withoutSeqs`).
6. A message that replaces another (`head.replace`, as the server does to record a call's progress)
   is no bubble of its own: it updates its target, or waits in `ChatState.pending` until an older
   page brings the target. `firstSeq` and `lastSeq` count every seq seen, updates included, so
   catching up and marking read don't stall on them.

**Starting a chat** (`FindController(scope)`, autoDispose, sync `Notifier<FindState>`):

1. Each change of the input goes to `search`; after `findDebounce` (300 ms) without changes it asks
   the server (`find`). Answers to older input are dropped. Input shorter than 2 letters searches
   nothing.
2. `findQuery` turns the input into a `fnd` query: each word may match (OR), as a tag and as a
   login (`basic:`). Emails, phone numbers and prefixed words go as typed.
3. Each screen keeps its own search (`FindScope`): the new group's member search leaves out groups,
   and both leave out the user.
4. Searching needs the server. Offline it fails, and a failed search runs again on `Connected`.
5. Tapping a result opens its chat over the chat list (`ChatScreen.openOverList`). For a user, the
   chat screen's attach creates the 1:1 chat the first time.
6. `NewGroupController.create` creates the group, adds the members in parallel and releases the
   attach that creating took. A member the server refuses doesn't undo the group: the screen says
   so and opens it anyway.
7. The server sends no presence to whoever started a chat. So `ChatListController.refresh` syncs
   the list after a group is created, and `ChatController` asks for it when it attaches a chat the
   list doesn't have. A user added to a group gets `pres acs` on `me`, which syncs their list.

**Attaches are counted** (`ClientTinodeSession`): a chat screen and a call can hold the same
topic, and it stays attached until every attach has been matched by a detach. Creating a group
counts as one attach. Closing the chat
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

**Sending** (`SendController(topic)`): puts plain text in the outbox and clears the composer; the
chat shows it with a clock until the server numbers it, or with an error mark if it refuses it.
Only a local failure (no session) keeps the text and shows a snack bar.

**Deleting** (`ChatController.delete`): a long press on a message offers "Delete for me", and
"Delete for everyone" where the user has `D`. A long press on an outgoing message offers Retry
(once failed) and Discard.

## Errors

`ChatFailure.of(error)` maps any error to a small enum the UI can explain
(`unreachable`, `connectionLost`, `badCredentials`, `timeout`, `rejected`, `unexpected`), and
`failureMessage` turns it into the host's `TinodeChatStrings`.

| Where | Shown as |
|-------|----------|
| Connect fails, or the link ends for good | `SessionErrorView` with Reconnect |
| The socket drops and the client is reconnecting | `ReconnectingBanner`; sends wait in the outbox |
| Login fails | Text under the login form; the session keeps waiting for a login |
| Chat list or history fails to load, with nothing cached | `ErrorRetryView` in place of the list |
| The server refuses a message, or it keeps failing | Error mark on its bubble; long press to retry or discard |
| The server refuses a deletion | The messages come back |
| A call fails (permission, busy, link) | Snack bar from `CallLayer`; the call screen says why for 2 s |
| A search fails, e.g. offline | `ErrorRetryView` in place of the results; it searches again on connect |
| The server refuses a new group, or some of its members | Snack bar; the group screen stays, or the group opens |

Providers report failures in their state (`LoadStatus.failed`, `AsyncError`); widgets never catch.

## Public API

Only what `lib/tinode_flutter_chat.dart` exports is public: `TinodeChat`, `TinodeChatController`,
`TinodeCredentials`
(`PasswordCredentials`, `TokenCredentials`), `TinodeChatTheme`, `TinodeChatStrings`, and the
client's `TinodeConfig` and `LoginResult`. Everything else may change freely. Every exported symbol
carries dartdoc. Adding an export is an API decision: keep the list short.
