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

## Rebuild only what changes

- **Watch at the leaves.** A screen widget watches nothing; it lays out children that each watch the
  one value they show. Example from the chat list:

  | Widget | Watches | Rebuilds when |
  |--------|---------|---------------|
  | `ChatListScreen` | nothing | never by state |
  | `ChatListBody` | `(status, failure)` | the load status changes |
  | `ChatListView` | `order` | chats are added or reordered |
  | `ChatListTile` | nothing | the list rebuilds it |
  | `ChatTitle` / `ChatAvatar` | `title` / `initials` | the chat is renamed |
  | `ChatLastMessageTime` | `lastMessageAt` | a message arrives |
  | `ChatUnreadBadge` | `unread` | a message arrives or is read |

  A test (`chat_list_rebuild_test.dart`) checks that a new message in the top chat rebuilds only
  `ChatLastMessageTime` and `ChatUnreadBadge`.
- **`select` scalars:** `ref.watch(chatSummaryProvider(topic).select((c) => c?.unread ?? 0))`.
- **Buttons own their state.** `SendButton` alone watches whether a send is running (and the text
  field via `ValueListenableBuilder`); typing or sending never rebuilds the composer or the screen.
  `LoginSubmitButton` does the same for the login form.
- **Side effects use `ref.listen`** (snack bars, navigation), which never rebuilds.
- **Lists:** `ListView.builder`, one widget per item with a `ValueKey` (topic or seq), each item
  watching its own family provider (`chatSummaryProvider(topic)`, `chatMessageProvider(topic, seq)`).
- **`const` everywhere it compiles.** Lints flag missing ones.
- Use `MediaQuery.sizeOf(context)` (and the other `…Of` getters) instead of `MediaQuery.of`, so a
  keyboard opening doesn't rebuild every widget that reads the size.
- Pass a `child` to builders (`ValueListenableBuilder`, `AnimatedBuilder`) for the parts that don't
  change.

## Strings, theme, layout

- No user-visible string literals in widgets: use `TinodeChatStrings.of(context)`. Add a field with
  an English default for new text. (gen_l10n can back the same accessor later.) Text that names
  someone or counts something is a function field (`typingOne(name)`) whose default is a private
  top-level function, so `TinodeChatStrings` stays `const`. Choosing between such texts (one name,
  two, a count) is a plain function next to its widget, like `typingMessage`, not code in `build`.
- No hard-coded colors: use `TinodeChatTheme.of(context)` or `Theme.of(context).colorScheme`. Add a
  field to `TinodeChatTheme` (and to `copyWith`, `lerp`, `fallback`) for new chat-specific colors.
- Widgets must work at phone width and in dark mode.

## Public widgets

Everything exported from `lib/tinode_flutter_chat.dart` needs dartdoc on the class and every public
member, with a short example where useful. Internal widgets need a one-line doc saying what they
show and what they watch.

## Checking rebuilds

- DevTools → Flutter Inspector → **Track widget rebuilds** while using the example app.
- In tests, record rebuilt widgets with `debugOnRebuildDirtyWidget`, as
  `chat_list_rebuild_test.dart` does.
