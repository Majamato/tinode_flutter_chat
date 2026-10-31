import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

/// The Tinode server; the default suits `../tinode-tests` on this machine.
/// From the Android emulator, run with
/// `--dart-define=TINODE_SERVER=ws://10.0.2.2:6060`; from a phone on the
/// same Wi-Fi, use the computer's address, e.g. `ws://192.168.1.20:6060`.
/// Calls need two devices, or one device and the web UI at
/// http://localhost:6060/ on that computer.
const server = String.fromEnvironment(
  'TINODE_SERVER',
  defaultValue: 'ws://localhost:6060',
);

/// The demo API key of the official Tinode images.
const apiKey = String.fromEnvironment(
  'TINODE_API_KEY',
  defaultValue: 'AQEAAAABAAD_rAp4DJh05a1HAwFT3A6K',
);

/// Where the example keeps the login token, so the next start logs in by
/// itself, and opens the cached chats even offline. A real app should
/// keep it in secure storage instead.
const _tokenKey = 'tinode_token';

/// The palettes on the settings' Appearance screen; the first is the
/// default.
const _palettes = [
  TinodeAppearancePalette(
    id: 'slate',
    label: 'Slate',
    colors: TinodeChatPalette.neutral,
  ),
  TinodeAppearancePalette(
    id: 'plum',
    label: 'Plum',
    colors: TinodeChatPalette(
      primary: Color(0xFF5B1A8C),
      night: Color(0xFF6E29A8),
      bright: Color(0xFF8A3FD1),
      accent: Color(0xFFFF9A3D),
      soft: Color(0xFFF1E5FA),
      ink: Color(0xFF42106A),
      onDark: Color(0xFFC08BFF),
      deep: Color(0xFF1A0730),
      scene: Color(0xFF28133D),
    ),
  ),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final appearance = await TinodeAppearance.load(palettes: _palettes);
  runApp(ExampleApp(preferences: preferences, appearance: appearance));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({
    required this.preferences,
    required this.appearance,
    super.key,
  });

  final SharedPreferences preferences;

  /// What the user picked on the Appearance screen; the themes follow it.
  final TinodeAppearance appearance;

  @override
  Widget build(BuildContext context) {
    final token = preferences.getString(_tokenKey);
    return ListenableBuilder(
      listenable: appearance,
      builder: (context, child) => MaterialApp(
        title: 'Tinode chat',
        theme: TinodeChatTheme.materialTheme(
          palette: appearance.palette.colors,
        ),
        darkTheme: TinodeChatTheme.materialTheme(
          palette: appearance.palette.colors,
          brightness: Brightness.dark,
        ),
        themeMode: appearance.themeMode,
        home: child,
      ),
      child: TinodeChat(
        config: TinodeConfig(
          server: Uri.parse(server),
          apiKey: apiKey,
          userAgent: 'tinode_flutter_chat-example/0.1',
        ),
        credentials: token == null ? null : TinodeCredentials.token(token),
        onLoggedIn: (login) {
          unawaited(preferences.setString(_tokenKey, login.token));
          // The ringing screen needs notifications, and on Android 14+ full
          // screen ones.
          unawaited(TinodeCalls.requestPermissions());
        },
        onLoggedOut: () => preferences.remove(_tokenKey),
        appearance: appearance,
      ),
    );
  }
}
