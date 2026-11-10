# Widget rules

The goal: screens that only rebuild what changed, widgets small enough to read at a glance, and no
business logic in UI files. Flutter's own guidance is in
[performance best practices](https://docs.flutter.dev/perf/best-practices).

## One widget per file

- Each public widget class gets its own file, named after it (`chat_unread_badge.dart` →
  `ChatUnreadBadge`). The number of files doesn't matter; readable widgets do.
- A file may also hold the widget's `State` class and **private** helpers used only by that widget
  (`_LoginFormState`, a `_Dot` painter).
- Prefer a small widget class over a helper method that returns a widget. A class can be `const`,
  rebuild on its own, and show up in DevTools.
- `test/architecture/one_widget_per_file_test.dart` enforces this.

## Keep `build` light

`build` can run on every frame of an animation, so it may only arrange widgets and read values.

- No business logic, parsing, sorting, filtering or string building beyond simple formatting. Put
  it in a domain model (`ChatSummary.initials`, `ChatSummary.unread`) or a provider.
- No object creation that isn't cheap and needed for the tree: no controllers, streams, futures or
  regexes in `build`. Controllers live in a `State` and are disposed in `dispose`.
- No `ref.read` to fetch data in `build`; `ref.read` belongs in callbacks.
- No local functions declared inside `build`. A helper used by callbacks (`_act` in
  `OutgoingActionsSheet`) is a private method on the widget, taking `context` or `ref` as
  parameters when it needs them; anything bigger moves to a controller.

## Rebuild only what changes

- **Watch at the leaves.** A screen widget watches nothing; it lays out children that each watch the
  one value they show. Example from the chat list:

  | Widget | Watches | Rebuilds when |
  |--------|---------|---------------|
  | `ChatListScreen` / `ChatListHeader` | nothing | never by state |
  | `ChatListBody` | `(status, failure)` | the load status changes |
  | `ChatListView` | `order` | chats are added or reordered |
  | `ChatListTile` | nothing | the list rebuilds it |
  | `ChatTitle` / `ChatAvatar` | `title` / `initials` | the chat is renamed |
  | `ChatOnlineDot` / `ChatMutedIcon` | `online` / `muted` | presence or the mute changes |
  | `ChatLastMessageTime` | `(lastMessageAt, unread and not muted)` | a message arrives |
  | `ChatUnreadBadge` | `(unread, muted)` | a message arrives or is read |
  | `ChatPreviewLine` | typing, `chatPreviewBehind`, the preview | someone types, the cached newest message changes, or the chat falls behind |
  | `ChatLastSentTicks` | the preview's receipt, `chatPreviewBehind` | the user's last message gets further |

  A test (`chat_list_rebuild_test.dart`) checks that a new message in the top chat rebuilds only
  `ChatLastMessageTime` and `ChatUnreadBadge`. The first unread `pres msg` also rebuilds
  `ChatPreviewLine`, which turns to "New message"; later ones don't.
- **Attachments** follow the same rule. In the chat, `AttachmentMessageBody` lays out what the
  message carries; `ImageBubbleContent` watches only its file (`attachmentFile(ref)`),
  `FileBubbleContent` and `VideoBubbleContent` only their download, and `RefPhotoAvatar` only
  its photo. The image and video bubbles also read `sentStandIns`, which changes only with the
  session. An outgoing attachment's `AttachmentProgressRing` is the only widget that watches
  its compression and upload progress (`attachments_flow_test.dart` checks that progress
  rebuilds nothing else). Images keep their
  space from the sender's width and height, so the list doesn't jump when they load, and decode
  at display size (`ResizeImage`). The attach menu (`AttachSheet`), the caption screen
  (`AttachmentPreviewScreen`, which `AttachButton` gives its `AttachmentPreviewActions`) and the
  full-screen `ImageViewerScreen` watch nothing but the
  camera's availability.
- **`select` scalars:** `ref.watch(chatSummaryProvider(topic).select((c) => c?.unread ?? 0))`.
- **Buttons own their state.** `SendButton` alone watches whether a send is running (and the text
  field via `ValueListenableBuilder`); typing or sending never rebuilds the composer or the screen.
  `LoginSubmitButton` does the same for the login form.
- **Side effects use `ref.listen`** (snack bars, navigation), which never rebuilds.
- **Lists:** `ListView.builder` (`SuperListView.builder` for the messages, which must jump to any
  one of them), one widget per item with a `ValueKey` (topic or seq), each item watching its own
  family provider (`chatSummaryProvider(topic)`, `chatMessageProvider(topic, seq)`).
- **`const` everywhere it compiles.** Lints flag missing ones.
- Use `MediaQuery.sizeOf(context)` (and the other `…Of` getters) instead of `MediaQuery.of`, so a
  keyboard opening doesn't rebuild every widget that reads the size.
- Pass a `child` to builders (`ValueListenableBuilder`, `AnimatedBuilder`) for the parts that don't
  change.

## Strings, theme, layout

- No user-visible string literals in widgets: use `TinodeChatStrings.of(context)`. A new text is a
  field with a default in all three constructors: English (`TinodeChatStrings()`), Spanish
  (`.es()`, informal *tú*) and French (`.fr()`, *vous*, with a no-break space ` ` before
  `? ! :`). Text that names someone or counts something is a function field (`typingOne(name)`)
  whose defaults are private top-level functions, one per language (`_typingOne`,
  `_typingOneEs`, `_typingOneFr`), so `TinodeChatStrings` stays `const`; mind each language's
  plurals (French counts 0 and 1 in the singular). Choosing between such texts (one name,
  two, a count) is a plain function next to its widget, like `typingMessage`, not code in `build`.
- No `Icons.*` in widgets: use `TinodeChatIcons.of(context)`. Add a field named for its role
  (`voiceCall`, not `phone`) with a Phosphor default for a new icon; an on or selected state gets
  its own field (`chatsTabSelected`). Only `tinode_chat_icons.dart` imports Phosphor. Helpers
  that pick an icon outside `build` take the `TinodeChatIcons`, as `CallRecordTexts.icon` does.
- Icon colors are roles: leave an icon you can tap to `iconColor`, the default, and use
  `iconPassiveColor` for one that only informs (docs/design.md). Sizes are `ChatIconSize`, never a
  number; `test/architecture/icon_size_test.dart` enforces it.
- No hard-coded colors: use `TinodeChatTheme.of(context)` or `Theme.of(context).colorScheme`. Add a
  field to `TinodeChatTheme` (and to `copyWith`, `lerp`, `fallback`) for new chat-specific colors.
- Widgets must work at phone width and in dark mode.
- **Sheets.** Open every bottom sheet with `showChatSheet` and build it as a `ChatSheet` of
  `ChatSheetAction` rows, never a raw `showModalBottomSheet` with `ListTile`s, so they all
  look, move and read alike.
- **App bars and bottom bars.** A screen with an app bar is a `GlassScaffold`: a `Scaffold`
  with `extendBodyBehindAppBar` and `extendBody`, inside one `BackdropGroup`. Its app bar is a
  `TinodeAppBar` (or a widget building one: `ChatListHeader`, `ChatHeader`), which the host's
  `appBarBuilder` may wrap or replace; a bottom bar (the chat's `ComposerDock`) goes in
  `bottomNavigationBar`. The Scaffold hands the body both bars' heights as `MediaQuery`
  padding in the same layout pass, so **lists pad by `MediaQuery.paddingOf(context)`, read
  inside the body, and never measure a bar**; whatever bar the host brings, solid or not, then
  just works. Read the padding in a widget under the Scaffold, not in the screen's own `build`
  (that context is above the Scaffold), or let a `ListView` without `padding` add it. The
  Scaffold caps the app bar at the status bar plus `preferredSize`, so a preferred height that
  is too small squashes it silently: `header_height_test.dart` lays each bar out on its own and
  checks it. With a bottom bar the Scaffold doesn't resize for the keyboard; the bar pads
  itself above it, so its height (keyboard included) is the body's bottom padding, and only the
  dock reads `viewInsets`. The tab bar's room reaches the tabs as `MediaQuery` bottom padding,
  under a `GlassBelow`, so their scaffolds paint only a light veil there, not the solid
  fade (the bar's glass blurs the rows instead); touches on that room still stop there.
- **Back buttons.** A screen that can go back has a `TinodeBackButton` in `TinodeAppBar.leading`,
  never a Material `BackButton` or a bar's implied arrow. The chevron alone is the default; a
  settings page adds a label naming the screen it goes back to. With more than one way in it
  takes that name as a required `backLabel` in `open`, so a new caller can't forget it. A text field in the bar's row goes on a `GlassField`, with the chevron
  alone beside it.
- **Glass.** Every translucent piece is a `GlassSurface` (round buttons: `GlassIconButton`),
  whose `BackdropFilter.grouped` joins the screen's `BackdropGroup`. Glass must not overlap
  other glass of the same group.

## Public widgets

Everything exported from `lib/tinode_flutter_chat.dart` needs dartdoc on the class and every public
member, with a short example where useful. Internal widgets need a one-line doc saying what they
show and what they watch.

## Checking rebuilds

- DevTools → Flutter Inspector → **Track widget rebuilds** while using the example app.
- In tests, record rebuilt widgets with `debugOnRebuildDirtyWidget`, as
  `chat_list_rebuild_test.dart` does.
