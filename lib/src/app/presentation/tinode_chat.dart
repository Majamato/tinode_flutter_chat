import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/app/presentation/session_gate.dart';
import 'package:tinode_flutter_chat/src/attachments/data/attachment_picker.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_opener.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_store.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/application/background_policy.dart';
import 'package:tinode_flutter_chat/src/session/application/credentials_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/network_policy.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/data/network_monitor.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings_scope.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/chat_theme_scope.dart';

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
/// To switch server or user, give the widget a new [key].
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
    this.strings = const TinodeChatStrings(),
    super.key,
  }) : connector = null,
       restorer = null,
       storeOpener = null,
       fileStoreOpener = null,
       fileOpener = null,
       attachmentPicker = null,
       network = null,
       callMedia = null;

  /// Like the default constructor, with sessions opened by [connector]
  /// (or [restorer] for a remembered user) instead of a real connection,
  /// caches from [storeOpener], files from [fileStoreOpener], opened with
  /// [fileOpener] and picked with [attachmentPicker], network reports from
  /// [network] and the media of calls from [callMedia].
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
    this.credentials,
    this.onLoggedIn,
    this.onLoggedOut,
    this.controller,
    this.strings = const TinodeChatStrings(),
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

  /// The texts the chat shows.
  final TinodeChatStrings strings;

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

  @override
  State<TinodeChat> createState() => _TinodeChatState();
}

class _TinodeChatState extends State<TinodeChat> {
  late final ProviderContainer _container = createTinodeContainer(
    config: widget.config,
    credentials: widget.credentials,
    connector: widget.connector,
    restorer: widget.restorer,
    storeOpener: widget.storeOpener,
    fileStoreOpener: widget.fileStoreOpener,
    fileOpener: widget.fileOpener,
    attachmentPicker: widget.attachmentPicker,
    network: widget.network,
    callMedia: widget.callMedia,
  );

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => _container.read(backgroundPolicyProvider.notifier).hidden(),
      onShow: () => _container.read(backgroundPolicyProvider.notifier).shown(),
    );
    _container
      ..read(networkPolicyProvider)
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
    widget.controller?._logOut = () =>
        _container.read(sessionControllerProvider.notifier).logout();
  }

  @override
  void dispose() {
    widget.controller?._logOut = null;
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
        child: const ChatThemeScope(child: SessionGate()),
      ),
    );
  }
}

/// Acts on a [TinodeChat] from outside it: pass it to the widget, then call
/// its methods, e.g. from the host app's own settings screen.
class TinodeChatController {
  Future<void> Function()? _logOut;

  /// Logs the user out: deletes the chats kept on the device, including
  /// messages not sent yet, and shows the login screen. Does nothing while
  /// no user is logged in, or before the controller is given to a
  /// [TinodeChat].
  Future<void> logOut() async => _logOut?.call();
}
