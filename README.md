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
- Sends and shows images and files: an attach button offers Photo, Camera and File, then a
  preview with a caption. Images show in the chat and open full screen; files show their name and
  size, and a tap downloads and opens them with the system's viewer. Uploads show their progress,
  wait in the outbox like any message, and can be cancelled. Profile photos given by reference
  show too.
- In groups, names the sender of each run of messages and shows their avatar. Shows who is
  typing. The user's own messages get delivered and read ticks, and a "Read by" list in groups.
- Finds people and groups by login, email, phone or tag, opens 1:1 chats with them, and creates
  groups with members. This needs the network.
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

## Attachments: platform setup

Picking photos and files uses `image_picker` and `file_picker`; opening received files uses
`open_filex`. The package runs on Android, iOS and desktop; the web is not supported yet (its
cache uses `dart:io`).

- **iOS** (`ios/Runner/Info.plist`): `NSPhotoLibraryUsageDescription`, and
  `NSCameraUsageDescription` (already there for calls) for the Camera entry.
- **Android:** nothing for the system photo picker. See `file_picker`'s notes for older Android
  versions.
- **macOS:** the `com.apple.security.files.user-selected.read-only` entitlement (in
  `DebugProfile.entitlements` and `Release.entitlements`), next to `network.client`.
- **Linux:** `file_picker` needs `zenity` or `kdialog` installed.
- **Desktop:** there is no Camera entry, and photos go up at their original size (the pickers
  can't scale them there). Every file is still capped by the server's `maxFileUploadSize`.

Downloaded files live in the OS's cache folder, which the OS may clear; files waiting to be sent
are kept in the app's support folder until the server has them. Logging out deletes both.

## Offline

Each user's chats are kept on the device, so they open without waiting for the server:

- the chat list and the messages already seen show at once, even in airplane mode;
- back online, only what changed is fetched: new messages, deletions, updated chats;
- messages sent offline wait in an outbox with a clock, and go out once the link is back,
  never twice. One the server refuses shows an error mark; a long press retries or discards it;
- a long press on a message deletes it for the user, or for everyone where they may.

Pass the token of the user who last logged in as `TinodeCredentials.token`, and the app opens
their chats even with no network, logging in once the server answers. Logging out, from the chat
list's menu or with a `TinodeChatController`, deletes the user's cache:

```dart
final chat = TinodeChatController();

TinodeChat(
  config: config,
  credentials: savedToken == null ? null : TinodeCredentials.token(savedToken),
  controller: chat,
  onLoggedIn: (login) => saveToken(login.token),
  onLoggedOut: deleteSavedToken, // also when the server refuses the token
);

// From the host's own settings screen:
await chat.logOut();
```

## Roadmap

Built so far: the happy path, reconnection, calls, offline, finding people and starting chats,
group chat essentials, attachments.
Next, in this order. Each feature lands in [`tinode_dart_client`](../tinode_dart_client) first
where it needs the protocol:

1. ~~**Find people and start chats**~~: done (search, 1:1 chats, new groups with members).
2. ~~**Group chat essentials**~~: done (sender names and avatars in groups, typing indicators,
   delivered and read ticks, a "Read by" list).
3. ~~**Attachments**~~: done (send and show images and files, photos given by reference).
   Rich Drafty rendering (bold, links, mentions) is still to come: messages show their plain
   text.
4. **Account and profile**: sign up, edit name and avatar, change password, leave or delete
   chats.
5. **Push and background calls**: push notifications, CallKit and ConnectionService. Today calls
   ring only while the app is open and connected, and on Android a call may lose the microphone
   and camera in the background. Later still: group calls, switching between voice and video
   during a call.
6. **Search and cache upkeep**: message search, pruning the cache, encrypting it at rest (today
   it is a plain SQLite file per user).
7. **UI/UX improvements.**

## Development

Start with [`docs/`](docs/README.md): architecture, Riverpod usage, widget rules and testing.

## License

MIT. Tinode's server is GPL-3.0; this package only talks to it over the network.
