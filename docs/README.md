# Developer docs

Read these before changing code. They are the rules this package is built on,
and the tests in `test/architecture/` enforce the mechanical ones.

| Doc | What it covers |
|-----|----------------|
| [architecture.md](architecture.md) | Folder layout, layers and what each may import, how the session, chat list and chats fit together. |
| [riverpod.md](riverpod.md) | How we use Riverpod 3: code generation, provider lifetimes, `select`, async safety, versions. |
| [widgets.md](widgets.md) | Widget rules: one widget per file, nothing heavy in `build`, small rebuilds. |
| [testing.md](testing.md) | Test layout, the fake session, widget tests and the integration test against a real server. |
| [glossary.md](glossary.md) | Words used in code and docs. Builds on the client's Tinode glossary. |

## Everyday commands

The Flutter version is pinned in `.fvmrc`, so prefix commands with `fvm`.

```sh
fvm flutter pub get
fvm dart run build_runner build          # after changing any @riverpod code
fvm dart format .
fvm dart analyze --fatal-infos           # also reports riverpod_lint; `flutter analyze` does not
fvm flutter test                         # unit + widget tests
fvm flutter test --tags integration --run-skipped   # needs ../tinode-tests running
cd example && fvm flutter run            # the example app
```
