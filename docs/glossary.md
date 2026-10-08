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
- **Call**, **call event**, **call state**, **ICE server**: as in the client's glossary, section
  Calls. Calls exist only in direct chats.

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

**Reconnecting banner**
The strip under the chats while the client restores a dropped link, or connects after an offline
start. The screens stay as they were; what the user sends meanwhile waits in the outbox.
*In code:* `ReconnectingBanner`, `ReconnectingController`.

**Network hint**
A network change reported by the OS. It is not proof of anything: it only makes the client check
its socket sooner (a quick probe) or stop waiting to retry. *In code:* `NetworkMonitor`,
`NetworkPolicy`.

**Background grace**
How long the socket stays open after the app is hidden (15 s) before the session is suspended.
*In code:* `BackgroundPolicy`, `backgroundGrace`.

**Live model**
A provider whose state follows server events as they arrive (chat list, open chat), as opposed to a
one-shot load.

## Offline

**Cache**
The copy of the user's chats on the device: the chat list, the messages fetched so far and the
outbox, in one SQLite file per server and user. It is never the truth: the server is, and the
cache can be deleted at any time without losing anything but unsent messages.
*In code:* `ChatStore`, `ChatDatabase`, `ChatStoreOpener`.
*Avoid:* "database" in UI terms; "store" is the code's word for it.

**Covered range**
Seqs of a chat the cache has fetched from the server. A covered seq that is not stored was deleted
or never existed; an uncovered one may be on the server. Live messages extend the coverage only
when they follow it, so a gap never hides.
*In code:* `SeqRanges`, `ChatStore.coverage`.

**Gap**
Uncovered seqs between covered ones. Older pages come from the cache where it covers them and
from the server for the gaps only.

**Catch up**
After the chat opens or the link comes back: fetch what arrived after the newest cached message,
then the deletions made since the last applied one (the **delete log**). When more arrived than a
page holds, the chat starts over from the newest page and pages back from there.
*In code:* `ChatSession.catchUp`, `CatchUp.gap`.

**Offline start**
Opening the app for the user who last logged in to this server, with their token, without waiting
for the server: their cache shows at once, and the client connects in the background.
*In code:* `TinodeClient.restore`, `SessionRestorer`, `ChatStoreOpener.lastUser`,
`SessionLoggedIn.login` (null until the server answers).

**Outbox**
What the user did that the server has not taken yet, in order: messages to send, deletions,
read markers. It survives restarts and goes out when the link allows.
*In code:* the `outbox` table, `OutboxEntry`, `ChatSession.send`.

**Outgoing message**
A message in the outbox, shown below the numbered ones with its status: **waiting** (a clock),
or **not sent** (an error mark) when the server refused it or it kept failing. The user can retry
or discard it. Once the server takes it, it becomes an ordinary message with a seq.
*In code:* `OutgoingMessage`, `OutgoingStatus`, `OutgoingBubble`.

**Client ID**
A random ID each outgoing message carries in its head (`x-tinode-flutter-chat-cid`). Tinode has no
idempotency key: after a drop the outbox looks for this ID on the server before sending again, so a
message never arrives twice.
*In code:* `clientIdHeadKey`, `ChatMessage.clientId`.

**Delete for me / for everyone**
A soft delete hides messages for the user on all their devices; a hard one deletes them for all
members and needs the `D` permission. Both show at once and go to the server through the outbox.
*In code:* `ChatController.delete`, `ChatSummary.canDeleteForEveryone`.

**Log out**
Ends the session for good: deletes the user's cache, including unsent messages, and forgets the
credentials. *In code:* `SessionController.logout`, `TinodeChatController.logOut`, `onLoggedOut`.

## Calls

**Call stage**
Where this device's call stands: preparing, calling, ringing, incoming, connecting, connected,
ended. Not the server's **call state**, which the call message records.
*In code:* `CallStage`, `ActiveCall.stage`.

**Accept / decline**
What the user does with a ringing call. Declining is a hang-up before the call was accepted.
*Avoid:* "answer" for the user's action; the **answer** is the callee's WebRTC reply to the offer.

**Invite check**
How a call reaches a chat this session isn't attached to: `pres msg` on `me` makes the call
controller attach that chat and read the new message; if it starts a call nobody answered yet, it
rings and keeps the chat attached. *In code:* `CallController`, `CallInvite.findIn`.

**Call layer**
The ringing screen or the call screen, drawn over every chat route. *In code:* `CallLayer`,
`IncomingCallView`, `CallView`.

**Call record / call bubble**
How a call message shows in the chat: direction, voice or video, and how it went (duration,
missed, no answer, declined). The server's updates change this bubble instead of adding new ones.
*In code:* `CallRecord`, `ChatMessage.call`, `CallBubbleContent`.

**Call media**
The microphone, camera and WebRTC link of one call. *In code:* `CallMedia` (interface),
`WebRtcCallMedia`, `FakeCallMedia` in tests.

**Answered elsewhere**
Another device of the same user took the call; this one stops ringing without showing an ended
call.
