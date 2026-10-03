# Notes: tinode_flutter_chat

Reminders from the October 2026 exploration that led to this package.

## Goal

- A ready-made chat UI that any Flutter app can drop in with minimal setup.
- Tinode-specific by design, built on the sibling package `../tinode_dart_client`
  (a pure-Dart client for the protocol, offline store and local search).
- Not wired yet: add `tinode_dart_client` as a dependency (a local path dependency at first)
  when the first real code lands. Publishing to pub.dev later means switching it to a hosted version.

## What the UI has to cover

- Chat list from the `me` topic (contacts, unread counts, last message).
- 1:1 chats (`usr…`) and groups (`grp…`): sender names, read and received receipts, typing indicator.
- Channels (`chn…`): one-way broadcast like Telegram or WhatsApp channels, read-only for followers,
  and messages arrive without a sender.
- Message rendering: content is "Drafty", either a plain string or JSON with text in `txt` plus
  formatting and attachments.
- Search: on-device only (SQLite FTS5 in the client package). The server can't search message text;
  it can only find users and groups by tags (`fnd`).
- Offline: show cached history and queue unsent messages; sync happens in the client package.

## Trying it

- Server: `../tinode-tests` → `docker compose up -d`, web UI at http://localhost:6060/.
- Users: `alice` / `alice123`, `bob` / `bob123`, … (password = name + `123`).
- Demo API key: `AQEAAAABAAD_rAp4DJh05a1HAwFT3A6K`.
- From the Android emulator the host is `10.0.2.2`, not `localhost`.
- `example/` is the default Flutter app, ready to host the widgets.

## Push notifications

- The server sends through FCM; each app needs its own Firebase project and credentials.
- 1:1 and group pushes use FCM HTTP v1 (fine). Pushes to channel followers rely on the
  legacy Firebase SDK's topic subscriptions, which stop on 2027-09-29.

## Context

- Server: Tinode (Go, GPL-3.0), active (v0.25.3, Jul 2026) but mostly one maintainer.
  Paid support is available from Tinode LLC.
- We chose it over ejabberd: ejabberd has server-side message search (MySQL only), but no solid
  Flutter XMPP library, and XMPP is much heavier to implement ourselves.
