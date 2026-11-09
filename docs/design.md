# Design

The chat's own look: fast, warm, playful, never noisy. One strong brand color per screen, for
the primary action and the user's own messages; everything else stays neutral. Motion starts
where the touch did: bubbles grow from their tail, sheets from the button that opened them.

The values live in code, not here: the palette in `TinodeChatPalette`, the neutrals in
`ChatNeutrals`, everything the widgets read in `TinodeChatTheme`, and the Material theme around
them in `chatMaterialTheme` (`TinodeChatTheme.materialTheme`). This page says what each is for.

Every screen follows it: the chat screen with voice messages, the chat list, the call screens
and the app shell (tab bar, calls history, settings, appearance). Login is the exception: it is
plain, and the look of a designed login is the host's.

## Palette

The host brands the chat with a `TinodeChatPalette`; `TinodeChatPalette.neutral` (a slate blue)
is the default. Its roles:

| Role | Use |
|---|---|
| `primary` | Primary buttons, the send button, selected chips, unread badges, the FAB, the active tab; read ticks and the voice player on own bubbles in light mode. White text on it passes 4.5:1. |
| `night` | `primary` in dark mode, a little lifted from near-black, and the own bubbles there. White text on it passes 4.5:1. |
| `bubble` | Optional. Own bubbles in light mode, under near-black text (white if it is dark). By default `lightBubble`, `primary` at 26 % over white: a muted tint of the brand. |
| `bright` | Decoration only: waveform highlights, photo placeholders, call blobs, recording rings. Never behind text. |
| `accent` | The clashing pop for small decorations. Never behind small text. |
| `soft` | Secondary buttons and Material's containers in light mode. |
| `ink` | Text and links in the brand's hue on light backgrounds. |
| `onDark` | `ink` in dark mode. |
| `deep` | Base of the voice call background. |
| `scene` | Base of the remote video before it shows. |

Dark mode swaps `primary` for `night` and `ink` for `onDark`, and uses the dark neutrals
(`TinodeChatTheme.fromPalette(palette, brightness: Brightness.dark)`).

The status bar is clear, with dark icons over light screens and light ones over dark screens
(`chatOverlayStyle`): `TinodeChat` sets it for screens without an app bar, the chat header and
`materialTheme`'s app bars for theirs, and the call screens always take light icons.

## Neutrals and semantic colors

`ChatNeutrals.light` and `.dark`: `page` (outermost, and the dark wallpaper; `pageColor` behind
settings), `background` (lists, sheets), `surface` (inputs, chips), `card` (settings groups:
`cardColor`, radius `cardRadius` 20), `peerBubble`, `text`,
`muted` (times, previews, labels), `line` (dividers, borders), `glass`, `glassEdge` and
`glassShadow` (floating glass: the app bar's and the composer's capsules, the tab bar),
`waveOff`, `dateChip`, `mutedBadge`. Fixed in both modes: `danger` (end call, recording,
missed calls) and `online` (the presence dot, with a 2–3 px ring in `background`).

## Type

The host bundles the fonts and passes them to `materialTheme`: `fontFamily` for the interface,
`displayFontFamily` for big, rare headlines (display styles: onboarding, empty states), never in
messages.

| Text role | Size / line | Weight | Use |
|---|---|---|---|
| `headlineLarge` | 32 / 38, −0.02 em | 800 | Large title |
| `headlineSmall` | 26 / 32 | 800 | Title (login) |
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
24 px [Phosphor](https://phosphoricons.com) strokes (`TinodeChatIcons`), never emoji: Regular,
Fill for the current tab, play, pause and hang up, Bold for the small ticks and the send arrow.

Icons are drawn in one of three roles, from `TinodeChatTheme`:

| Role | Color | For |
|---|---|---|
| Action | `iconColor` (`onSurface`) | Anything you can tap: back, app bars, the composer, rows |
| Passive | `iconPassiveColor` (`onSurfaceVariant`) | What only informs: chevrons, field hints, previews, the muted mark |
| Selected or primary | `linkColor` with the Fill glyph, or on a filled `actionColor` | The current tab, a tonal main action, Send |

Color means state, so brand color stays off the chrome. Unchanged by role: white on media, the
call screens' own colors, `colorScheme.error` for what destroys, `missedCallColor`, read ticks and
icons on a filled surface. `ChatThemeScope` makes the action color and 24 px the default of every
icon and icon button in the chat, whatever `ThemeData` the host has.

Sizes are `ChatIconSize`, never a number:

| Name | Px | For |
|---|---|---|
| `tiny` | 14 | Ticks, chips on media |
| `small` | 16 | Indicators in a line of text |
| `label` | 18 | Beside a label or a field's hint |
| `standard` | 24 | App bars, the composer, tabs, tiles, rows |
| `large` | 28 | Alone in a large round control: calls, play, retry |
| `xlarge` | 32 | File icons in a bubble |
| `hero` | 64 | The one thing on a screen |

## Bubbles

- Fully rounded, at most 78% of the width. The last bubble of a run has a tail at its bottom
  corner (`bubbleTail`): bottom left for others, mirrored bottom right for the user's own.
- `sameRunGap` (2 px) between the bubbles of a run, `newRunGap` (12 px) between runs.
- Own: `ownBubbleColor` with `onOwnBubbleColor` text and `ownMetaColor` time and ticks, the
  ticks of a read message in `readReceiptColor`. As in Telegram and WhatsApp, light mode puts
  near-black text on a muted tint of the brand (`palette.lightBubble`), with the time and
  ticks in `ink` at 80 % (4.5:1 on the bubble) and read ticks in `primary`; others' bubbles
  are white on the lighter wallpaper. Every palette the user picks in Appearance derives its
  own, so the chat follows the pick. Dark mode fills own bubbles with `night` under white
  text.
  Others: `peerBubbleColor`, `onPeerBubbleColor`, `peerMetaColor`.
- The brand's strong color for actions is `actionColor` / `onActionColor` (the send button,
  the recording panel's send, others' voice players), so it stays strong while own bubbles are
  light; `ownAccentColor` is the brand drawn on an own bubble (its voice player).
- The time and ticks sit at the end of the last line when they fit, else on a line of their
  own (`BubbleTextLayout`). On a photo without a caption they sit on a dark pill over it.
- Padding: text 7 × 12, files and calls 10 × 12, photos 4 (caption 2 × 8 × 6 below).
  A photo's bubble takes the photo's radius plus that 4 px (19), so the rim is even. The tail's
  base reaches into the bubble, so it stays joined to a photo's thin rim.
- The wallpaper is a flat `wallpaperColor`, as in the design. In light mode it is
  `lightWallpaper`, `primary` at 6 % over a light grey: its lightness sits between others'
  white bubbles and the own tint, so both stand out from it by at least 1.2:1. The first message of a day has a `dateChipColor` pill above it, in white.
- While someone types, a bubble with three bouncing dots (`peerMetaColor`) sits at the bottom.
- A host wraps or replaces any bubble with `TinodeChat.bubbleBuilder`, which gets a
  `TinodeBubble` and the default bubble.

## Login

The package's login is deliberately plain, because how an app greets its users is the app's brand:

- One screen signs in and up, on the theme's background: a centred column up to 400 px wide with
  the host's `TinodeChat.loginHeader` if any, the title (`headlineSmall`) and subtitle, the form,
  and a text button to the other side where sign-up is offered. Forms swap at once.
- Fields are the theme's (radius `fieldRadius`, `surface`, a `line` border) with Material's
  floating label rather than a label above; the password has a show/hide eye. The primary button
  is 54 px, `buttonRadius`, with a trailing arrow. Under it: "Forgot password?" when offered, or
  `TinodeChatStrings.signUpTerms` when the host sets it.
- The screen scrolls from the bottom: with the keyboard open, the form and its button stay just
  above the keyboard, and the header scrolls off the top.

A host draws its own login with `TinodeChat.loginBuilder`, which gets the working form
(`TinodeLoginView.form`), the mode and whether sign-up is offered. `BubbleTail` and
`SlidingSegments` are exported for it. Resetting a password and confirming an email stay simple
screens in the host's theme, with the same glass app bar and back button as the rest of the chat.

## Glass

Floating glass, as in Telegram: no bars, only capsules over the content, which scrolls under
them.

- **Glass** (`GlassSurface`): `glassColor` over a blur of 22 with saturation 1.6, a 0.5 px
  `glassEdgeColor` edge and a soft `glassShadowColor` shadow (blur 24, 6 px down; `raised`
  glass such as the tab bar casts it at twice the alpha, blur 34, 12 px down). A stadium,
  or round when square; the field and the recording panel take `composerRadius`. All the glass
  of a screen joins one `BackdropGroup`, so the blur reads the content behind it once.
- **Tonal** (`GlassSurface(tonal: true)`, `GlassIconButton(tonal: true)`): a screen's main
  action, solid `primaryContainer` with its icon in `onPrimaryContainer`, like the new group
  row's circle; the same shape and shadow as glass but no blur or edge. Both come from the
  palette (`soft` and `ink` in light, `night` and `onAction` in dark), so it follows the
  appearance screen. Only the chat list's new chat button uses it.
- **App bar** (`TinodeAppBar`): a 44 px row 6 px under the status bar, 8 px from the sides,
  its pieces 8 px apart: a leading capsule (the back button on every screen that can go back),
  the title (`titleLarge`, centred, or a capsule of
  its own), round 44 px buttons (`GlassIconButton`, 24 px icons in `iconColor`), then an
  optional bottom row such as a search pill. Buttons that belong together share one island of
  glass instead, 40 px wide each with 2 px at its ends (the chat's search and calls), leaving
  the title more room. Behind it an **edge fade** (`EdgeFade`) of the
  screen's background keeps what isn't on glass readable: solid under the status bar and
  under a plain-text title's row, then easing (85 %, 45 %, clear) over the rest of the bar and
  16 px past it, so content slides in from under the bar without an edge. The fade only
  paints; each bar blocks the touches on its own area, so content under the bar's overhang
  stays tappable. A title on glass of
  its own (the chat's name pill, which starts with its 34 px photo 5 px in, `titleOnGlass`) needs no solid row: there the fade is solid
  under the status bar only and the messages show behind the capsules. The bar takes every touch that lands on it, between the buttons too, so nothing
  under it can be tapped through it; the composer's dock does the same. Text grows to 1.3
  times at most. Every screen with an app bar uses it; a host wraps or replaces it with
  `TinodeChat.appBarBuilder`, which gets the `TinodeScreen`.
- **Back button** (`TinodeBackButton`): a 44 px glass capsule, its 24 px chevron and its label
  (`titleMedium`, 600) in `iconColor`, at most 45 % of the screen wide. The chevron alone is the
  default. Only Profile, Account, Appearance and Change password add a label, cut with an
  ellipsis, naming the screen they go back to ("‹ Settings", "‹ Chats", "‹ Account"). The chat
  itself has the chevron and its unread count. A bar whose title is a field (find people,
  message search) keeps the room for it. That field sits on a 44 px capsule (`GlassField`), filled like the chat list's search
  pill in light mode and glass in dark mode.
- The content runs under the bars and is padded by their heights, which the `Scaffold` gives
  it, so a host's bar of any height, solid or not, works.

## Chat list

- The chats scroll under the glass app bar: the account menu (only without the tab bar:
  profile, appearance, log out) as a round button, "Chats" (`titleLarge`) centred and the
  tonal new chat button (a plus), then a 40 px search pill that opens the people search: filled
  in `surfaceContainerHighest` like an input in light mode, where white glass would vanish on
  the white list, and glass in dark mode.
  No folder chips.
- **Reconnecting title** (`ReconnectingTitle`), as in Telegram: once the link has been down for
  1 s (`networkSettle`, so a blip shows nothing), "Chats" turns into a 16 px spinner (stroke 2)
  and "Reconnecting…", 8 px apart, in the title's `titleLarge` muted to `onSurfaceVariant`, so
  it reads as a state rather than a name. It turns back as soon as the link is. Nothing else
  moves: there is no strip or banner, and the bar keeps its height. Screen readers announce it
  (a live region).
- Rows are 76 px: a 56 px avatar with the presence dot; the name (`titleMedium` at 16), a muted
  icon, the ticks of the user's own last message (read in `linkColor`) and the time (`bodySmall`,
  in `linkColor` while unread, else `outline`); then the preview (`bodyMedium` in `outline`) and
  the unread badge (a 22 px stadium in `unreadBadgeColor`, `mutedBadgeColor` when muted). The
  divider (`outlineVariant`) runs under the text only.
- Preview icons, 16 px in `iconPassiveColor`: a mic for voice, a doc for files, a phone or camera for
  calls (`missedCallColor` when missed); a photo shows its inline thumbnail (18 px, radius 4).
  In groups the sender comes first, in `onSurface` 600.
- The first rows fade up 14 px over 420 ms, 40 ms apart, once per screen. Reduce motion shows
  them at once. There is no floating button: a new chat starts from the header's plus.
- Times: today the time of day, then "Yesterday", else the short date.

## Shell

- `TinodeChat(tabBar: true)`, the default: the chat list, the calls history (when the host
  offers some kind of call) and the settings are tabs of a floating glass bar. Hosts with tabs of
  their own turn it off; the chat list's account menu then holds the settings.
- The bar: 16 px from the sides, 66 px tall, on the same glass as the capsules (a stadium).
  Over an iOS home indicator it sits 8 px from the edge, the indicator across it; elsewhere
  12 px above what the system keeps at the bottom (Android's navigation buttons or gesture
  strip when the app draws behind them, else the screen's edge).
- Under it only a veil: the tab's background at 60 % at the screen's edge, easing to clear at
  the bar's top, never solid, so rows scroll under the bar, blur through its glass and still
  show around it. Touches anywhere in the bar's room stop there, so a row half under the bar
  can't be opened by a near miss. The bar's raised shadow keeps it floating. A glass screen without a composer or the tab bar fades its
  background in under the system's own bars instead, solid from the screen's edge to their
  middle and clear at their top; touches there stop. A lens (`tabBarLensColor`: `primary` at 10 % in light, white at 14 % in dark,
  radius 27) slides under the current tab on `springCurve`. Each tab is a 24 px icon over an
  11/700 label, in `linkColor` when current, else `iconPassiveColor`. The chats tab carries the unread
  count of chats that aren't muted (an 18 px `unreadBadgeColor` stadium, "99+" above 99). A
  pick ticks the haptics; screen readers hear the tabs as tabs, the current one selected, and the
  unread count.
- The tabs see the bar's footprint as their bottom padding: lists scroll under it, snack bars
  over it. A hidden tab keeps its
  state, its tickers off. Back on another tab goes to the chats first.

## Calls history

- The calls of direct chats, newest first, scrolling under a "Calls" glass app bar: 72 px rows with a
  48 px avatar, the chat's name (`missedCallColor` when the user missed the call), then the
  direction arrow (bent when the call didn't happen), the kind and how it went ("Voice call ·
  4:12", "Video call · Missed") in `outline`, the time as in the chat list, and a button to the
  chat in `iconColor`. A tap calls back, by the same kind, or the other when the host leaves that
  one out. Pull to fetch again.
- "Calls" turns into the reconnecting title while the link is down, as on the chat list.
  Settings and Appearance don't show it.

## Settings

- Cards (`cardColor`, `cardRadius`) on `pageColor`, 22 px apart, scrolling under a
  "Settings" glass app bar fading from `pageColor`: the user's photo (56 px) and name over "Name, photo and password", opening the
  profile; Appearance with the palette in use, when the host offers one; "Show my online
  status" with an adaptive switch (disabled while the profile can't be read or the change
  saves; a failed save shows a snack bar) and a footer (`bodySmall` in `outline`) saying that
  other Tinode apps may still show it; Log out in `colorScheme.error`. Rows are at least 52 px,
  with an `iconColor` icon and an `iconPassiveColor` chevron, or a trailing switch instead.
- Section labels are `labelMedium`, upper case, in `outline` (`SettingsLabel`).

## Appearance

- Under a glass app bar, a "‹ Settings" pill in `iconColor` and "Appearance": a preview card (radius
  24) with the wallpaper and two bubbles with tails, the answer naming the
  palette and popping in again from its tail (.6 → 1.06 → 1, 380 ms) when it changes.
- **Color** (when the host offers more than one palette): five swatches to a row on a card,
  48 px circles split at 135° into the palette's `accent` (38 %) and light `primary`, the name
  below (11 px, 800 when picked); the picked one has a 3 px gap and a 2.5 px `primary` ring. A
  pick ticks the haptics. Then a line on what the color changes.
- **Theme**: Light | Dark | System (`SlidingSegments`: 46 px, radius 16, `cardColor`, a
  `primary` pill sliding on `springCurve`, labels 15/700).
- The host's own `appearanceExtra`, if any, then "Reset to <default>" in
  `linkColor`, which resets only the palette.

## Sheets

- Every sheet opens with `showChatSheet` and is a `ChatSheet`: Material 3's modal bottom sheet,
  full width and docked to the bottom, its top corners `sheetRadius`, on `colorScheme.surface`
  with Material's drag handle in `outlineVariant`, its motion and its scrim. An optional title
  (`titleLarge`) and subtitle (`bodySmall` in `outline`) sit under the handle, 24 px in. Rows that
  pass the height Material allows scroll inside.
- **Rows** (`ChatSheetAction`): at least 56 px, the ripple a rounded pill 8 px in from the sides
  (`buttonRadius`); a 40 px rounded square (radius 12) in `colorScheme.surfaceContainer` behind a
  24 px icon in `iconColor`, then the label (`bodyLarge` 600). What
  deletes or discards is `destructive`: icon and label in `colorScheme.error`, the square that
  color @ 12 %. A tap
  ticks the haptics.
- Read by lists the members under its title, with "Delivered to" as an upper-case
  `labelMedium` label in `outline`.

## Chat screen

- The messages scroll under the glass app bar, fading from `wallpaperColor`: a back pill
  (the chevron, and the other chats' unread count in a badge), a pill with the chat's 34 px
  photo (or initials), then the name (15/700) over who is typing, "online" in `linkColor`, or
  "last seen …" in `outline` (`bodySmall`),
  which opens the chat's info, then search, video and voice call buttons (only the calls
  offered) on one island of glass; search alone is a round button.
- While the link is down (after the same 1 s as the chat list's reconnecting title), the line
  under the name is a 10 px spinner (stroke 1.5) and "Reconnecting…" in `bodySmall`, both in
  `outline`. It outranks typing, "online" and last seen, which are stale meanwhile.
- The composer has no bar: three pieces of glass float 8 px above the keyboard, or above the
  home indicator, over a fade of the wallpaper: the round attach button, the field
  (`composerRadius`, transparent inside, 44 px for one line, up to five) and the round send
  button. A read-only chat shows a glass pill instead. The messages are padded by the
  composer's height, keyboard included, in the same frame it changes.
- On every screen, a touch outside the field closes the keyboard, and a touch that starts a
  scroll counts. The composer's buttons count as its field, so sending leaves the keyboard open.
- While the field is blank the send button rests on the microphone (in `onSurfaceVariant`),
  or, without `TinodeChatFeatures.voiceMessages`, on a greyed arrow. With text its glass fills
  with `actionColor` and the arrow turns in from a quarter turn as the mic turns out (300 ms on
  `springCurve`, scale .4 ↔ 1).

## Voice messages

- **Recording.** A tap on the mic records (a medium haptic, and "Recording voice message" read
  out). The whole composer gives way to the **recording panel**, on one piece of glass, the field keeping its text: the
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
- **The bubble** (232 px, padding 10 × 12): a 44 px play button (`actionColor` with an `onActionColor` icon on
  others' bubbles, `ownAccentColor` with an icon in the bubble's color on the user's own, as
  in Telegram), then bars 2 px wide, 2 px apart, 2 to 22 px
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
typing (typing wins). Offline, the header says when they were last seen, in `outline`: "last seen
today at 14:05", "last seen yesterday at 14:05", "last seen Mar 3". Online is live only, never
cached; last seen is cached. None of it shows while the host turns presence off
(`TinodeChatFeatures.presence`), nor for a peer who hides theirs ("Show my online status").

## Motion

`springCurve` (a spring with a little overshoot, `Cubic(.2, .9, .3, 1.25)`) over
`springDuration` for pops, pills and lenses; `fadeDuration` for fades and color changes.
A sent message pops from its tail corner (420 ms: scale .35 → 1.05 → .98 → 1, rising 18 px);
the typing dots hop 4 px in a 1.2 s loop, 150 ms apart. The call screens' blobs drift in 9 to
14 s loops and their avatar rings pulse every 2.2 s. The recording rings pulse every 1.4 s, the
recording dot blinks each second, and the bars at a voice message's playhead swell in 0.9 s.
The reconnecting title swaps in and out over `springDuration`, fading while it rises 6 px and
grows from .92 on `springCurve`.
With the OS's Reduce motion (`MediaQuery.disableAnimationsOf`), scale and slide become plain
fades (the reconnecting title included) and looping background animations stop: the call blobs hold still, the avatar rings go
and the dots of "Ringing…" stop pulsing; while recording, the button changes colour without
growing, the rings go, and the dot and the chevron hold still; the playhead's bars stop
swelling.

## Accessibility

- Text passes 4.5:1 (3:1 from 24 px). Check new colors before adding them.
- Every icon-only button has a label. Toggles, segments, swatches and tabs expose their state; the
  current tab is announced.
- Decoration (tails, blobs, rings) is hidden from screen readers.
- Color is never the only signal: read state also shows in the ticks, muted chats show an icon.
