## Unreleased

- Automatic reconnect, from `tinode_dart_client` 0.2.0: a dropped socket shows a "Reconnecting…"
  banner instead of the error screen. Afterwards the chat list reloads and an open chat fetches
  what it missed. A token the server no longer accepts goes back to the login screen.
- The socket closes 15 s after the app is hidden and reconnects when it is shown again.
- Network changes reported by the OS (`connectivity_plus`) make the client check its socket
  within about 5 s, or retry at once when the network comes back, instead of waiting up to 30 s.
- `TinodeChatStrings.reconnecting`.

## 0.1.0-dev.1

- `TinodeChat`: connect, built-in login (or `TinodeCredentials`), chat list with unread counts,
  chats with history paging, live messages, plain-text sending and read markers.
- Read-only view for channel followers.
- `TinodeChatTheme` and `TinodeChatStrings` for styling and texts.
