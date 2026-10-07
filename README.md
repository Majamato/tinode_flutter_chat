# tinode_flutter_chat

A drop-in Flutter chat UI for the [Tinode](https://github.com/tinode/chat) chat server, built on
[`tinode_dart_client`](../tinode_dart_client).

## Features

- Connects, logs in with a built-in form or with credentials you pass, and keeps the session for as
  long as the widget lives.
- Shows the chat list from `me`, newest first, with unread counts that follow new messages and reads
  from other devices.
- Opens direct chats, groups and channels. Channel followers get a read-only view.
- Loads history, pages older messages in on scroll, and merges live messages as they arrive.
- Sends plain text and marks what the user sees as read.
- 1:1 voice and video calls with `flutter_webrtc`, while the app is open: call buttons in direct
  chats, a ringing screen over any route, mute, camera on/off, front/back camera and speaker.
  Calls show in the chat with how they went. They need a server with ICE (STUN/TURN) servers.
- Restyle it with a `TinodeChatTheme` theme extension, and translate or reword it with
  `TinodeChatStrings`.
- Needs no `ProviderScope` or other setup in your app.

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

void main() => runApp(
  MaterialApp(
    home: TinodeChat(
      config: TinodeConfig(
        server: Uri.parse('wss://chat.example.com'),
        apiKey: '<your API key>',
        userAgent: 'MyApp/1.0',
      ),
      // Optional: skip the login form. Keep the token from onLoggedIn.
      // credentials: TinodeCredentials.token(savedToken),
      onLoggedIn: (login) => saveToken(login.token),
    ),
  ),
);
```

To restyle the chat, add a theme extension:

```dart
ThemeData(
  extensions: [
    TinodeChatTheme.fallback(ThemeData()).copyWith(ownBubbleColor: Colors.teal),
  ],
)
```

See [`example/`](example/lib/main.dart) for a runnable app. To try it locally, start the server
from `../tinode-tests` (`docker compose up -d`) and log in as `alice` / `alice123`.

## Calls: platform setup

Calls use the microphone and camera, so the host app must declare them.

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-feature android:name="android.hardware.camera" android:required="false"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE"/>
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

For release builds, keep WebRTC from R8: `-keep class org.webrtc.** { *; }` in
`proguard-rules.pro`.

**iOS** (`ios/Runner/Info.plist`): `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`,
and `UIBackgroundModes` with `audio` so a call keeps its sound when the screen locks. The Podfile
needs `platform :ios, '13.0'` or later.

The OS asks the user for access when the first call starts. See [`example/`](example/) for a
complete setup.

## Current limits

This release covers the online happy path. Not built yet:

- offline cache and message search (waiting on the client);
- typing indicators, read receipts per message, sender names in groups;
- attachments, rich Drafty rendering (messages show their plain text);
- creating chats, finding users (`fnd`);
- calls ring only while the app is open and connected: no push, CallKit or ConnectionService yet.
  On Android a call may lose the microphone and camera while the app is in the background. No
  group calls, no switching between voice and video during a call.

## Development

Start with [`docs/`](docs/README.md): architecture, Riverpod usage, widget rules and testing.

## License

MIT. Tinode's server is GPL-3.0; this package only talks to it over the network.
