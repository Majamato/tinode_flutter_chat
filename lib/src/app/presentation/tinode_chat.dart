import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/app/presentation/session_gate.dart';
import 'package:tinode_flutter_chat/src/app/presentation/shell_scope.dart';
import 'package:tinode_flutter_chat/src/app/presentation/tinode_appearance.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_scope.dart';
import 'package:tinode_flutter_chat/src/attachments/data/attachment_picker.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_opener.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_store.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/calls/domain/system_calls.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/system_call_texts_of.dart';
import 'package:tinode_flutter_chat/src/chats/application/requested_chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_builder_scope.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/offline/domain/tinode_cache_limits.dart';
import 'package:tinode_flutter_chat/src/push/application/push_registration.dart';
import 'package:tinode_flutter_chat/src/push/application/push_token_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/background_policy.dart';
import 'package:tinode_flutter_chat/src/session/application/credentials_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/network_policy.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/data/network_monitor.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_chat_features.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_header_scope.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/app_bar_builder_scope.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons_scope.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings_scope.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/chat_theme_scope.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_player.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_recorder.dart';

/// A complete chat UI for a Tinode server: login, chat list and chats.
///
/// Place it anywhere below a `MaterialApp`; it needs no `ProviderScope`.
/// It connects when first built and closes the connection when removed.
///
/// It keeps each user's chats on the device, so they open without waiting
/// for the server, even offline, and what the user sends meanwhile goes out
/// once the link is back. With [credentials] holding the token of the user
/// who last logged in, it opens their chats right away.
///
/// [config], [credentials], [controller] and the callbacks are read once.
/// To switch server or user, give the widget a new [key]. [pushToken] is
/// read on every build: rebuild with the push service's new token.
///
/// ```dart
/// MaterialApp(
///   home: TinodeChat(
///     config: TinodeConfig(
///       server: Uri.parse('wss://chat.example.com'),
///       apiKey: '<your API key>',
///       userAgent: 'MyApp/1.0',
///     ),
///   ),
/// )
/// ```
class TinodeChat extends StatefulWidget {
  const TinodeChat({
    required this.config,
    this.credentials,
    this.onLoggedIn,
    this.onLoggedOut,
    this.controller,
    this.pushToken,
    this.strings = const TinodeChatStrings(),
    this.icons = const TinodeChatIcons(),
    this.features = const TinodeChatFeatures(),
    this.cacheLimits = const TinodeCacheLimits(),
    this.bubbleBuilder,
    this.appBarBuilder,
    this.loginHeader,
    this.tabBar = true,
    this.appearance,
    this.appearanceExtra,
    super.key,
  }) : connector = null,
       restorer = null,
       storeOpener = null,
       fileStoreOpener = null,
       fileOpener = null,
       attachmentPicker = null,
       network = null,
       callMedia = null,
       systemCalls = null,
       voiceRecorder = null,
       voicePlayer = null;

  /// Like the default constructor, with sessions opened by [connector]
  /// (or [restorer] for a remembered user) instead of a real connection,
  /// caches from [storeOpener], files from [fileStoreOpener], opened with
  /// [fileOpener] and picked with [attachmentPicker], network reports from
  /// [network], the media of calls from [callMedia], the phone's call
  /// screens from [systemCalls], and voice messages recorded with
  /// [voiceRecorder] and played with [voicePlayer].
  @visibleForTesting
  const TinodeChat.withConnector({
    required this.config,
    required SessionConnector this.connector,
    this.restorer,
    this.storeOpener,
    this.fileStoreOpener,
    this.fileOpener,
    this.attachmentPicker,
    this.network,
    this.callMedia,
    this.systemCalls,
    this.voiceRecorder,
    this.voicePlayer,
    this.credentials,
    this.onLoggedIn,
    this.onLoggedOut,
    this.controller,
    this.pushToken,
    this.strings = const TinodeChatStrings(),
    this.icons = const TinodeChatIcons(),
    this.features = const TinodeChatFeatures(),
    this.cacheLimits = const TinodeCacheLimits(),
    this.bubbleBuilder,
    this.appBarBuilder,
    this.loginHeader,
    this.tabBar = true,
    this.appearance,
    this.appearanceExtra,
    super.key,
  });

  /// The server to connect to.
  final TinodeConfig config;

  /// Logs in with these right after connecting. When null, or when they
  /// are rejected, the built-in login screen asks the user.
  final TinodeCredentials? credentials;

  /// Called after each successful login. Keep `LoginResult.token` to pass
  /// `TinodeCredentials.token` next time.
  final ValueChanged<LoginResult>? onLoggedIn;

  /// Called when the user logs out, or when the server refuses the token:
  /// forget the token you kept.
  final VoidCallback? onLoggedOut;

  /// Lets the host act on the chat, e.g. log out from its own settings.
  final TinodeChatController? controller;

  /// This device's push token from the host's push service, e.g.
  /// `FirebaseMessaging.instance.getToken()`; null for none. It is
  /// registered for whoever logs in, sent again when it changes, and
  /// removed from the server when the user logs out. Pushes reach the app,
  /// not this widget: read them with `TinodePush.tryParse`, and hand those
  /// that arrive in the background to `TinodeCalls.handlePush`, which rings
  /// for calls.
  ///
  /// [config]'s `platform` tells the server how to push to it; when unset,
  /// it is this device's (Android, iOS or web).
  final String? pushToken;

  /// The texts the chat shows.
  final TinodeChatStrings strings;

  /// The icons the chat shows, Phosphor's by default.
  final TinodeChatIcons icons;

  /// Which features the chat offers: signing up and resetting a forgotten
  /// password (by default only where the server sends email) on the login
  /// screen, and the phone's own call screens for calls.
  final TinodeChatFeatures features;

  /// How much of each user's chats stays on the device: messages per chat
  /// and the size of the file cache. Message search finds only what is
  /// kept.
  final TinodeCacheLimits cacheLimits;

  /// Builds message bubbles in place of the default ones, e.g. to wrap or
  /// restyle them beyond `TinodeChatTheme`; null for the default bubbles.
  /// Read on every build.
  final TinodeBubbleBuilder? bubbleBuilder;

  /// Builds the app bar of the chat list, the calls history, the settings,
  /// the appearance and each chat in place of the default glass bar, e.g.
  /// to wrap it or bring the app's own. Gets the screen (`TinodeScreen`)
  /// and the default bar. The screens' content scrolls under the bar and
  /// starts below its preferred height, so a solid bar works too. Null for
  /// the default bars. Read on every build.
  ///
  /// ```dart
  /// TinodeChat(
  ///   config: config,
  ///   appBarBuilder: (context, screen, defaultAppBar) => switch (screen) {
  ///     TinodeChatScreen(:final topic) => MyChatBar(topic: topic),
  ///     _ => defaultAppBar,
  ///   },
  /// )
  /// ```
  final TinodeAppBarBuilder? appBarBuilder;

  /// Shown centred near the top of the login screen, over its backdrop
  /// and above the sheet that signs in or up: e.g. the app's
  /// animated logo. Null shows nothing there. Read on every build.
  final Widget? loginHeader;

  /// Whether the chat list sits in a floating tab bar with the calls
  /// history (when [features] offer calls) and the settings: the user's
  /// profile, the [appearance] and logging out. Turn it off when the app
  /// has tabs of its own; the chat list header then offers those settings
  /// in a menu, and there is no calls history. Read once.
  final bool tabBar;

  /// The palettes and the theme the user can pick in the settings, and
  /// what they picked; build the app's themes from it. Null offers no
  /// Appearance screen. Read on every build.
  final TinodeAppearance? appearance;

  /// Shown on the Appearance screen under the theme switch, e.g. a look
  /// setting of the app's own such as its text size. It is built inside the
  /// chat, so it reads the app's state from the widget tree above
  /// [TinodeChat] (or an [appearance] it listens to). Read on every build.
  final Widget? appearanceExtra;

  /// Opens sessions; null for a real connection.
  @visibleForTesting
  final SessionConnector? connector;

  /// Starts a remembered user's session; null for a real connection.
  @visibleForTesting
  final SessionRestorer? restorer;

  /// Opens the per-user caches; null for files on the device.
  @visibleForTesting
  final ChatStoreOpener? storeOpener;

  /// Opens the per-user downloaded and staged files; null for folders on
  /// the device.
  @visibleForTesting
  final FileStoreOpener? fileStoreOpener;

  /// Opens received files; null for the system's viewer.
  @visibleForTesting
  final FileOpener? fileOpener;

  /// Picks photos and files to send; null for the system's pickers.
  @visibleForTesting
  final AttachmentPicker? attachmentPicker;

  /// Reports network changes; null for the OS's.
  @visibleForTesting
  final NetworkMonitor? network;

  /// Creates the media of calls; null for WebRTC.
  @visibleForTesting
  final CallMediaFactory? callMedia;

  /// The phone's call screens; null for this device's.
  @visibleForTesting
  final SystemCalls? systemCalls;

  /// Creates the voice message recorder; null for the microphone.
  @visibleForTesting
  final VoiceRecorderFactory? voiceRecorder;

  /// Creates the voice message player; null for the device's.
  @visibleForTesting
  final VoicePlayerFactory? voicePlayer;

  @override
  State<TinodeChat> createState() => _TinodeChatState();
}

class _TinodeChatState extends State<TinodeChat> {
  late final ProviderContainer _container = createTinodeContainer(
    config: _withPlatform(widget.config),
    credentials: widget.credentials,
    features: widget.features,
    cacheLimits: widget.cacheLimits,
    connector: widget.connector,
    restorer: widget.restorer,
    storeOpener: widget.storeOpener,
    fileStoreOpener: widget.fileStoreOpener,
    fileOpener: widget.fileOpener,
    attachmentPicker: widget.attachmentPicker,
    network: widget.network,
    callMedia: widget.callMedia,
    systemCalls: widget.systemCalls,
    systemCallTexts: systemCallTextsOf(widget.strings),
    voiceRecorder: widget.voiceRecorder,
    voicePlayer: widget.voicePlayer,
  );

  late final AppLifecycleListener _lifecycle;
  late final bool _tabBar = widget.tabBar;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => _container.read(backgroundPolicyProvider.notifier).hidden(),
      onShow: () => _container.read(backgroundPolicyProvider.notifier).shown(),
    );
    _container.read(pushTokenControllerProvider.notifier).set(widget.pushToken);
    _container
      ..read(networkPolicyProvider)
      // Listened to, so it rebuilds as the token and session change.
      ..listen(pushRegistrationProvider, (_, _) {})
      ..listen(
        sessionControllerProvider.select(
          (s) => switch (s) {
            AsyncData(value: SessionLoggedIn(:final login)) => login,
            _ => null,
          },
        ),
        (_, login) {
          if (login != null) {
            widget.onLoggedIn?.call(login);
          }
        },
      )
      ..listen(credentialsControllerProvider, (previous, next) {
        if (previous != null && next == null) {
          widget.onLoggedOut?.call();
        }
      });
    widget.controller?._attach(
      logOut: () =>
          _container.read(sessionControllerProvider.notifier).logout(),
      openChat: (topic) => _container
          .read(requestedChatControllerProvider.notifier)
          .request(topic),
    );
  }

  @override
  void didUpdateWidget(TinodeChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pushToken != oldWidget.pushToken) {
      _container
          .read(pushTokenControllerProvider.notifier)
          .set(widget.pushToken);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _lifecycle.dispose();
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: _container,
      child: TinodeChatStringsScope(
        strings: widget.strings,
        child: TinodeChatIconsScope(
          icons: widget.icons,
          child: BubbleBuilderScope(
            builder: widget.bubbleBuilder,
            child: AppBarBuilderScope(
              builder: widget.appBarBuilder,
              child: LoginHeaderScope(
                header: widget.loginHeader,
                child: ShellScope(
                  tabBar: _tabBar,
                  child: AppearanceScope(
                    appearance: widget.appearance,
                    extra: widget.appearanceExtra,
                    child: const ChatThemeScope(child: SessionGate()),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Acts on a [TinodeChat] from outside it: pass it to the widget, then call
/// its methods, e.g. from the host app's own settings screen.
class TinodeChatController {
  Future<void> Function()? _logOut;
  void Function(String topic)? _openChat;

  /// A chat asked for before the controller was given to a [TinodeChat].
  String? _pendingChat;

  /// Logs the user out: removes this device's push token from the server,
  /// deletes the chats kept on the device, including messages not sent
  /// yet, and shows the login screen. Does nothing while no user is logged
  /// in, or before the controller is given to a [TinodeChat].
  Future<void> logOut() async => _logOut?.call();

  /// Opens the chat named [topic] over the chat list, e.g. when the user
  /// taps a notification: pass `TinodePush.topic`. It waits for a login,
  /// and for the [TinodeChat] when called before it is built, as when a
  /// notification started the app. A later call replaces a waiting one.
  void openChat(String topic) {
    if (_openChat case final open?) {
      open(topic);
    } else {
      _pendingChat = topic;
    }
  }

  void _attach({
    required Future<void> Function() logOut,
    required void Function(String topic) openChat,
  }) {
    _logOut = logOut;
    _openChat = openChat;
    if (_pendingChat case final topic?) {
      _pendingChat = null;
      openChat(topic);
    }
  }

  void _detach() {
    _logOut = null;
    _openChat = null;
  }
}

/// [config] with this device's OS as its push platform, unless the host
/// set one.
TinodeConfig _withPlatform(TinodeConfig config) {
  if (config.platform != null) {
    return config;
  }
  final platform = kIsWeb
      ? DevicePlatform.web
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => DevicePlatform.android,
          TargetPlatform.iOS => DevicePlatform.ios,
          _ => null,
        };
  return platform == null ? config : config.copyWith(platform: platform);
}
