import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/app/presentation/session_gate.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/session/application/background_policy.dart';
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
/// [config], [credentials] and [onLoggedIn] are read once. To switch
/// server or user, give the widget a new [key].
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
  /// Creates the chat UI for the server in [config].
  const TinodeChat({
    required this.config,
    this.credentials,
    this.onLoggedIn,
    this.strings = const TinodeChatStrings(),
    super.key,
  }) : connector = null,
       network = null,
       callMedia = null;

  /// Like the default constructor, with sessions opened by [connector]
  /// instead of a real connection, network reports from [network] and the
  /// media of calls from [callMedia].
  @visibleForTesting
  const TinodeChat.withConnector({
    required this.config,
    required SessionConnector this.connector,
    this.network,
    this.callMedia,
    this.credentials,
    this.onLoggedIn,
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

  /// The texts the chat shows.
  final TinodeChatStrings strings;

  /// Opens sessions; null for a real connection.
  @visibleForTesting
  final SessionConnector? connector;

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
      );
  }

  @override
  void dispose() {
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
