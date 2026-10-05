# Glossary

The Tinode words (session, topic, subscription, attach, chat list, member, peer, profile, seq,
read and received markers, access mode…) are defined in the client's glossary:
[`../tinode_dart_client/docs/glossary.md`](../../tinode_dart_client/docs/glossary.md). Use those
terms here too, with the same "avoid" rules:

- **Chat list**, not "contacts": groups and channels are in it too.
- **Attach / detach** for the live link to a topic (`sub` / `leave`). "Subscription" is the lasting
  relationship; don't say "subscribe" when you mean attach.
- **Profile**, not "card" (Tinode's docs call it theCard).
- **Direct** chat for P2P (`TopicKind.direct`).

## UI terms

**Chat**
One topic the user takes part in, as the UI shows it: a direct chat, a group or a channel.

**Chat list screen / chat screen**
The list of the user's chats, and one open chat.

**Chat summary**
What the list knows about one chat: title, last message time, `lastSeq`, `read`, whether the user
may write. *In code:* `ChatSummary`.

**Tile**
One row of the chat list. *In code:* `ChatListTile`.

**Bubble**
One message on the chat screen. *In code:* `MessageBubble`.

**Composer**
The message field and send button. *In code:* `Composer`, `SendButton`.

**Unread count / unread badge**
`lastSeq − read`, never negative, shown as a badge on the tile.

**Own message**
A message the logged-in user sent (`from` is their user ID). Shown on the right.

**Read-only chat**
A chat the user can't post to: a channel they follow, or a topic without the `W` permission. The
composer is replaced by a notice. *In code:* `ChatSummary.canWrite`, `ReadOnlyNotice`.

**Session phase**
Which screen the session gate shows: connecting, awaiting login, logged in, failed.
*In code:* `SessionPhase`.

**Failure**
An error put in terms the UI can explain. *In code:* `ChatFailure`.

**Live model**
A provider whose state follows server events as they arrive (chat list, open chat), as opposed to a
one-shot load.
