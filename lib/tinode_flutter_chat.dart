/// A drop-in Flutter chat UI for the [Tinode](https://github.com/tinode/chat)
/// chat server, built on `tinode_dart_client`.
///
/// Put a `TinodeChat` below your `MaterialApp`; it connects, shows a login
/// screen (or logs in with the `TinodeCredentials` you pass), the chat list
/// and the chats.
library;

export 'package:tinode_dart_client/tinode_dart_client.dart'
    show LoginResult, TinodeConfig;

export 'src/app/presentation/tinode_chat.dart' show TinodeChat;
export 'src/session/domain/tinode_credentials.dart'
    show PasswordCredentials, TinodeCredentials, TokenCredentials;
export 'src/shared/presentation/l10n/tinode_chat_strings.dart'
    show TinodeChatStrings;
export 'src/shared/presentation/theme/tinode_chat_theme.dart'
    show TinodeChatTheme;
