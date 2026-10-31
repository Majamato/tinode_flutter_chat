# Design

The chat's own look: fast, warm, playful, never noisy. One strong brand color per screen, for
the primary action and the user's own messages; everything else stays neutral. Motion starts
where the touch did: bubbles grow from their tail, sheets from the button that opened them.

The values live in code, not here: the palette in `TinodeChatPalette`, the neutrals in
`ChatNeutrals`, everything the widgets read in `TinodeChatTheme`, and the Material theme around
them in `chatMaterialTheme` (`TinodeChatTheme.materialTheme`). This page says what each is for.

Every screen follows it: the chat screen with voice messages, the chat list, login, the call
screens and the app shell (tab bar, calls history, settings, appearance).

## Palette

The host brands the chat with a `TinodeChatPalette`; `TinodeChatPalette.neutral` (a slate blue)
is the default. Its roles:

| Role | Use |
|---|---|
| `primary` | Own bubbles, primary buttons, selected chips, unread badges, the FAB, the active tab. White text on it passes 4.5:1. |
| `night` | `primary` in dark mode, a little lifted from near-black. White text on it passes 4.5:1. |
| `bright` | Decoration only: waveform highlights, photo placeholders, call blobs, recording rings. Never behind text. |
| `accent` | The clashing pop for small decorations. Never behind small text. |
| `soft` | Light chat wallpaper, secondary buttons, the login background. |
| `ink` | Text and links in the brand's hue on light backgrounds. |
| `onDark` | `ink` in dark mode. |
| `deep` | Base of the voice call background. |
| `scene` | Base of the remote video before it shows. |

Dark mode swaps `primary` for `night` and `ink` for `onDark`, and uses the dark neutrals
(`TinodeChatTheme.fromPalette(palette, brightness: Brightness.dark)`).

## Neutrals and semantic colors

`ChatNeutrals.light` and `.dark`: `page` (outermost, and the dark wallpaper; `pageColor` behind
settings), `background` (lists, sheets), `surface` (inputs, chips), `card` (settings groups:
`cardColor`, radius `cardRadius` 20), `peerBubble`, `text`,
`muted` (times, previews, labels), `line` (dividers, borders), `glass` and `glassEdge` (frosted
bars), `waveOff`, `dateChip`, `mutedBadge`. Fixed in both modes: `danger` (end call, recording,
missed calls) and `online` (the presence dot, with a 2–3 px ring in `background`).

## Type

The host bundles the fonts and passes them to `materialTheme`: `fontFamily` for the interface,
`displayFontFamily` for big, rare headlines (display styles: onboarding, empty states), never in
messages.

| Text role | Size / line | Weight | Use |
|---|---|---|---|
| `headlineLarge` | 32 / 38, −0.02 em | 800 | Large title |
| `headlineSmall` | 26 / 32 | 800 | Sheet title (login) |
| `titleLarge` | 18 | 800 | App bar title |
| `titleMedium` | 17 / 22 | 700 | A chat's name |
| `bodyLarge` | 16 / 22 | 400 | Message text, inputs |
| `bodyMedium` / `bodySmall` | 14 / 19, 13 / 18 | 500 | Previews, status |
| `labelLarge` | 16 | 700 | Buttons |
| `labelMedium` | 13, +0.06 em | 700 | Section labels, upper case |
| `labelSmall` | 11 | 500 | The time in a bubble |

Timers and durations use tabular figures.

## Shape and spacing

4 px grid; 16 px screen padding; bubbles 10 px from the edges. Radii in `TinodeChatTheme`:
`bubbleRadius` 20, `photoRadius` 15, `composerRadius` 22, `fieldRadius` 14, `buttonRadius` 16,
`sheetRadius` 28; chips and badges are stadiums. Touch targets are at least 44 × 44. Icons are
24 px strokes, never emoji.

## Bubbles

- Fully rounded, at most 78% of the width. The last bubble of a run has a tail at its bottom
  corner (`bubbleTail`): bottom left for others, mirrored bottom right for the user's own.
- `sameRunGap` (2 px) between the bubbles of a run, `newRunGap` (12 px) between runs.
- Own: `ownBubbleColor` with `onOwnBubbleColor` text and `ownMetaColor` time and ticks.
  Others: `peerBubbleColor`, `onPeerBubbleColor`, `peerMetaColor`.
- The time and ticks sit at the end of the last line when they fit, else on a line of their
  own (`BubbleTextLayout`). On a photo without a caption they sit on a dark pill over it.
- Padding: text 7 × 12, files and calls 10 × 12, photos 4 (caption 2 × 8 × 6 below).
  A photo's bubble takes the photo's radius plus that 4 px (19), so the rim is even. The tail's
  base reaches into the bubble, so it stays joined to a photo's thin rim.
- The wallpaper is `wallpaperColor` with two offset 28 px dot grids in `wallpaperDotColor`;
  the first message of a day has a `dateChipColor` pill above it, in white.
- While someone types, a bubble with three bouncing dots (`peerMetaColor`) sits at the bottom.
- A host wraps or replaces any bubble with `TinodeChat.bubbleBuilder`, which gets a
  `TinodeBubble` and the default bubble.

## Login

- One screen signs in and up. Behind it: `wallpaperColor` with a 20 px dot grid in
  `wallpaperDotColor`, and decorative bubbles (an incoming hello, an outgoing reply, a tiny voice
  note, an `accent` dot) drifting 12 px over 5–7 s, hidden from screen readers and still with
  Reduce motion.
- The host's `TinodeChat.loginHeader` (e.g. an animated logo) sits centred near the top; by
  default there is none.
- A sheet (`colorScheme.surface`, top radius `sheetRadius`) rises 60 px into place as it fades
  in (550 ms on `springCurve`): the title (`headlineSmall`) and subtitle, a 44 px Sign in |
  Sign up switch whose pill slides on `springCurve` (only where sign-up is offered), and the
  form. Switching cross-fades the forms in 320 ms.
- Fields are the theme's (radius `fieldRadius`, `surface`, a `line` border) with Material's
  floating label rather than a label above; the password has a show/hide eye. The primary button
  is 54 px, `buttonRadius`, with a trailing arrow. Under it: "Forgot password?" when offered, or
  `TinodeChatStrings.signUpTerms` when the host sets it.
- The screen scrolls from the bottom: with the keyboard open, the sheet and its button stay just
  above the keyboard, and the header scrolls off the top.

## Chat list

- The chats scroll under a frosted header: the account menu (only without the tab bar: profile,
  appearance, log out), "Chats" (`titleLarge`) and the compose button in `linkColor`, then a 38 px search pill (`surfaceContainer`, radius 12) that
  opens the people search. No folder chips.
- Rows are 76 px: a 56 px avatar with the presence dot; the name (`titleMedium` at 16), a muted
  icon, the ticks of the user's own last message (read in `linkColor`) and the time (`bodySmall`,
  in `linkColor` while unread, else `outline`); then the preview (`bodyMedium` in `outline`) and
  the unread badge (a 22 px stadium in `unreadBadgeColor`, `mutedBadgeColor` when muted). The
  divider (`outlineVariant`) runs under the text only.
- Preview icons, 15 px in `linkColor`: a mic for voice, a doc for files, a phone or camera for
  calls (`missedCallColor` when missed); a photo shows its inline thumbnail (18 px, radius 4).
  In groups the sender comes first, in `onSurface` 600.
- The first rows fade up 14 px over 420 ms, 40 ms apart, once per screen; the floating button
  (`primary`, a new-message icon) pops in after 350 ms. Reduce motion shows both at once.
- Times: today the time of day, then "Yesterday", else the short date.

## Shell

- `TinodeChat(tabBar: true)`, the default: the chat list, the calls history (when the host
  offers some kind of call) and the settings are tabs of a floating glass bar. Hosts with tabs of
  their own turn it off; the chat list's account menu then holds the settings.
- The bar: 16 px from the sides, 26 px from the bottom (or the system inset, if more), 66 px
  tall, radius 33, `glassColor` with blur 24 and saturation 1.6, a 1 px `glassEdgeColor` edge and
  a soft shadow. A lens (`tabBarLensColor`: `primary` at 10 % in light, white at 14 % in dark,
  radius 27) slides under the current tab on `springCurve`. Each tab is a 24 px icon over an
  11/700 label, in `linkColor` when current, else `outline`. The chats tab carries the unread
  count of chats that aren't muted (an 18 px `unreadBadgeColor` stadium, "99+" above 99). A
  pick ticks the haptics; screen readers hear the tabs as tabs, the current one selected, and the
  unread count.
- The tabs see the bar's footprint as their bottom padding: lists scroll under it, the floating
  button sits 20 px above it (18 px from the side), snack bars over it. A hidden tab keeps its
  state, its tickers off. Back on another tab goes to the chats first.

## Calls history

- The calls of direct chats, newest first, under a frosted "Calls" header: 72 px rows with a
  48 px avatar, the chat's name (`missedCallColor` when the user missed the call), then the
  direction arrow (bent when the call didn't happen), the kind and how it went ("Voice call ·
  4:12", "Video call · Missed") in `outline`, the time as in the chat list, and a button to the
  chat in `linkColor`. A tap calls back, by the same kind, or the other when the host leaves that
  one out. Pull to fetch again.

## Settings

- Cards (`cardColor`, `cardRadius`) on `pageColor`, 22 px apart, under a frosted "Settings"
  header: the user's photo (56 px) and name over "Name, photo and password", opening the
  profile; Appearance with the palette in use, when the host offers one; Log out in
  `colorScheme.error`. Rows are at least 52 px, with a `linkColor` icon and a chevron.
- Section labels are `labelMedium`, upper case, in `outline` (`SettingsLabel`).

## Appearance

- Under a frosted header, "‹ Settings" in `linkColor` and "Appearance": a preview card (radius
  24) with the wallpaper, a 22 px dot grid and two bubbles with tails, the answer naming the
  palette and popping in again from its tail (.6 → 1.06 → 1, 380 ms) when it changes.
- **Color** (when the host offers more than one palette): five swatches to a row on a card,
  48 px circles split at 135° into the palette's `accent` (38 %) and light `primary`, the name
  below (11 px, 800 when picked); the picked one has a 3 px gap and a 2.5 px `primary` ring. A
  pick ticks the haptics. Then a line on what the color changes.
- **Theme**: Light | Dark | System (`SlidingSegments`: 46 px, radius 16, `cardColor`, a
  `primary` pill sliding on `springCurve`, labels 15/700).
- The host's own `appearanceExtra`, if any, then "Reset to <default>" in
  `linkColor`, which resets only the palette.

## Chat screen

- The messages scroll under two frosted bars (`FrostedBar`: `glassColor`, blur 22, saturation
  1.6, a `glassEdgeColor` hairline). The header has back (with the other chats' unread count in
  a badge), the avatar, the name, who is typing in `linkColor`, then search and the call
  buttons. The composer has attach, a pill field (`composerRadius`) and the send button.
- While the field is blank the send button rests on the microphone (in `onSurfaceVariant`),
  or, without `TinodeChatFeatures.voiceMessages`, on a greyed arrow. With text it fills with
  `primary` and the arrow turns in from a quarter turn as the mic turns out (300 ms on
  `springCurve`, scale .4 ↔ 1).

## Voice messages

- **Recording.** A tap on the mic records (a medium haptic, and "Recording voice message" read
  out). The whole composer gives way to the **recording panel**, the field keeping its text: the
  composer grows to it on `springCurve` over `springDuration` (at once with Reduce motion), and
  the panel slides in 12 px as it fades in (250 ms). The list above is reversed, so the last
  message stays in view.
  - Top row (40 px): a 10 px `recordingColor` dot blinking each second (1 → .2 → 1), the
    recorded time (`m:ss`, `titleLarge` at regular weight, tabular figures), then the **live
    waveform** filling the row in `onSurfaceVariant`.
  - Bottom row: delete (a 48 px circle, `recordingColor` @ 12 % behind a `recordingColor` trash
    can), a wide 48 px pill on `surfaceContainerHighest` with `composerRadius` corners ("⏸ Pause",
    or "🎤 Resume" while paused, 600 weight), and send (a 48 px circle in the send button's
    filled colours with a send arrow).
- **The live waveform.** One bar per level the recorder reports (every 100 ms), the bubble's bars
  (2 px wide, 2 px apart, 2 to 22 px tall, so silence shows as dots), the newest on the right,
  older ones drifting left and sliding out of the left edge. The scale is fixed, from
  `liveWaveformFloor` (−50 dBFS, a dot) to 0 dB (full height), so one loud sample doesn't resize
  the others; it won't match the sent bubble bar for bar, which scales its loudest to full. A
  ticker glides the bars one pitch (4 px) per 100 ms, 40 px/s; paused, or with Reduce motion,
  they step instead. Hidden from screen readers.
- **Pause.** The pill pauses the recording (a light haptic): the clock stops, the dot stops
  blinking and turns `onSurfaceVariant`, the waveform stops, and the pill shows "Resume", which
  carries on in the same file. The time shown, the duration sent and the ten-minute limit count
  recorded time only, not the pauses.
- Send sends, paused or not; delete drops the recording. Under two seconds of recorded time
  nothing is sent ("Too short to send"); at ten minutes it sends itself. Hiding the app (paused
  or not), leaving the chat or a call starting drops it; there is no recording during a call.
- Recordings are AAC in MPEG-4 (`audio/mp4`), mono, 16 kHz at 24 kbps, as Tindroid records,
  sent as a Drafty `AU` entity with the duration and a 96-value loudness preview, so TinodeWeb
  and Tindroid play them. They go through the outbox like files.
- **The bubble** (232 px, padding 10 × 12): a 44 px play button (`primary` with a white icon on
  others' bubbles, white @ 22 % on the user's own), then bars 2 px wide, 2 px apart, 2 to 22 px
  tall (the preview's loudness to the power .7, so silence shows as dots and speech rises and
  falls), as many as fit the width less 6 px at each end (42 in the bubble), all 2 px without a
  preview. The playhead dot, in the played colour on top, is centred exactly on the position:
  8 px at rest, growing to 12 px with `springCurve` while playing or dragging. Under them
  the duration (the position while playing) in 12 px tabular figures, and the time and ticks at
  the end.
- **Playing.** Only ever from a file on the device, never streamed. A received message
  downloads when its bubble shows; the bubble looks complete meanwhile, and its button plays once
  the file is there (a tap after a failed download tries again). The user's own plays once the
  server has it, from the recording on the device; until then its button shows the upload's
  progress. Pressing play shows pause at once, with no spinner. One message plays at a time; a
  call or a recording stops it, and one that ends rewinds. The dot glides every frame between
  the player's reports, over the length the player reads from the file. While playing it never
  steps back: it starts gliding once a report shows the audio moving (as play starts, or after a
  seek), and when a report is behind it, it slows down for the audio to catch up, the further
  behind the slower, standing only when 400 ms or more behind (as `just_audio` on Android runs
  ahead of the audio for a moment as play starts). The bars keep their height, and those before the
  dot take `primary` (white on the user's own; unplayed: `waveOffColor`, or white @ 45 %). A tap
  on the bars moves the dot there at once and seeks; a drag moves the dot with the finger and
  seeks once it lifts. Seeks run one at a time, so quick taps end at the last, and the player's
  positions from before a seek don't show. Voice files are kept until their message, its chat or
  the login goes; the OS and the cache limit never clear them.

## Calls

The call screens are always dark, whatever the brightness: text, icons and rings in
`onCallColor` on `callBackgroundColor` (`deep`).

- **Voice call** (`VoiceCallView`). `CallBackdrop` paints three blurred blobs (`callBlobColors`:
  `primary`, `bright` @ 70 %, `accent` @ 45 %, blur 70) drifting in 14, 11 and 9 s loops, under
  `callScrimColor`. On top: the chevron that minimizes the call, and the reconnecting pill
  while the link drops. In the middle: `CallAvatar` (148 px, a 4 px `callOutlineColor` ring),
  with three rings pulsing out every 2.2 s, .75 s apart, until the call connects; the name in
  30/800; the status in 17 px, a timer in tabular figures once connected. At the bottom:
  Speaker, Mute and End, 64 px `CallRoundButton`s with a word below. A toggle that is on turns
  `callControlActiveColor` with an `onCallControlActiveColor` icon; End is `colorScheme.error`
  with a glow. The content fades up 20 px over 500 ms. There is no Video button yet: switching a
  running call to video needs renegotiation.
- **Video call** (`VideoCallView`). The peer's video full-bleed; until it arrives,
  `videoPlaceholderColor` (`scene`) with two still blobs and the avatar. A tap toggles the
  controls: a 200 px `callShadeColor` gradient with the chevron, the name (18/800) and the status
  (14/600), and the control pill (84 px, radius 42, `callPillColor` with a `callPillEdgeColor`
  edge, `glassFilter(26)`): flip camera (its icon turns half a turn), camera, mute, end, 60 px
  each. Hidden, the pill slides down 40 px and fades. The self-view (`CallLocalPreview`) is
  108 × 152, radius 22, with a 1.5 px `callOutlineColor` edge and a deep shadow; it moves from
  66 to 8 px under the status bar while the controls hide (400 ms, `springCurve`). While the
  cameras swap its video blurs and it turns edge-on (200 ms), and back once WebRTC says which
  camera is in use (the front camera is mirrored, the back one isn't). The blur stays until the
  new camera's frames arrive (the renderer reports a new rotation or size), or 1.5 s at most:
  until then the renderer still shows the old camera's last frame. With Reduce motion it only
  blurs.
- **A lost call** (`CallLostActions`): a call that ended because a connection dropped keeps
  its screen for 12 s with the reason, and round **Close** (glass) and **Call again**
  (`acceptCallColor`, faded and disabled while the chat server reconnects) in place of the
  controls; on a video call they show whatever the tap did.
- **Ringing** (`IncomingCallView`): the voice call's backdrop and avatar with rings, "Incoming
  voice call", and Decline (`error`, with a glow) and Accept (`acceptCallColor`).
- **Call bar** (`CallBar`): the minimized call, `colorScheme.primary`, 44 px under the status
  bar, above the chat routes: the call's icon, the name, the timer. A tap brings the call back.

## Presence

Only direct chats show presence: an `onlineColor` dot with a 3 px ring in the list's background
on the avatar, and "online" in `linkColor` under the title in the chat header when the peer isn't
typing (typing wins). Presence is live only, never cached.

## Motion

`springCurve` (a spring with a little overshoot, `Cubic(.2, .9, .3, 1.25)`) over
`springDuration` for pops, pills, lenses and sheets; `fadeDuration` for fades and color changes.
A sent message pops from its tail corner (420 ms: scale .35 → 1.05 → .98 → 1, rising 18 px);
the typing dots hop 4 px in a 1.2 s loop, 150 ms apart. The call screens' blobs drift in 9 to
14 s loops and their avatar rings pulse every 2.2 s. The recording rings pulse every 1.4 s, the
recording dot blinks each second, and the bars at a voice message's playhead swell in 0.9 s.
With the OS's Reduce motion (`MediaQuery.disableAnimationsOf`), scale and slide become plain
fades and looping background animations stop: the call blobs hold still, the avatar rings go
and the dots of "Ringing…" stop pulsing; while recording, the button changes colour without
growing, the rings go, and the dot and the chevron hold still; the playhead's bars stop
swelling.

## Accessibility

- Text passes 4.5:1 (3:1 from 24 px). Check new colors before adding them.
- Every icon-only button has a label. Toggles, segments, swatches and tabs expose their state; the
  current tab is announced.
- Decoration (tails, blobs, rings) is hidden from screen readers.
- Color is never the only signal: read state also shows in the ticks, muted chats show an icon.
