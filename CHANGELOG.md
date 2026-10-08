## Unreleased

- Offline, from `tinode_dart_client` 0.4.0: each user's chats are kept on the device (SQLite via
  `drift`, one file per server and user). The chat list and the chats show from the cache at once
  and then sync only what changed: new messages, deletions (the delete log), updated chats
  ("if modified since").
- Offline start: with the token of the user who last logged in, `TinodeChat` opens their chats
  without waiting for the server and logs in in the background.
- An outbox: messages sent while the link is down wait with a clock and go out once it is back,
  never twice (each carries a client ID that is looked up on the server after a drop). Refused
  messages show an error mark; a long press retries or discards them. Read markers made offline
  reach the server later.
- Deleting messages: a long press offers "Delete for me", and "Delete for everyone" where the user
  has the `D` permission.
- Logging out: a menu on the chat list, `TinodeChatController.logOut` for the host, and
  `TinodeChat.onLoggedOut` to forget the saved token. It deletes the user's cache.
- New `TinodeChatStrings`: `logOut`, `messageWaiting`, `messageSent`, `messageNotSent`,
  `discardMessage`, `deleteForMe`, `deleteForEveryone`.
- Sending no longer fails while reconnecting: the composer clears and the message waits.
- New dependencies: `drift`, `drift_flutter`, `path_provider`.
- Automatic reconnect, from `tinode_dart_client` 0.2.0: a dropped socket shows a "Reconnecting…"
  banner instead of the error screen. Afterwards the chat list reloads and an open chat fetches
  what it missed. A token the server no longer accepts goes back to the login screen.
- The socket closes 15 s after the app is hidden and reconnects when it is shown again.
- Network changes reported by the OS (`connectivity_plus`) make the client check its socket
  within about 5 s, or retry at once when the network comes back, instead of waiting up to 30 s.
- `TinodeChatStrings.reconnecting`.
- 1:1 voice and video calls (`flutter_webrtc`), from `tinode_dart_client` 0.3.0: call buttons in
  direct chats, a ringing screen over every route, and a call screen with mute, camera,
  front/back camera, speaker and hang-up. Calls ring only while the app is open. Call messages
  show as call bubbles that follow the server's updates; replaced messages update their bubble
  instead of adding one.
- The session stays open in the background while a call runs.
- New `TinodeChatStrings` for calls (`voiceCall`, `videoCall`, `acceptCall`, `hangUp`, …).
- **Breaking:** `TinodeChatTheme` has a new required `missedCallColor`
  (`TinodeChatTheme.fallback` sets it to the color scheme's `error`).
- Host apps must declare camera and microphone access to make calls; see the README.

## 0.1.0-dev.1

- `TinodeChat`: connect, built-in login (or `TinodeCredentials`), chat list with unread counts,
  chats with history paging, live messages, plain-text sending and read markers.
- Read-only view for channel followers.
- `TinodeChatTheme` and `TinodeChatStrings` for styling and texts.
