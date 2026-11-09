## Unreleased

- **Behaviour change:** icons follow one standard. What you can tap is near-black, what only
  informs is grey, and the brand color marks only what is selected or primary. The back button,
  settings rows and sheet rows lose their brand or multicolored tints, and chrome icons are all
  24 px.
- **Breaking:** `TinodeChatTheme`'s constructor requires `iconColor` and `iconPassiveColor`.
- **New:** videos. The attach menu's first row, Photos on iOS and Gallery elsewhere, picks a
  photo or a video, and Camera opens an in-app camera that takes either (CamerAwesome), saving
  what it takes to the device's photos. Videos are sent as Tinode's `VD` with an inline poster,
  their length and size, and show as their poster with a play button; a tap downloads and plays
  them full screen.
- **New:** photos and videos are compressed on the device before they go: photos to a 2048 px
  JPEG, videos to an H.264 MP4 at about 720p. A video must fit 20 MiB once compressed (or the
  server's limit, when lower); one that clearly can't is refused at once, naming the longest that
  fits. `TinodeChat.attachmentLimits` (`TinodeAttachmentLimits`) adjusts all of it.
- **New:** the bubble of a photo or video shows at once, with "Compressing… 42%" and then
  "Uploading… 67%" over it. Compression is part of the outbox: it carries on when the user leaves
  the chat, works offline, and starts again if the app is closed meanwhile.
- **Fix:** the picture a sent photo or video shows until its own is ready is freed as soon as its
  own is on screen, instead of staying in memory until 32 newer ones replace it.
- **Fix:** sending a photo or video no longer jumps. A photo's bubble shows a small poster from
  the start, as a video's does, and keeps it through compression and upload. The sent bubble
  shows the same picture until its own is ready, and a portrait video stored on its side gets an
  upright bubble from the start. In the preview, the photo fades in, the video's controls are in
  place from the start, and the caption keyboard no longer opens by itself.
- **Breaking:** `TinodeChatStrings.attachPhoto` is gone, for `attachPhotos` and `attachGallery`;
  there are new strings for videos, compression and the camera.
- **New:** `TinodeVideoPlayerScreen`, for `appBarBuilder`.
- **Fix:** on Android, Gallery (in the chat and for the profile photo) opens the system photo
  picker over the app, not the file picker, and what's picked comes back. A picker that fails
  again says so again.
- **Hosts:** set `MainActivity` to `android:launchMode="singleTask"`, not `singleInstance`. With
  `singleInstance`, Android opens the photo and file pickers as a separate app and reports them
  cancelled at once. The example and the README now use `singleTask`.

- **Fix:** every screen that can go back shows the same glass back button. Profile, the password
  change, chat info, a new group, the attachment preview, the image viewer, password reset and
  email confirmation had a plain arrow; Profile showed none of the "‹ Settings" the account and
  appearance screens have. Profile, account, appearance and the password change name the screen
  they go back to; the rest keep the chevron alone. The chat's own chevron takes the link colour.
- **New:** `TinodeBackButton`, the back button for `TinodeAppBar.leading`, with an optional
  label, badge and tooltip, for hosts replacing a bar with `appBarBuilder`.
- **New:** `TinodeAppBar.overlayBrightness`, for a bar on a screen that doesn't follow the theme.
- **New:** `appBarBuilder` also reaches the profile, password change, chat info, find people,
  new group, message search, attachment preview, image viewer, password reset and email
  confirmation screens, through `TinodeProfileScreen`, `TinodeChangePasswordScreen`,
  `TinodeChatInfoScreen`, `TinodeFindPeopleScreen`, `TinodeNewGroupScreen`,
  `TinodeMessageSearchScreen`, `TinodeAttachmentPreviewScreen`, `TinodeImageViewerScreen`,
  `TinodePasswordResetScreen` and `TinodeConfirmEmailScreen`.
- **Breaking:** `TinodeScreen` is sealed, so a `switch` over it without a wildcard must handle
  these new screens.
- **Fix:** a touch outside a text field closes the keyboard, on every screen, including a touch
  that starts a scroll. The composer's attach and send buttons count as its field, so sending
  leaves the keyboard open.
- **Fix:** a call screen closes the keyboard when it appears, also when the call rings with no
  touch at all. Before, it stayed open over the call.
- **Fix:** a last seen too long for the chat's header slides to its end and back, so all of it
  can be read, instead of being cut off. With Reduce motion it stays cut.
- **New:** the chat info of a direct chat shows whether the peer is online, or when they were
  last seen, under their name.
- **Fix:** the Spanish chat info title reads "Información del chat".
- **Fix:** read markers reach the server when a chat opens from the cache. Before, the marker went
  out before the chat was attached, the server didn't take it, and the chat turned unread again
  after a log out or a reinstall. Chats already behind recover the next time they are opened.
- **Fix:** opening a chat whose newest messages were deleted before they were read clears its
  unread count. Before, the count could never reach zero.
- **Fix:** a missed call counts as one unread message, and a call that was answered or declined,
  on any device, as none. The server gives a call a seq for each state, so a missed call counted
  as two and an answered one as three. Edits of a message no longer count either. Messages unread before a call
  stay unread. A state that arrives while the chat isn't open can count for a moment, until the
  background catch-up fetches it.
- **Behaviour change:** the login screen is plain: a title, the form and a button to the other
  side, on the theme's background. The floating bubbles, the rising sheet and the Sign in | Sign
  up switch are gone from the package; an app that wants a designed login draws it.
- **New:** `TinodeChat.loginBuilder` draws the login screen around its working form. It gets a
  `TinodeLoginView` (`form`, `mode`, `onModeChanged`, `signUpOffered`) and the default screen.
  `TinodeAuthMode`, `BubbleTail` and `SlidingSegments` are exported for it. `loginHeader` shows
  only in the default screen.
- **Breaking:** `TinodeChatStrings.loginBubbleHello` and `loginBubbleLater` are removed along with
  the bubbles.
- **Fix:** the chat list's previews come from the server, not only from the cache: after logging
  in again (the cache is gone), after an offline start or a reconnect, and when a message arrives
  in a chat that isn't open, the session fetches the newest messages of each chat behind it, in
  the background. Groups show their sender's name, the members fetched along. Before, a group
  said "New message" until opened, and after a log out every tile was empty.
- **Behaviour change:** the user's own newest message reads "You: …" in every chat, not only in
  groups.
- **Behaviour change:** the Calls tab no longer fetches when it shows, and has no pull to refresh:
  its calls come from the same background catch-up as the chat list's previews, right after
  logging in.
- **Fix:** the Calls tab keeps its calls after logging out and back in. Every call the app sees
  now goes into a call log, a SQLite file of its own per server and user, which pruning doesn't
  touch and which outlives a log out, so the calls show on the next login without asking the
  server. An app updated to this version starts from the calls it has cached. Calls it never saw
  aren't in the log, so a new device shows only what reaches it, and older calls appear as a chat
  is scrolled back to them. Deleted calls, and the calls of chats that go, leave the log.
- **Behaviour change:** logging out no longer deletes everything about the user on the device:
  their call history (who called, when, for how long) stays, in the app's private storage,
  unencrypted like the cache, for that user's next login. Deleting the account deletes it.
- **Behaviour change:** an Account row in the settings, under the profile, opens a new account
  screen with "Change password", "Log out" and "Delete account", in cards like the settings.
  Log out is no longer on the settings tab itself, and the password change and account deletion
  are no longer on the profile. Without the tab bar, the chat list's menu reads Profile, Account,
  Appearance: "Account" opens the same screen and takes the place of "Log out".
- **Behaviour change:** the profile edits only the photo and the name. The "About" field is gone;
  saving keeps the note already on the account as it is.
- **Behaviour change:** changing the password asks for the new password twice and sends it once
  both match ("The passwords don't match." under the second field otherwise). It no longer
  offers a new login: the login stays as it is.
- **API:** `TinodeAccountScreen`, the account screen as `TinodeChat.appBarBuilder` sees it.
  `TinodeChatStrings.account`, `accountSubtitle`, `confirmNewPasswordField` and
  `passwordsDontMatch` hold the new texts; `profileSubtitle` now reads "Name and photo". Removed
  `TinodeChatStrings.noteField` and `newLoginField`.
- **API:** `TinodeChatFeatures.presence` (on by default): whether the chat shows others'
  presence. Off, there is no online dot, no "online" or last seen under a chat's name: the chat
  drops `online`, `seen` and `pres on` / `off` as they arrive, keeps none of it in memory or in
  the cache, and forgets the last seen the cache held. The server still sends presence. It
  doesn't change what others see of the user (see "Show my online status").
- Last seen: under a direct chat's name while the peer is offline, in `outline`: "last seen
  today at 14:05", "last seen yesterday at 14:05" or "last seen Mar 3". It comes from the
  server's `seen`, from `pres off`, and from the chat's description when it opens.
  `TinodeChatStrings.lastSeenToday`, `lastSeenYesterday` and `lastSeenOn` hold the texts.
- "Show my online status" in the settings, on by default: off, the user's profile (`public`)
  carries `"x-presence": "hidden"`, and apps built on this package show no online dot,
  "online" or last seen for them. On again, it carries `"x-presence": "shown"`: the server
  merges `public`, so leaving the key out kept the user hidden. It is saved on the account, so it follows the user to every
  device. Only a request: their presence still reaches others' devices, and other Tinode apps
  may show it (Tinode has no way to hide it but never attaching `me`, which would stop the chat
  list's live updates). A `pres upd` (a peer changed their profile) now syncs the chat list.
  **API:** `TinodeChatStrings.showMyOnlineStatus` and `showMyOnlineStatusFooter`, and
  `TinodeChatIcons.onlineStatus` (`PhosphorIconsRegular.eye`).
- Spanish and French. `TinodeChatStrings.es()` and `TinodeChatStrings.fr()` hold every text in
  those languages (any left out keep that language's default, as with `TinodeChatStrings()`),
  `TinodeChatStrings.forLocale` picks the built-in texts for a locale, and
  `TinodeChatStrings.supportedLocales` lists the languages for `MaterialApp.supportedLocales`.
- **Behaviour change:** `TinodeChat.strings` and `TinodeCalls.handlePush(strings:)` are now
  nullable and default to null: the chat follows the app's locale, and the phone's call screens
  the phone's. Pass `const TinodeChatStrings()` to keep English everywhere. The app's locale
  resolves to Spanish or French only with `flutter_localizations` set up (see the README).
- **Behaviour change:** the chat list has no floating new chat button any more; a new chat
  starts from the header's button, now a plus on a tonal circle (`primaryContainer` under
  `onPrimaryContainer`, like the new group row's, following the palette in light and dark)
  instead of glass. `TinodeChatIcons.newChat` defaults to `PhosphorIconsRegular.plus`, was
  `notePencil`. `TinodeChatStrings.newMessage`, the floating button's tooltip, is no longer
  used.
- **Behaviour change:** the reconnecting strip at the bottom of the chats is gone. While the link
  is down, the titles of the chat list and the calls history turn into a small spinner and
  "Reconnecting…", as in Telegram, and so does the line under a chat's name, ahead of typing and
  "online". It shows once the link has been down for 1 s, so a short network flap shows nothing.
  A host that replaces the app bar with `TinodeChat.appBarBuilder` no longer gets the
  reconnecting state.
- **Behaviour change:** the app bars and the composer are floating glass, as in Telegram.
  Content scrolls under both: at the top a fade of the screen's background with glass
  capsules on it (a chat's back pill with the unread count, a pill with its photo, name and
  status, and its search and call buttons sharing one glass island; "Chats" with the compose
  button and a search pill; "Calls"; "Settings"; "‹ Settings" on Appearance), at the bottom a
  round attach button, a glass field and a round send button floating above the keyboard. The
  messages make room for the composer, keyboard and recording panel in
  the same frame, with no lag.
- The light chat follows the design more closely, in every palette: the wallpaper is a
  greyish tint of the brand (`primary` at 6 % over a light grey,
  `TinodeChatPalette.lightWallpaper`) whose lightness sits between others' white bubbles and
  the own ones, so both stand out from it, own bubbles are a muted tint of `primary` (26 % over
  white, was `bright` at 28 %), and their time and ticks take
  the brand's `ink` instead of grey. The wallpaper is flat, with no dot grid. Dark mode keeps its
  colors.
- **API:** `TinodeChat.appBarBuilder` (`TinodeAppBarBuilder`) wraps or replaces the app bar of
  each screen, told which by a `TinodeScreen` (`TinodeChatListScreen`, `TinodeCallsScreen`,
  `TinodeSettingsScreen`, `TinodeAppearanceScreen`, `TinodeChatScreen(topic)`). `TinodeAppBar`
  is public, to build bars in the same style. `TinodeChatTheme` gains `glassShadowColor`.

- The user's own bubbles in light mode are a light tint of the brand with near-black text,
  as in Telegram and WhatsApp, instead of the brand color with white text; the time is grey
  and read ticks are in the brand color. Dark mode is unchanged. The voice player on an own
  bubble is a brand-colored button with the bubble's color for its icon.
- The status bar's icons follow the theme: dark over light screens (they were white on the
  chat's white header), light over dark ones and over calls.
- **API:** `TinodeChatPalette.bubble`, optional, sets the own bubble in light mode (a dark one
  gets white text); `lightBubble` is the color in use. `TinodeChatTheme` gains
  `actionColor` / `onActionColor` (the send button and others' voice players, which used to
  take `ownBubbleColor`) and `ownAccentColor` (the voice player on own bubbles).
  `materialTheme`'s `colorScheme.primary` is `actionColor`.

- Sheets share one look (attach, message actions, read by, profile photo): Material 3's
  docked sheet with a drag handle, and rows with the icon on a tinted rounded square, deleting
  ones in red, the attach menu's Photo, Camera and File each in its own colour.
- Icons are [Phosphor](https://phosphoricons.com) instead of Material: Regular, with Fill for
  the current tab, the play and pause buttons and hang up, and Bold for the ticks. Adds the
  `phosphoricons_flutter` dependency.
- **API:** `TinodeChatIcons`, passed as `TinodeChat(icons:)`, holds every icon the chat shows,
  one `IconData` per role, so a host can swap one icon or the whole set (Material, Cupertino,
  another package or its own icon font).
- Voice messages. The send button rests on the microphone while the field is blank: a tap
  records, and the composer grows into the recording panel: a blinking dot, the recorded time
  and a live waveform scrolling as the user speaks, then delete, a wide Pause pill (Resume
  while paused) and send. Paused, the clock, the dot and the waveform stop; the duration sent
  and the ten-minute limit count recorded time only. Recordings under two seconds aren't sent;
  at ten minutes one sends itself. Hiding the app (paused or not), leaving the chat or a call
  drops the recording, and there is none during a call. Recordings are AAC (`audio/mp4`, 16 kHz, 24 kbps), sent through the outbox as Tinode's
  `AU` entity with the duration and a 96-value loudness preview, as TinodeWeb and Tindroid send
  them; theirs play here too.
- Voice messages show as a bubble with a play button, thin bars from the preview across its
  width that fill as it plays, a playhead dot that glides along them, and the duration or
  position. They play only from a file on the device: a received one downloads when its bubble
  shows and plays once it is there; the user's own plays once the server has it, from the
  recording. One plays at a time; a tap on the bars seeks, and a drag moves the dot and seeks
  where it is let go. Seeks run one at a time and quick taps end at the last; while playing,
  the dot never steps back. A call or a recording stops it. Voice files are kept apart from the file
  cache, in the app's support folder: neither the OS nor `fileCacheBytes` clears them, and they
  go with their message, its chat, or at logout.
- Needs `tinode_dart_client` 0.10.0 (`DraftyAudio`), and adds the `record` and `just_audio`
  dependencies. Hosts declare the microphone (see the README's voice messages setup).
- **API:** `TinodeChatFeatures(voiceMessages:)`, true by default; off, the send button rests
  disabled as before, and received voice messages still play. `TinodeBubbleKind.voice` for the
  bubble builder.
- **API:** `TinodeChatTheme` gains `recordingColor` (the recording dot and the delete button).
- New `TinodeChatStrings`: `recordVoiceMessage`, `sendVoiceMessage`, `deleteRecording`,
  `pauseRecording`, `resumeRecording`, `recordingVoiceMessage`, `playVoiceMessage`,
  `pauseVoiceMessage`, `microphoneDeniedForVoice`, `voiceMessageTooShort`, `cannotRecordDuringCall`, `cannotPlayVoiceMessage`, `recorderFailed`.

- **Behaviour change:** the chat now opens in a floating glass tab bar: **Chats** (with the
  unread count of chats that aren't muted), **Calls** (only when some kind of call is offered)
  and **Settings**. The account menu leaves the chat list header for the settings tab (the
  user's profile, Appearance, Log out). Turn the bar off with `TinodeChat(tabBar: false)`, e.g.
  when the app has tabs of its own; the header then keeps the menu, which also opens
  Appearance. The floating button sits above the bar; Back on another tab goes to the chats
  first; hidden tabs keep their state.
- The calls history: the calls of direct chats from the cache, newest first, with direction,
  kind, how they went (missed calls in `missedCallColor`) and the time. A tap calls back, by the
  same kind or the other when that one is off; a button opens the chat. Each time the tab shows
  (and on pull), it fetches the newest messages of the direct chats the cache is behind on.
- The settings tab: the user's photo and name (opening the profile), Appearance, Log out.
- The Appearance screen: a live preview, the host's palettes as swatches, Light | Dark |
  System, the host's own widget, and "Reset to <default>".
- **API:** `TinodeAppearance` (with `TinodeAppearancePalette`) holds the palettes the host
  offers and what the user picked, saved on the device; `load` it before `runApp`, build the
  themes from it, and pass it to `TinodeChat(appearance:)`. `TinodeChat(appearanceExtra:)` adds
  a host widget to the Appearance screen. `TinodeChat(tabBar:)`, true by default.
- **API:** `TinodeChatTheme` gains `pageColor`, `cardColor`, `cardRadius` and
  `tabBarLensColor`.
- New `TinodeChatStrings`: `callsTitle`, `settingsTitle`, `noCalls`, `callBack`, `openChat`,
  `profileSubtitle`, `appearance`, `appearanceColor`, `appearanceColorHelp`, `appearanceTheme`,
  `themeLight`, `themeDark`, `themeSystem`, `appearancePreviewQuestion`,
  `appearancePreviewAnswer`, `resetPalette`, `unreadCount`. `accountMenu` now names the menu
  shown without the tab bar.

- The call screens in the chat's design, always dark. The voice call shows the peer's 148 px
  avatar with rings pulsing out until it connects, the name and the status ("Ringing…" with
  pulsing dots, then a timer in tabular figures), over blurred blobs drifting in 9 to 14 s
  loops. Its controls are round glass buttons with a word below: Speaker, Mute and End (red,
  with a glow). The video call plays the peer full-bleed (a still backdrop with the avatar until
  the video arrives). A tap hides or shows the name on top and a floating glass pill of controls
  (flip camera, camera, mute, end), and the self-view (108 × 152) moves up while they are
  hidden. With the camera off, the self-view shows the user's avatar and "Camera off". The
  ringing screen shares the voice call's background, with round Decline and Accept buttons.
  Content fades up into place. Reduce motion stills the blobs, the rings and the dots.
- Minimized calls: the chevron at the top of a call, or Back, shrinks the call to a call bar
  above the chats (the name and the timer); a tap on the bar brings the call back. A ringing
  call still ignores Back.
- A call whose link drops shows "Reconnecting…" (a pill on the voice call, in place of the timer
  on the video call and the call bar) until the link comes back. After 20 s down, or when
  WebRTC reports the link failed, the call ends as lost ("The connection dropped. The call
  ended.") and the peer is told at once, instead of "The call could not be connected" whenever
  WebRTC gave up. A call ended by this device losing the chat server says "You're offline. The
  call ended." Either way the ended screen stays 12 s with **Call again** (disabled until the
  chat server is back) and **Close**. A call can't continue over a new connection: Tinode ties
  each call to the session that placed or took it, and ends it when that session goes.
- During a call, a network change probes the chat connection with a 10 s deadline instead of
  4 s, so a slow but alive mobile link doesn't end the call.
- **API:** `TinodeChatFeatures(voiceCalls:, videoCalls:)` turn each kind of call off: no call
  button, and an incoming call of that kind doesn't ring here (the user's other devices may take
  it). Pass the same features to `TinodeCalls.handlePush(features:)`.
- **API:** `TinodeChatTheme` gains the call screens' tokens: `callBackgroundColor`,
  `onCallColor`, `callBlobColors`, `videoPlaceholderColor`, `videoBlobColors`, `callScrimColor`,
  `callShadeColor`, `callControlColor`, `callControlActiveColor`, `onCallControlActiveColor`,
  `callOutlineColor`, `callPillColor`, `callPillEdgeColor` and `acceptCallColor`. `fromPalette`
  takes them from `deep`, `scene`, `primary`, `bright` and `accent`.
- Fixed: switching cameras flashed the picture mirrored the wrong way in the self-view, and the
  old camera's last frame stayed up to a second after the swap. The self-view now blurs and turns
  away while the cameras swap, stays blurred until the new camera's frames arrive (1.5 s at
  most), and its mirror follows the camera WebRTC reports. `CallMedia.switchCamera` (internal)
  returns whether the front camera is in use.
- Fixed: ending a call could log an uncaught "Cannot add new events after calling close": the
  WebRTC plugin reported the closing link after the call's media had shut down. The peer
  connection is now also disposed, not only closed.
- `TinodeChatStrings.callBusy` now reads "This chat is still in a call. Try again in a moment.":
  after a drop, the server may hold the old call for up to a minute.
- New `TinodeChatStrings`: `callLost`, `callOffline`, `callAgain`, `closeCall`,
  `callSpeakerLabel`, `callMuteLabel`, `callEndLabel`, `minimizeCall`,
  `returnToCall`, `callReconnecting`, `cameraOff`, `yourCamera`, `toggleCallControls`.

- Login in the chat's design: one screen signs in and up, over the wallpaper with drifting
  bubbles. A sheet rises in with a Sign in | Sign up switch, the form (the password with a
  show/hide eye) and a button with an arrow. `TinodeChat(loginHeader:)` puts the host's widget,
  e.g. an animated logo, near the top. Signing up no longer opens its own screen: `SignUpScreen`
  and its "Create an account" link are gone, and confirming the email pushes over the login
  screen. `TinodeChatStrings`: `loginTitle` now labels the switch's sign-in side; `signUpTitle`
  and `createAccountLink` are removed; new `signUpTab`, `loginHeadline`, `loginSubtitle`,
  `signUpHeadline`, `signUpSubtitle`, `signUpTerms` (empty by default), `showPassword`,
  `hidePassword`, `loginBubbleHello`, `loginBubbleLater`.

- The chat list in the chat's design: a frosted header (account menu, "Chats", compose) with a
  search pill that opens the people search; 76 px rows with a 56 px avatar, the online dot, a
  muted icon, the ticks of the user's own last message, the time ("Yesterday" too), a preview
  of the newest message (text, photo, file, voice, call; the sender in groups; "typing…") and
  the unread badge, grey for muted chats. Rows fade up one after the other on first show, and
  the floating button pops in. The preview comes from the cache: a chat whose newest message
  isn't on the device says "New message". `FindPeopleButton` is gone (the search pill replaces
  it). New `TinodeChatStrings`: `newMessage`, `accountMenu`, `searchChats`, `chatMuted`,
  `newMessageArrived`, `photoMessage`, `voiceMessage`; `missedVoiceCall` / `missedVideoCall`
  also serve the preview.
- Fixed: "Today" and "Yesterday" over a clock change (a 23-hour day counted as none).

- Online presence: a direct chat whose peer is online shows a dot on its avatar in the chat list
  and "online" under its name in the chat header (typing wins). Live only: the cache no longer
  keeps `online`, so a cached list shows everyone offline until it syncs. `pres acs` for a known
  chat syncs the list. New `TinodeChatStrings.online`.
- Fixed: after a sync "if modified since", a chat whose peer was online lost its access in the
  cache (the server's stub has an empty `acs`) and turned read-only.

- The chat screen in the chat's design. Bubbles are 20 px round, with a tail on the last of each
  run, 2 px between the bubbles of a run and 12 px between runs; the user's newest message and
  the outbox make one run. The time and ticks sit after the last line when they fit. A photo
  without a caption carries its time on it. A date ("Today", "Yesterday" or the date) shows
  above each day's first message. The messages scroll over the wallpaper, under a frosted
  header (back with the other chats' unread count, the avatar, the name, who is typing, search
  and calls) and a frosted composer with a pill field. The send button fills with the brand
  color and its arrow spins in once there is text. A sent message pops in from its tail
  corner, with a light haptic. A bubble with bouncing dots shows while someone types. Reduce
  motion turns the pop into a fade and stops the dots.
- `TinodeChat(bubbleBuilder:)` wraps or replaces message bubbles. It gets a `TinodeBubble`:
  the chat, seq, sender, whether it is the user's own, text, time, kind (`TinodeBubbleKind`),
  its place in its run and, for the user's own, how far it got (`TinodeBubbleStatus`).
- New `TinodeChatStrings`: `today`, `yesterday`, `backToChats`.
- Message text is `bodyLarge` (was `bodyMedium`); photos in bubbles are 248 px wide (were 220).

- The chat's own design (`docs/design.md`). `TinodeChatPalette` holds the brand colors, with a
  neutral slate blue by default. `TinodeChatTheme.materialTheme(palette:, brightness:,
  fontFamily:, displayFontFamily:)` builds a whole app theme from it: colors, the type scale,
  inputs, buttons, app bars, sheets and chips. `TinodeChatTheme.fromPalette` builds only the
  extension. `TinodeChatTheme` gains the tokens the screens move to: meta colors, bubble tail,
  photo radius, run gaps, wallpaper, date chip, glass, link, muted badge, online,
  waveform, field, button, composer and sheet radii, spring curve and durations. Its
  constructor now needs them all; `fallback` and `copyWith` keep existing code working.
  Photos and file tiles in bubbles use `photoRadius`.

- Background calls: calls go through the phone's own call screens, CallKit on iOS and a
  self-managed Telecom connection on Android (`flutter_callkit_incoming`). Calls ring over the
  lock screen and can be accepted, declined, muted and hung up from there. On Android a
  foreground service holds the microphone and camera while a call goes on, so a call keeps them
  with the app in the background. An unanswered call leaves a missed call notification.
- `TinodeCalls.handlePush(push, config:, token:)`, from the host's background push handler, rings
  for a call push while the app is in the background or closed, with the caller's name from the
  cache, and stops the ringing when the call is taken on another device or is over. Accepting
  opens the app straight into the call, which joins once connected if the call still waits.
  With the user's saved `token`, declining while the app is closed hangs up for the caller at
  once (Android). Call pushes are all `silent`: hand pushes to it before skipping silent ones.
  On iOS this is best effort: Tinode sends no VoIP pushes, so iOS may hold back call pushes and
  never wakes an app the user swiped away.
- `TinodeCalls.requestPermissions()` asks Android for notifications and full screen
  notifications, which the ringing screen needs.
- `TinodeChatFeatures(systemCalls: false)` keeps calls inside the app, e.g. where CallKit isn't
  allowed (the App Store in China).
- A call that starts while the app is in the background resumes a suspended session.
- New dependency: `flutter_callkit_incoming`. New `TinodeChatStrings`: `unknownCaller`,
  `ongoingCall`, `missedVoiceCall`, `missedVideoCall`. Host apps need some platform setup; see
  the README.

- Message search within a chat: the search button in the chat's app bar searches its messages
  kept on the device. Every word must start a word of the message, and accents don't count. A
  result goes back to the chat scrolled to the message, loading back to it from the cache or the
  server, and highlights it for a moment; one that can't be shown (deleted, or offline and not
  cached) says so. It needs no network. The cache
  moves to schema v3 and indexes the messages it already holds.
- The cache is pruned each time a user's chats open: each chat keeps its newest 1000 messages,
  older ones load from the server again on scroll, chats no longer in the list lose theirs, and
  the downloaded files used longest ago go until the rest fit in 200 MiB. Files staged for a
  message that was never sent go too. `TinodeChat(cacheLimits:)` with `TinodeCacheLimits` sets
  both limits; message search finds only what is kept.
- `TinodeChatTheme.revealedMessageColor` colours the highlight; it is a new required argument
  of the theme's constructor (`TinodeChatTheme.fallback` and `copyWith` fill it in).
- The chat list has a search button that finds people and groups, like the new chat button.
- The message list uses `super_sliver_list`, which can jump to a message of any height.

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
