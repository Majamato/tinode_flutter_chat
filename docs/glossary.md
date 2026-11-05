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
may write, whether it is online and muted. *In code:* `ChatSummary`.

**Online**
The other user of a direct chat has a session open. Live only (`pres on` / `off`), never cached.
Shown as the online dot on the tile's avatar and "online" under the chat's title. Groups have no
presence in the UI. Not shown, and not kept, while the host turns presence off; not shown for a
peer who hides it (see **Presence**). *In code:* `ChatSummary.online`, `ChatOnlineDot`,
`ChatStatus`.

**Last seen**
When the other user of a direct chat was last online: the server's `seen.when`, or now when
`pres off` arrives; it never moves back. Shown under the chat's title while they are offline:
"last seen today at 14:05", "… yesterday at 14:05", "… Mar 3". Cached, unlike online, and
refreshed from the chat's description when it opens. *Avoid:* "last connection".
*In code:* `ChatSummary.lastSeen`, `ChatStatus`.

**Presence**
Online and last seen together. Two separate switches:
- the host's `TinodeChatFeatures.presence`: whether the app shows anyone's. Off, the package
  drops it as it arrives (`CachedTinodeSession.keepsPresence`).
- **Show my online status**, the user's: whether others see theirs. Off, their profile's
  `public` carries `"x-presence": "hidden"` and this package shows no presence for them
  (`ChatSummary.presenceHidden`); on, `"shown"`, since the server merges `public` and keeps a
  key left out. A request only: their presence still reaches others, and
  other Tinode apps may show it. *In code:* `PresenceVisibility` (`hidesPresence`,
  `withPresenceHidden`), `PresenceVisibilityController`, `myPresenceShownProvider`,
  `PresenceTile`.
*Avoid:* "invisible mode": the server still tells others.

**Muted**
The user turned off notifications for a chat: their `want` lacks presence (`P`), so the server
sends no push. Not "silenced". *In code:* `ChatSummary.muted`.

**Tile**
One row of the chat list. *In code:* `ChatListTile`.

**Preview**
The tile's second line: the chat's newest cached message (its text, or an icon and label for a
photo, file, voice message or call; "You" first for the user's own message in any chat, the
sender first in a group), or who is typing. Read from the cache, which the **latest catch-up**
fills from the server. When the chat has messages past it (**behind**), until then or while
offline, the line says "New message" if unread, else nothing. *In code:* `ChatPreview`,
`ChatPreviewController`, `ChatPreviewLine`.

**Bubble**
One message on the chat screen. *In code:* `MessageBubble`, `OutgoingBubble`, `BubbleFrame`.
A host may wrap or replace it with `TinodeChat.bubbleBuilder`, which gets a `TinodeBubble`.

**Run**
Messages from one sender in a row, each within 5 minutes (`runGap`) of the one before. The
first of a run names the sender in groups and has a wider gap above it; the last has the tail
and, in groups, the avatar. The user's newest numbered message and the outbox make one run.
*In code:* `MessageRun`, `messageRunProvider`, `outgoingRunProvider`.

**Tail**
The small point at the bottom corner of the last bubble of a run. *In code:* `BubbleTail`.

**Date chip**
The date above the first message of a day ("Today", "Yesterday", or the date).
*In code:* `DateChip`, `ChatState.startsDay`.

**Wallpaper**
Behind a chat's messages: a flat color.
*In code:* `ChatWallpaper`, `wallpaperColor`.

**Glass**
A floating, translucent piece that blurs what scrolls under it: the app bar's buttons and
title pill, the composer's attach button, field and send button, and the tab bar. All the glass
of a screen shares one backdrop. *In code:* `GlassSurface`, `GlassIconButton`.
*Avoid:* "frosted bar": there are no bars, only glass over the content.

**App bar**
The row of glass at the top of a screen (chat list, calls history, settings, appearance, a
chat), over an **edge fade** of the screen's background. Content scrolls under it and starts
below it. The host can wrap or replace it per screen. *In code:* `TinodeAppBar`, `EdgeFade`,
`GlassScaffold`, `TinodeChat.appBarBuilder`, `TinodeScreen`.
*Avoid:* "header" for the bar itself (the chat's is `ChatHeader` for history).

**Tab bar**
The floating glass bar with the chats, the calls history and the settings, on by default
(`TinodeChat.tabBar`). Its current tab sits on a sliding **lens**. *In code:* `HomeScreen`,
`HomeTab`, `HomeTabBar`.

**Calls history**
The calls of direct chats the cache holds, newest first, in its own tab; not "call log". *In
code:* `CallHistoryController`, `CallHistoryEntry`, `CallsScreen`.

**Appearance**
The palette and the light, dark or system theme the user picks on this device, from the host's
palettes. *In code:* `TinodeAppearance`, `AppearanceScreen`.

**Composer**
The round attach button, the message field and the round send button, glass floating over the
messages above the keyboard; the send button fills with the brand color once there is text.
*In code:* `Composer`, `ComposerDock`, `SendButton`.

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

**Reconnecting title**
While the client restores a dropped link, or connects after an offline start, the chat list's and
calls history's titles turn into a spinner and "Reconnecting…", and so does the line under a
chat's name. It shows only once the link has been down for 1 s. The screens stay as they were;
what the user sends meanwhile waits in the outbox.
*In code:* `ReconnectingTitle`, `ReconnectingNotice` (the 1 s grace), `ReconnectingController`
(the link itself, which also disables a lost call's Call again at once), `ChatStatus`.
*Avoid:* "reconnecting banner" or "strip": nothing is added to the screen.

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

**Latest catch-up**
Keeping the end of each chat in the cache as the server has it, for the previews: after each chat
list sync, and a moment after a `pres msg`, the session attaches each chat whose `lastSeq` is past
what the cache covers, catches it up and detaches, newest chats first, a few at a time. It fetches
the members a preview needs too: a group's sender, the counters for the user's own message.
*In code:* `CachedTinodeSession` (`_queueLatest`, `latestDelay`).

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

**Prune**
Shrinking the cache once each time a user's chats open: each chat keeps its newest messages
(the rest are uncovered, so they load from the server again), chats that left the list lose
theirs, and the file cache drops the files used longest ago until it fits.
*In code:* `ChatStore.prune`, `FileStore.prune`, `CachedTinodeSession` (`_prune`).
*Avoid:* "clean", "evict".

**Cache limits**
How much pruning keeps: messages per chat (1000 by default) and the size of the file cache
(200 MiB). The host sets them. *In code:* `TinodeCacheLimits`, `TinodeChat.cacheLimits`.

**Log out**
Ends the session for good: deletes the user's cache, including unsent messages, and forgets the
credentials. *In code:* `SessionController.logout`, `TinodeChatController.logOut`, `onLoggedOut`.

## Account and profile

**Sign up**
Creating an account from the login screen's Sign up side with a name, a login and a password; it
logs in as the new user. *In code:* `SessionController.signUp`, `SignUpController`, `SignUpForm`,
`AuthModeSwitch`.
*Avoid:* "register".

**Account features**
What the login screen offers besides logging in: signing up, and resetting a forgotten password.
The host switches them (`TinodeChatFeatures`); the reset defaults to servers that require an
email. *In code:* `signUpOffered`, `passwordResetOffered`.

**Confirm email**
Entering the code the server mailed to the email given at sign-up. Servers that send mail usually
require an email, and an account can't log in until it is confirmed. *In code:*
`ConfirmEmailController`, `ConfirmEmailScreen`, `signUpNeedsEmail`; the client's
`CredentialsRequiredException`.

**Password reset**
Setting a new password for a user who forgot it: the server emails a code to the account's address,
and the code sets the new password. It doesn't log in. *In code:* `PasswordResetController`,
`PasswordResetState`, `PasswordResetScreen`.

**Profile**
What others see of the user: name, note and photo, the `public` of `me`. Edited on the profile
screen, online only. *In code:* `MyProfile`, `ProfileController`, `ProfileScreen`.
*Avoid:* "card".

**Change password**
A new password, and optionally a new login, for the logged-in user; the session goes on.
*In code:* `ChangePasswordController`, `ChangePasswordScreen`.

**Delete account**
Deletes the user on the server, then ends the session like a log out. *In code:*
`SessionController.deleteAccount`, `DeleteAccountController`.

**Chat info**
The screen about one chat, opened from its title: a group's members, and the way out of the chat.
*In code:* `ChatInfoScreen`, `ChatActionsController`.

**Delete chat / delete group / leave group**
The way out of a chat (`ChatExit`): a 1:1 chat is deleted for the user (the peer keeps their side);
the owner deletes a group for everyone; other members leave it, on every device. Either way it
leaves the chat list and the cache.

**Remove a member**
Taking someone out of a group, which needs `A`; nobody removes the owner, and nobody removes
themselves (they leave). *In code:* `ChatActionsController.removeMember`, `memberRemovable`.

**Gone chat**
A chat that was deleted, or the user removed from it, maybe on another device (`pres gone`). It
leaves the list and the cache; an open one says it is no longer available. *In code:*
`ChatFailure.gone`.

## Starting chats

**Search**
Finding people and groups to chat with, by their tags, as the user types. It needs the server.
*In code:* `FindController`, `FindState`. The client's term is `fnd`; see its glossary.
*Avoid:* "contacts". A result isn't in the chat list until a chat with it exists. The chat
list's search button opens it (`FindPeopleButton`). Finding messages is **message search**,
never plain "search".

**Search result**
A user or group the search found, shown as a tile. A user's result is named by their user ID,
which also names the 1:1 chat with them. *In code:* `SearchResult`, from the client's `FoundTopic`.

**Find scope**
Which screen a search belongs to: the new chat search, or the member search of a new group.
*In code:* `FindScope`.

**New group**
A group the user creates with a name and members picked from a search; the user owns it.
*In code:* `NewGroupController`, `NewGroup` (with the members not added).

**Add a member**
Making a user a member of a group (`set sub` on the wire), which needs `S`. The member can read the
group at once. *Avoid:* "invite"; Tinode's docs use it, but nothing waits for an answer.

## Message search

**Message search**
Finding messages of one chat by their words in the cache, as the user types, from the search
button in the chat's app bar. Every word must start a word of the message; accents don't count ("cafe" finds "café").
Tinode has no message search, so it needs no network and finds only what the cache keeps.
*In code:* `MessageSearchController`, `MessageSearchState`, `messageMatch`,
`ChatSession.searchMessages`, the `message_search` table.
*Avoid:* plain "search" (that finds people), "find" (the client's `fnd`).

**Found message**
A message that message search found, shown as a tile with its sender, its time and a snippet. *In code:* `FoundMessage`, `FoundMessageTile`, `FoundSender`.
*Avoid:* "search result" (`SearchResult` is a person or group).

**Snippet**
The words around what matched, the matches marked. *In code:* `MessageSnippet`, `SnippetPart`,
`MessageSnippetText`.

**Reveal**
Showing one message in its chat: loading back to it if needed, scrolling to it and highlighting
it for a moment. A message that can't be had (deleted, or offline and not cached) is
**unavailable**. *In code:* `ChatController.reveal`, `MessageReveal`, `RevealStatus`,
`RevealHighlight`.
*Avoid:* "jump to", "scroll to" for the whole flow.

## Group chats

**Members**
The users of a chat, as the chat knows them: name, photo and read and received counters. Fetched
in full each time the chat attaches, kept in the cache, and kept current from the other members'
markers. *In code:* `ChatMembers`, `ChatMember`, `ChatMembersController`.

**Run**
Messages from one sender in a row, each within 5 minutes of the one before. In a group, the
**sender label** (their name, in their colour) heads a run's first bubble and their avatar sits
beside its last. *In code:* `ChatState.startsRun`, `endsRun`, `MessageSender`, `SenderName`,
`SenderAvatar`.

**Receipt**
How far one of the user's own messages got, shown as ticks: **sent** (one), **delivered** (two:
every other member who may read received it, or read it) and **read** (two in the read colour:
every one of them read it). In a direct chat that is the peer; a channel's messages stay sent.
*In code:* `MessageReceipt`, `ChatMembers.receiptOf`.
*Avoid:* "seen".

**Read by**
The list, from a long press on the user's own group message, of the members who read it and of
those who only received it. *In code:* `ReadBySheet`, `ChatMembers.readBy`.

**Typing indicator**
Who is typing, under the chat's title. A member stops typing 5 s after their last key press or
when their message arrives; the user's own typing goes out at most every 3 s.
*In code:* `TypingController`, `TypingMembers`, `TypingIndicator`.

**Received marker**
`note recv`: this device has the messages up to a seq. Sent for each message from someone else as
it arrives (live, or as `pres msg` for a chat that isn't attached), and after each chat list sync
for what came while away. Not queued offline. *In code:* `TinodeSession.markReceived`.

## Attachments

**Attachment**
An image or file in a message: a Drafty `IM` (shown in the bubble) or `EX` (shown as its name and
size; audio and video read as files too), sent inline (`val`) or as a `ref` to an **upload**.
*In code:* `MessageAttachment` (`ImageAttachment`, `FileAttachment`), `ChatMessage.attachments`;
the text beside it is the **caption** (`ChatMessage.caption`).

**Upload**
Sending an attachment's file to the server over HTTP before its message goes; the server answers
with the file's `ref` and a deadline for a message to use it.
*In code:* `TinodeSession.upload`.

**Uploader**
The part of the outbox that uploads attachments, one at a time, each once its message leads its
chat, beside the drain that sends messages. *In code:* `CachedTinodeSession` (`_runUploads`).

**Staged file**
A copy of a file the user picked, kept in the app's own folder until the server has the message:
picker files can vanish. *In code:* `FileStore.stage`, `OutgoingAttachment.stagedId`.

**File cache**
Downloaded files, and files the user sent, kept by their URL in the OS's cache folder (which the
OS may clear), one store per user beside the chat cache. *In code:* `FileStore`,
`ChatSession.fetchFile`, `attachmentFile`.

**Kept file**
A voice message's recording, sent or received, kept by its URL in the app's own folder rather
than the file cache: neither the OS nor pruning clears it, and it goes with its message, its chat,
or at logout. Playback only ever opens it, never the server's copy. *In code:*
`ChatSession.fetchFile` (`keep`), `FileStore.forget`, `voiceFile`.

**Recording panel**
What takes the composer's place while a voice message records: the recorded time and the live
waveform on top, then delete, pause or resume, and send. *In code:* `RecordingPanel`.

**Live waveform**
The waveform of a voice message as it records, one bar per level on a fixed loudness scale,
scrolling left as levels come. Not the bubble's waveform, which is drawn from the sent preview.
*In code:* `LiveVoiceWaveform`, `liveBarOf`.

**Recorded time**
How long a voice message being recorded has recorded, not counting its pauses: what the panel
shows, what is sent as its duration, and what counts towards the ten-minute limit.

**Upload progress**
How much of an attachment's file has gone to the server, reported a few times a second at most and
never stored. *In code:* `UploadProgress` (outbox event), `UploadProgressController`,
`UploadProgressRing`.

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

**Voice call / video call screen**
The call screen of each kind, always dark. *In code:* `VoiceCallView`, `VideoCallView`, both
under `CallView`.

**Minimized call / call bar**
A call the user shrank, with the chevron or Back, to use the chats meanwhile: a bar above the chat
routes shows it, and a tap brings it back. Each call starts full screen; a ringing call can't be
minimized. *In code:* `CallMinimized`, `CallBar`, `CallMinimizeButton`.

**Reconnecting (call)**
The WebRTC link between the two devices dropped during a connected call and may come back by
itself; the call goes on. Not the session's reconnecting, which the reconnecting title shows: a
dropped session ends the call. *In code:* `ActiveCall.reconnecting`, `CallReconnectingPill`.

**Lost call**
A connected call that ended because a connection dropped: the WebRTC link stayed down for
`callReconnectTimeout` or failed (`CallFailure.callLost`), or this device lost the chat server
(`CallFailure.connectionLost`). Its screen offers Call again. A call can never continue over a
new session: the Tinode server keeps a call's parties by session ID and ends the call when one
of those sessions goes. *In code:* `CallLostActions`, `CallController.callAgain`.

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

**System call screen**
The phone's own call screens: CallKit on iOS, a self-managed Telecom connection on Android, with
its ringing notification and ongoing call notification. Every call is reported there, and what the
user does there (accept, decline, hang up, mute) comes back to the call controller. On Android it
also holds the microphone and camera in a foreground service while the call goes on.
*In code:* `SystemCalls` (interface), `CallKitSystemCalls`, `NoSystemCalls`, `FakeSystemCalls` in
tests; the host turns it off with `TinodeChatFeatures.systemCalls`. The host can also turn off
each kind of call (`voiceCalls`, `videoCalls`): no button, and no ringing for it here.
*Avoid:* "native call UI", "CallKit" for both platforms.

**Accepted from the system**
A call the user accepted on the system call screen that this session didn't know: rung by a push
while the app was closed or its session suspended. It shows as connecting at once, waits for the
session to connect, and joins if the call still waits, or ends. *In code:*
`CallController` (`_acceptFromSystem`), `SystemCalls.accepted`, `CallResources.awaitingServer`.

**Call push**
A push about a call: `webrtc: started` for one that rings, later states as replacements of the call
message. Always `silent`. The host hands it to `TinodeCalls.handlePush` from its background
handler. *In code:* `TinodeCalls`, `handleCallPush`, `callPushLifetime`.

**Background hang-up**
Declining on the system call screen while the app is closed: a background isolate logs in with the
token the push handler was given and hangs up, so the caller sees it declined at once (Android).
*In code:* `hangUpDeclined`, `hangUpFromBackground`, `HangUpCredentials`.

## Push

The client's glossary defines **device token** (`dev`), **platform** (`platf`) and the **push
payload**.

**Push token**
The host's device token, passed to `TinodeChat(pushToken:)`. Registered for whoever logs in,
removed from the server on log out. *In code:* `PushTokenController`, `PushRegistration`.
*Avoid:* device ID.

**Requested chat**
A chat the host asked to open, e.g. from a tapped notification. It waits for the widget and a
login, then opens over the chat list. *In code:* `TinodeChatController.openChat`,
`RequestedChatController`.
