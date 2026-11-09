/// A drop-in Flutter chat UI for the [Tinode](https://github.com/tinode/chat)
/// chat server, built on `tinode_dart_client`.
///
/// Put a `TinodeChat` below your `MaterialApp`; it connects, shows a login
/// screen (or logs in with the `TinodeCredentials` you pass), the chat list
/// and the chats.
library;

export 'package:tinode_dart_client/tinode_dart_client.dart'
    show
        DevicePlatform,
        LoginResult,
        MessagePush,
        ReadPush,
        SubscriptionPush,
        TinodeConfig,
        TinodePush;

export 'src/app/presentation/tinode_appearance.dart'
    show TinodeAppearance, TinodeAppearancePalette;
export 'src/app/presentation/tinode_calls.dart' show TinodeCalls;
export 'src/app/presentation/tinode_chat.dart'
    show TinodeChat, TinodeChatController;
export 'src/attachments/domain/tinode_attachment_limits.dart'
    show TinodeAttachmentLimits;
export 'src/chats/domain/tinode_bubble.dart'
    show TinodeBubble, TinodeBubbleKind, TinodeBubbleStatus;
export 'src/chats/presentation/chat/bubble_builder_scope.dart'
    show TinodeBubbleBuilder;
export 'src/chats/presentation/chat/bubble_tail.dart' show BubbleTail;
export 'src/offline/domain/tinode_cache_limits.dart' show TinodeCacheLimits;
export 'src/session/domain/tinode_auth_mode.dart' show TinodeAuthMode;
export 'src/session/domain/tinode_chat_features.dart'
    show PasswordResetMode, TinodeChatFeatures;
export 'src/session/domain/tinode_credentials.dart'
    show PasswordCredentials, TinodeCredentials, TokenCredentials;
export 'src/session/presentation/login_builder_scope.dart'
    show TinodeLoginBuilder;
export 'src/session/presentation/tinode_login_view.dart' show TinodeLoginView;
export 'src/shared/domain/tinode_screen.dart'
    show
        TinodeAccountScreen,
        TinodeAppearanceScreen,
        TinodeAttachmentPreviewScreen,
        TinodeCallsScreen,
        TinodeChangePasswordScreen,
        TinodeChatInfoScreen,
        TinodeChatListScreen,
        TinodeChatScreen,
        TinodeConfirmEmailScreen,
        TinodeFindPeopleScreen,
        TinodeImageViewerScreen,
        TinodeMessageSearchScreen,
        TinodeNewGroupScreen,
        TinodePasswordResetScreen,
        TinodeProfileScreen,
        TinodeScreen,
        TinodeSettingsScreen,
        TinodeVideoPlayerScreen;
export 'src/shared/presentation/app_bar_builder_scope.dart'
    show TinodeAppBarBuilder;
export 'src/shared/presentation/icons/tinode_chat_icons.dart'
    show TinodeChatIcons;
export 'src/shared/presentation/l10n/tinode_chat_strings.dart'
    show TinodeChatStrings;
export 'src/shared/presentation/sliding_segments.dart' show SlidingSegments;
export 'src/shared/presentation/theme/tinode_chat_palette.dart'
    show TinodeChatPalette;
export 'src/shared/presentation/theme/tinode_chat_theme.dart'
    show TinodeChatTheme;
export 'src/shared/presentation/tinode_app_bar.dart' show TinodeAppBar;
export 'src/shared/presentation/tinode_back_button.dart' show TinodeBackButton;
