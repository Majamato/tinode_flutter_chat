# Design

The chat's own look: fast, warm, playful, never noisy. One strong brand color per screen, for
the primary action and the user's own messages; everything else stays neutral. Motion starts
where the touch did: bubbles grow from their tail, sheets from the button that opened them.

The values live in code, not here: the palette in `TinodeChatPalette`, the neutrals in
`ChatNeutrals`, everything the widgets read in `TinodeChatTheme`, and the Material theme around
them in `chatMaterialTheme` (`TinodeChatTheme.materialTheme`). This page says what each is for.

The screens are moving to this design one by one (see the README's roadmap). Until a screen has
moved, it reads only the tokens it already used.

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

`ChatNeutrals.light` and `.dark`: `page` (outermost, and the dark wallpaper), `background`
(lists, sheets), `surface` (inputs, chips), `card` (settings groups), `peerBubble`, `text`,
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
- The time and ticks sit at the bottom right of the last line.
- The wallpaper is `wallpaperColor` with a dot grid in `wallpaperDotColor`; dates between
  messages sit on a `dateChipColor` pill in white.

## Motion

`springCurve` (a spring with a little overshoot, `Cubic(.2, .9, .3, 1.25)`) over
`springDuration` for pops, pills, lenses and sheets; `fadeDuration` for fades and color changes.
With the OS's Reduce motion (`MediaQuery.disableAnimationsOf`), scale and slide become plain
fades and looping background animations stop.

## Accessibility

- Text passes 4.5:1 (3:1 from 24 px). Check new colors before adding them.
- Every icon-only button has a label. Toggles expose their state; the current tab is announced.
- Decoration (tails, blobs, rings) is hidden from screen readers.
- Color is never the only signal: read state also shows in the ticks, muted chats show an icon.
