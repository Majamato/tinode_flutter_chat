import 'package:flutter/material.dart';
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

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tinode chat',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: TinodeChat(
        config: TinodeConfig(
          server: Uri.parse(server),
          apiKey: apiKey,
          userAgent: 'tinode_flutter_chat-example/0.1',
        ),
      ),
    );
  }
}
