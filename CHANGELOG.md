## Unreleased

- Push notifications, from `tinode_dart_client` 0.9.0. `TinodeChat(pushToken:)` takes the device
  token from the host's push service: it is registered for whoever logs in, sent again when the
  host rebuilds with a new one, and removed from the server when the user logs out (account
  deletion drops it on the server's side). The package depends on no push service.
- The config's push platform defaults to the device's (Android, iOS or web).
- `TinodeChatController.openChat(topic)` opens a chat over the chat list, e.g. for a tapped
  notification. Called before the widget is built or before login, it waits for them.
- The package also exports `TinodePush` (`MessagePush`, `SubscriptionPush`, `ReadPush`) to read
  pushes in the host's background handler, and `DevicePlatform`.

- Account and profile, from `tinode_dart_client` 0.8.0. The login screen links to signing up (name,
  login and password; it logs in as the new user, so `onLoggedIn` hands over the token as after any
  login) and to resetting a forgotten password (a code sent to the account's email, then the new
  password; asking again while a code is valid goes on with that one). The chat list's menu opens a profile screen that edits the name and note, sets a new
  photo (picked like an attachment, uploaded and set by reference), changes the password and,
  optionally, the login, and deletes the account after asking, which ends the session like a log
  out. These need the network.
- Email confirmation: sign-up asks for an email, required where the server needs one (servers
  that send mail usually do) and optional elsewhere. When the server mails a code to confirm it,
  a "Confirm your email" screen takes the code and logs in; a password login of an account still
  to confirm opens it too. A remembered token whose email turns out unconfirmed goes back to the
  login screen. A taken or malformed email, or a wrong code, says so.
- `TinodeChat(features:)` with `TinodeChatFeatures` switches the login screen's extras: `signUp`
  (on by default) and `passwordReset` (`PasswordResetMode.automatic` by default: offered only
  where the server requires an email, the sign that it sends email; `always`; `never`).
- Tapping a chat's title opens its info: a group's members, owner first, with a remove button for
  whoever manages them, and "Delete chat" (1:1, the peer keeps their side), "Delete group" (the
  owner, for everyone) or "Leave group". A chat that is deleted, or that the user is removed from,
  here or on another device, leaves the list and the cache with its unsent messages; an open one
  says it is no longer available.
- Chats removed by a chat list sync take their cached messages along.
- The login screens get their own navigator, so sign-up and reset screens close on login.
- New `TinodeChatStrings`: `createAccountLink`, `signUpTitle`, `displayNameField`, `signUp`,
  `forgotPassword`, `resetPasswordTitle`, `emailField`, `sendResetCode`, `resetCodeSent`,
  `resetCodeField`, `newPasswordField`, `setPassword`, `passwordResetDone`, `profile`, `nameField`,
  `noteField`, `save`, `profileSaved`, `changePhoto`, `changePassword`, `newLoginField`,
  `passwordChanged`, `deleteAccount`, `deleteAccountConfirm`, `chatInfo`, `members`, `ownerLabel`,
  `youLabel`, `removeMember`, `deleteChat`, `deleteChatConfirm`, `deleteGroup`,
  `deleteGroupConfirm`, `leaveGroup`, `leaveGroupConfirm`, `cancel`, `loginTaken`,
  `credentialsRefused`, `wrongResetCode`, `chatGone`, `emailOptionalField`, `confirmEmailTitle`,
  `confirmEmailText`, `confirm`, `emailTaken`, `invalidEmail`, `confirmEmailFirst`, and the
  function `removeMemberConfirm`.

- Attachments, from `tinode_dart_client` 0.7.0. The composer's attach button offers Photo, Camera
  (where the device has one) and File, then a preview with a caption. The file is copied into the
  app's own folder and waits in the outbox like any message: it is uploaded once it is next in
  its chat (so later messages of that chat keep their order, and other chats don't wait), then
  the message goes out with its ref. The bubble shows the image or file with a progress ring; a
  long press cancels the upload. A drop restarts the upload on the next connect; a ref that
  expired meanwhile is uploaded again. A file over the server's `maxFileUploadSize` is refused
  before it is queued, naming the limit, and one the server finds too large fails with
  `ChatFailure.tooLarge`.
- Received images show in the chat, keeping their space while they download, and open full
  screen; received files show their name and size, and a tap downloads them (with progress) and
  opens them with the system's viewer (`open_filex`). Downloads are kept in a per-user cache in
  the OS's cache folder; sent files go there too, so the sender never downloads them. Logging out
  deletes them. Profile photos given by reference (`photo.ref`) show in avatars.
- Captions and plain Drafty text show Drafty line breaks as new lines.
- New dependencies: `image_picker`, `file_picker`, `open_filex`, `mime`, `crypto`.
- New `TinodeChatStrings`: `attach`, `attachPhoto`, `attachCamera`, `attachFile`, `captionHint`,
  `uploading`, `cancelUpload`, `fileTooLarge`, `downloadFailed`, `cannotOpenFile`, `openFile`,
  `imageLabel`, `fileLabel`, and the function `fileTooLargeLimit`.

- Group chat essentials, from `tinode_dart_client` 0.6.0: in groups, the sender's name (in their
  colour) heads each run of their messages and their avatar sits beside its last. The user's own
  messages show two ticks once every other member received them, in the read colour once all of
  them read them; a long press on one in a group lists who read it. Who is typing shows under the
  chat's title, and the composer tells the others while the user types. Messages from others are
  marked received as they arrive, also in chats that aren't open.
- Profile photos sent inline show on chat list tiles, search results and sender avatars, in place
  of the initials.
- The cache keeps each chat's members (schema v2; existing caches migrate on open).
- New `TinodeChatStrings`: `messageDelivered`, `messageRead`, `readBy`, `deliveredTo`,
  `notReadYet`, `unknownMember`, `typingDirect`, and the functions `typingOne`, `typingTwo` and
  `typingMany`.
- **Breaking:** `TinodeChatTheme` has new required `readReceiptColor` and `senderNameColors`
  (`TinodeChatTheme.fallback` uses the color scheme's `primary`, and a palette that suits light or
  dark).

- Finding people and starting chats, from `tinode_dart_client` 0.5.0: a button on the chat list
  opens a search for people and groups (by login, email, phone or tag). Tapping a result opens the
  chat, creating a 1:1 chat the first time. "New group" creates a group with a name and members
  picked from the same search. Searching needs the server: offline it says so and searches again
  once the link is back.
- The chat list picks up a chat the user was added to (`pres acs`), and one the user just started.
- New `TinodeChatStrings`: `newChat`, `findHint`, `nobodyFound`, `groupLabel`, `channelLabel`,
  `newGroup`, `groupNameField`, `addMembersHint`, `createGroup`, `membersNotAdded`.
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
